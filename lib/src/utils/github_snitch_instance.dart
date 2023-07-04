import 'dart:convert';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_udid/flutter_udid.dart';

import 'package:flutter/foundation.dart';
import 'package:github_snitch/src/utils/extensions.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:universal_io/io.dart';

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
      String? screenShot,
      String? screenShotsBranch,
      List<String>? labels,
      List<String>? assignees,
      int? milestone}) async {
    ConnectivityResult connectivity = await Connectivity().checkConnectivity();
    if (!(connectivity == ConnectivityResult.none)) {
      String issueEndpoint = "$owner/$repo/issues";
      bool alreadyReported = await isAlreadyReported(body, issueEndpoint);
      if (alreadyReported) {
        log("✅ Issue Already Reported");
        return false;
      } else {
        String? url = "";
        if (screenShot != null) {
          url = await uploadScreenShot(screenShot,
              screenShotsBranch: screenShotsBranch!);
          url = "\n## ScreenShot \n![]($url)";
        }
        String deviceId = await FlutterUdid.udid;
        Map<String, dynamic> issueBody = {
          ownerBody: owner,
          repoBody: repo,
          bodyTitle: title,
          bodyBody: '$body$url\n$deviceId',
        };
        if (assignees != null) {
          issueBody["assignees"] = assignees;
        }
        if (labels != null) {
          labels.add(fromGhRSnitchPackage);
          issueBody["labels"] = labels;
        }

        if (milestone != null) {
          issueBody["milestone"] = milestone;
        }

        String issueBodyToString = json.encode(issueBody);

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
      Map issue = {
        bodyTitle: title,
        bodyBody: body,
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
        bool reported = await report(
            title: issueToMap[bodyTitle],
            body: issueToMap[bodyBody] + "/n" + issueToMap[dateBody]);
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
      {required String token, required String owner, required String repo}) {
    this.token = token;
    this.owner = owner;
    this.repo = repo;
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
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (labels != null) {
        labels!.add(externalIssueLabel);
      } else {
        labels = [externalIssueLabel];
      }
      prepareAndReport(details.exception.toString(), details.stack!,
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
  /// It takes the `body` and `endpoint` as required parameters.
  Future<bool> isAlreadyReported(String body, String endpoint) async {
    bool isAlreadyReported = false;
    String params = "?state=all&labels=$fromGhRSnitchPackage";
    GhResponse ghResponse = await ghRequest.request("GET", endpoint + params);
    if (ghResponse.statusCode == 200) {
      for (var e in (ghResponse.response as List)) {
        String removedLastLine = e[bodyBody].toString().removeLastLine();
        double similarity = body.similarityTo(removedLastLine);
        if (similarity > 0.7) {
          isAlreadyReported = true;
          break;
        }
      }
    }
    return isAlreadyReported;
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
  Future<Issue> getReportsComments() async {
    final Issue issues = Issue();

    String deviceId = await FlutterUdid.udid;
    List userIssues = await getIssuesByUserID(deviceId);
    for (Issue issue in userIssues) {
      String listCommentsEp = "$owner/$repo/issues/${issue.id}/comments";
      GhResponse response = await ghRequest.request("GET", listCommentsEp);
      issue.comments.setMulti(response.response);
      issues.multi.add(issue);
    }
    return issues;
  }

  /// Submits a comment to the specified issue.
  Future<bool> submitComment(String reportId, String comment) async {
    bool commented = false;
    String submitCommentEp = "$owner/$repo/issues/$reportId/comments";
    String deviceId = await FlutterUdid.udid;
    Map commentBody = {
      commentsBodyField:
          "$comment\n${deviceIdTemplate.replaceFirst(idMark, deviceId)}"
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
  Future<String?> uploadScreenShot(String imgPath,
      {String screenShotsBranch = "GhSnitch_ScreenShots"}) async {
    Uint8List file = File(imgPath).readAsBytesSync();
    String content = base64.encode(file);
    String fileName = imgPath.split("/").last;
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
}
