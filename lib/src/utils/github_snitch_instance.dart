import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:github_snitch/src/screens/reports.dart';
import 'package:github_snitch/src/utils/extensions.dart';
import 'package:github_snitch/src/utils/get_app_version.dart';
import 'package:mime/mime.dart';

import '../gh_snitch.dart';
import '../models/comment.dart';
import '../models/issue.dart';
import 'constants.dart';
import 'gh_requests.dart';
import 'gh_response.dart';
import 'prefs.dart';

class GhSnitchInstance {
  String? token;
  String? owner;
  String? repo;
  int? maxDuplicatedReports;
  OnReport? onReport;
  late GhRequest ghRequest;
  static GhSnitchInstance get instance => GhSnitchInstance();
  bool get initialized => token != null && repo != null && owner != null;

  /// Reports an issue to the GitHub repository. It takes a `title` and `body` as required parameters,
  /// and optional parameters such as `screenShot`, `screenShotsBranch`, `labels`, `assignees`, and `milestone`.
  /// The method first checks if the issue has already been reported, and if not, it creates a new issue in the repository
  /// and saves its details in the app's preferences.
  Future<bool> report(
      {required String title,
      required String body,
      Uint8List? screenShot,
      String? screenShotsBranch,
      List<String>? labels,
      List<String>? assignees,
      int? milestone,
      String? userId,
      bool fromCatch = false}) async {
    ConnectivityResult connectivity = await Connectivity().checkConnectivity();
    if (!(connectivity == ConnectivityResult.none)) {
      String issueEndpoint = "$owner/$repo/issues";
      bool alreadyReported = await isAlreadyReported(body, labels);
      if (alreadyReported) {
        log("✅ Issue Already Reported");
        return true;
      } else {
        String? url = "";
        if (screenShot != null) {
          url = await uploadScreenShot(screenShot,
              screenShotsBranch: screenShotsBranch!);
          url = "\n## ScreenShot \n![]($url)";
        }
        String? id = userId ?? await deviceId;
        Map<String, dynamic> issueBody = {
          ownerBody: owner,
          repoBody: repo,
          bodyTitle: title,
          bodyBody: '$body$url\n$id',
        };
        if (assignees != null) {
          issueBody["assignees"] = assignees;
        }
        if (labels != null) {
          labels.add(fromGhRSnitchPackage);
          issueBody["labels"] = labels;
        }

        milestone ??= await getMilestoneID() ?? await createMilestone();
        issueBody["milestone"] = milestone;

        String issueBodyToString = json.encode(issueBody);
        onReport?.call(title, body, labels, milestone, userId);
        GhResponse response = await ghRequest.request("POST", issueEndpoint,
            body: issueBodyToString);
        if (response.statusCode == 201) {
          Map issueFieldsDecoded = Map.from(response.response);
          issueFieldsDecoded
              .removeWhere((key, value) => !issueFieldUses.contains(key));
          String issueFieldsEncoded = json.encode(issueFieldsDecoded);
          Prefs.set(
              "gh_issue_${response.response['number']}", issueFieldsEncoded);
          log("✅ Issue reported");
          return true;
        } else {
          log("❌ Echec to report Issue");
          log(response.response.toString());
          return false;
        }
      }
    } else {
      if (fromCatch) {
        return false;
      }
      Map issue = {
        bodyTitle: title,
        bodyBody: body,
        issueLabelsField: labels,
        issueFieldMilstone: milestone,
        dateBody: DateTime.now().toUtc().toString()
      };
      String issueToString = json.encode(issue);
      Prefs.set("github_report_issue${title.hashCode}", issueToString);
      return true;
    }
  }

  /// Reports any issues that were saved in the app's preferences when the app was offline.
  /// It retrieves the saved issues, reports them to the repository, and removes them from the preferences.
  void reportSavedIssues() async {
    List prefsKeys = (await Prefs.getKeys()).toList();
    List olderIssues =
        prefsKeys.where((e) => e.contains("github_report_issue")).toList();
    if (olderIssues.isNotEmpty) {
      for (var e in olderIssues) {
        String? issueFromPref = await Prefs.get(e);
        var issueToMap = json.decode(issueFromPref!);
        Issue issue = Issue.fromJson(issueToMap);
        bool reported = await report(
            title: issue.title!,
            milestone: issue.milestone,
            labels: issue.labels,
            body: "${issue.body!}\n${issueToMap[dateBody]}",
            fromCatch: true);
        if (reported) {
          Prefs.remove(e);
          log("✅ Reported saved issue");
        }
      }
    }
  }

  /// Initializes the `GhSnitchInstance` by setting the `token`, `owner`, and `repo` properties.
  /// It also creates a `GhRequest` object using the `token` property and calls the `reportSavedIssues` method.
  void initialize(
      {required String token,
      required String owner,
      required String repo,
      required int maxDuplicatedReports,
      OnReport onReport}) {
    this.token = token;
    this.owner = owner;
    this.repo = repo;
    this.maxDuplicatedReports = maxDuplicatedReports;
    this.onReport = onReport;
    if (token.isEmpty || owner.isEmpty || repo.isEmpty) {
      log("🔴 Echec to initialize GhSnitch");
    } else {
      ghRequest = GhRequest(token);
      reportSavedIssues();
      log("✅ GhSnitch initialized");
    }
  }

  /// Listens to any uncaught exceptions in the app and reports them to the repository.
  /// It takes optional parameters such as `assignees` and `milestone`.
  void listenToExceptions({
    List<String>? assignees,
    int? milestone,
    List<String>? labels,
  }) {
    FlutterError.onError = (details) async {
      FlutterError.presentError(details);
      if (labels != null) {
        labels!.add(externalIssueLabel);
      } else {
        labels = [externalIssueLabel];
      }
      await prepareAndReport(details.exception.toString(), details.stack!,
          labels: labels, assignees: assignees, milestone: milestone);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (labels != null) {
        labels!.add(internalIssueLabel);
      } else {
        labels = [internalIssueLabel];
      }
      prepareAndReport(error.toString(), stack,
          labels: labels, assignees: assignees, milestone: milestone);
      return true;
    };
    log("✅ GhSnitch Listen to exceptions");
  }

  /// Prepares and reports an exception to the repository. It takes the `exception`, `stack`, and `label` as required parameters,
  /// and optional parameters such as `assignees` and `milestone`.
  Future<bool> prepareAndReport(
    String exception,
    StackTrace stack, {
    List<String>? labels,
    List<String>? assignees,
    int? milestone,
  }) {
    bool issueNotFromPackage = !stack.toString().contains("github_snitch");
    if (issueNotFromPackage) {
      String body = stack.toString();
      if (body.contains("#21   ")) {
        body = body.substring(0, stack.toString().indexOf("#21   "));
      }
      return report(
          title: exception.toString(),
          labels: labels,
          body: "```\n$body ```",
          milestone: milestone,
          assignees: assignees);
    }
    return Future.value(false);
  }

  /// Checks if an issue with a similar `body` has already been reported in the repository.
  /// It takes the `body` as required parametes.
  Future<bool> isAlreadyReported(String body, List<String>? labels) async {
    bool isDuplicated = false;
    body = body
        .replaceAll("```", "")
        .substring(0, math.min(body.length, 255))
        .replaceFirst("#", "");
    String url =
        "https://api.github.com/search/issues?q=repo:$owner/$repo+is:issue+is:open+$body";
    GhResponse ghResponse = await ghRequest.request("GET", url, isSearch: true);
    if (ghResponse.statusCode == 200) {
      final count = ghResponse.response['total_count'];
      isDuplicated = count != 0;
      if (isDuplicated) {
        final comments = ghResponse.response["items"].first["comments"];
        if (comments < maxDuplicatedReports) {
          String labelsContent = "";
          if (labels != null) {
            labelsContent = "Labels: ${labels.join(", ")}";
          }
          await submitComment(
              ghResponse.response['items'][0][issueNumber].toString(),
              "+1\n$labelsContent");
        }
      }
    }
    return isDuplicated;
  }

  /// Retrieves all the issues in the repository that contain the specified `userId`.
  Future<List<Issue>> getIssuesByUserID(String userId) async {
    //TODO: Fix get closed issues issue
    String params = "?state=all";
    List<Issue> result = [];
    String issueEndpoint = "$owner/$repo/issues";
    GhResponse ghResponse =
        await ghRequest.request("GET", issueEndpoint + params);
    if (ghResponse.statusCode == 200) {
      for (var e in (ghResponse.response as List)) {
        if (e["body"] != null) {
          if (e["body"].contains(userId)) {
            result.add(Issue.fromJson(e));
          }
        }
      }
    }
    return result;
  }

  /// Retrieves all the comments made on the issues reported by the current user.
  Future<Issue> getReportsComments({String? userId}) async {
    final Issue issues = Issue();

    String? id = userId ?? await deviceId;
    List userIssues = await getIssuesByUserID(id ?? '');
    for (Issue issue in userIssues) {
      String listCommentsEp = "$owner/$repo/issues/${issue.id}/comments";
      GhResponse response = await ghRequest.request("GET", listCommentsEp);
      issue.comments.setMulti(response.response);
      issues.multi.add(issue);
    }
    return issues;
  }

  /// Submits a comment to the specified issue.
  Future<bool> submitComment(String reportId, String comment,
      {String? userId}) async {
    bool commented = false;
    String submitCommentEp = "$owner/$repo/issues/$reportId/comments";
    String? id = userId ?? await deviceId;
    Map commentBody = {
      commentsBodyField:
          "$comment\n${deviceIdTemplate.replaceFirst(idMark, id ?? '')}"
    };
    String commentBodyToString = json.encode(commentBody);
    GhResponse response = await ghRequest.request("POST", submitCommentEp,
        body: commentBodyToString);
    if (response.statusCode == 201) {
      log("✅ Commented Issue");
      commented = true;
    } else {
      log("❌ Echec to Comment Issue");
      log(response.response.toString());
      commented = false;
    }
    return commented;
  }

  /// Uploads a screenshot image to the repository.
  /// It takes the `imgPath` and optional `screenShotsBranch` as parameters.
  Future<String?> uploadScreenShot(Uint8List file,
      {String screenShotsBranch = "GhSnitch_ScreenShots"}) async {
    String content = base64.encode(file);
    String? mime = lookupMimeType('', headerBytes: file);
    String ext = extensionFromMime(mime!);
    String fileName = "${content.hashCode}.${ext.split("/").last}";
    String uploadImgEp = "$owner/$repo/contents/$fileName";
    var data = json.encode({
      "message": "uploaded screenshot by GhSnitch package",
      "content": content,
      "branch": screenShotsBranch
    });
    GhResponse response =
        await ghRequest.request("PUT", uploadImgEp, body: data);
    if (response.statusCode == 201) {
      log("✅ Screenshot uploaded");
      return response.response["content"]["html_url"]
          .toString()
          .replaceFirst("$repo/blob/", "$repo/raw/");
    } else {
      log("❌ Echec to Upload Screenshot");
      log(response.response.toString());
    }
    return null;
  }

  Future<String?> get deviceId async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String? id;
    if (kIsWeb) {
      id =
          (await deviceInfoPlugin.webBrowserInfo).userAgent.hashCode.toString();
    } else {
      id = switch (defaultTargetPlatform) {
        TargetPlatform.android => (await deviceInfoPlugin.androidInfo).id,
        TargetPlatform.iOS =>
          (await deviceInfoPlugin.iosInfo).identifierForVendor,
        TargetPlatform.linux => (await deviceInfoPlugin.linuxInfo).id,
        TargetPlatform.windows => (await deviceInfoPlugin.windowsInfo).deviceId,
        TargetPlatform.macOS => (await deviceInfoPlugin.macOsInfo).systemGUID,
        TargetPlatform.fuchsia => null
      };
    }
    return id;
  }

  Future<int> createMilestone({DateTime? milestoneDueOn}) async {
    int? id;
    String createMilestoneEp = "$owner/$repo/milestones";
    Map milestoneBody = {
      'title': await GetAppVersion.version,
    };
    if (milestoneDueOn != null) {
      milestoneBody['due_on'] = milestoneDueOn.toUtc().toString();
    }
    String milestoneBodyToString = json.encode(milestoneBody);
    GhResponse response = await ghRequest.request("POST", createMilestoneEp,
        body: milestoneBodyToString);
    if (response.statusCode == 201) {
      log("✅ Created Milestone");
      id = response.response['number'];
    } else {
      log("❌ Failure to Create Milestone");
      log(response.response.toString());
    }
    return id!;
  }

  Future<int?> getMilestoneID() async {
    int? result;
    String milestonesEndpoint = "$owner/$repo/milestones";
    GhResponse ghResponse = await ghRequest.request("GET", milestonesEndpoint);
    if (ghResponse.statusCode == 200) {
      for (var e in (ghResponse.response as List)) {
        if (e['title'] == await GetAppVersion.version) {
          result = e['number'];
        }
      }
    }
    return result;
  }

  openReportScreen(BuildContext context) async {
    context.push(Reports());
  }
}
