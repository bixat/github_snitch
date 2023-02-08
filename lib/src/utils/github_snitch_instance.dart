import 'dart:convert';
import 'dart:developer';

import 'package:client_information/client_information.dart';
import 'package:flutter/foundation.dart';
import 'package:github_snitch/src/utils/compare.dart';
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

  Future<bool> report(
      {required String title,
      required String body,
      String? screenShot,
      String? screenShotsBranch,
      List<String>? labels,
      List<String>? assignees,
      int? milestone}) async {
    bool connected = await isConnected;
    if (connected) {
      await createLabel(externalIssueLabel,
          "Errors not caught by Flutter Framework", "f0c2dd");
      await createLabel(
          internalIssueLabel, "Errors caught by Flutter Framework", "6a4561");
      await createLabel(fromGhRSnitchPackage,
          "Errors caught by Github Snitch package", "970206");
      String issueEndpoint = "$owner/$repo/issues";
      bool notCreated = await issueIsNew(body, issueEndpoint);
      if (notCreated) {
        String? url = "";
        if (screenShot != null) {
          url = await uploadScreenShot(screenShot,
              screenShotsBranch: screenShotsBranch!);
          url = "\n## ScreenShot \n![]($url)";
        }
        Map<String, dynamic> issueBody = {
          ownerBody: owner,
          repoBody: repo,
          bodyTitle: title,
          bodyBody: body + url,
        };
        if (assignees != null) {
          issueBody["assignees"] = assignees;
        }
        if (labels != null) {
          issueBody["labels"] = labels;
          labels.add(fromGhRSnitchPackage);
        }

        if (milestone != null) {
          issueBody["milestone"] = milestone;
        }

        String issueBodyToString = json.encode(issueBody);

        GhResponse response =
            await ghRequest.request("POST", issueEndpoint, issueBodyToString);
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
      } else {
        log("✅ Issue Already Reported");
        return true;
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
      log("✅ GhSnitch initialized $repo");
    }
  }

  void listenToExceptions({
    List<String>? assignees,
    int? milestone,
  }) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      prepareAndReport(
          details.exception.toString(), details.stack!, externalIssueLabel,
          assignees: assignees, milestone: milestone);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      prepareAndReport(error.toString(), stack, internalIssueLabel,
          assignees: assignees, milestone: milestone);
      return true;
    };
    log("✅ GhSnitch Listen to exceptions");
  }

  Future<bool> prepareAndReport(
    String exception,
    StackTrace stack,
    String label, {
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
          labels: [label, bugLabel],
          body: "```\n$body ```",
          milestone: milestone,
          assignees: assignees);
    }
    return Future.value(false);
  }

  Future<void> createLabel(
      String label, String description, String color) async {
    bool labelNotCreated = !(await Prefs.checkIfExist(label));
    if (labelNotCreated) {
      String labelEndpoint = "$owner/$repo/labels";
      Map labelBody = {
        "name": label,
        "description": description,
        "color": color
      };
      String labelBodyToString = json.encode(labelBody);
      GhResponse response =
          await ghRequest.request("POST", labelEndpoint, labelBodyToString);
      if (response.statusCode == 201 ||
          response.response["errors"][0]["code"] == "already_exists") {
        log("✅ $label Label Created");
        Prefs.setLabel(label, true);
      } else {
        log("❌ Echec to Create $label Label");
        log(response.response.toString());
      }
    } else {
      log("✅ $label Label Already Created");
    }
  }

  Future<bool> issueIsNew(String body, String endpoint) async {
    String params = "?state=all&labels=$fromGhRSnitchPackage";
    GhResponse ghResponse =
        await ghRequest.request("GET", endpoint + params, "");
    if (ghResponse.statusCode == 200) {
      bool notExist = true;
      for (var e in (ghResponse.response as List)) {
        double comparePercent = compare(e[bodyBody], body);
        if (comparePercent >= 80.0) {
          notExist = false;
        }
      }
      return notExist;
    }
    return false;
  }

  Future<Issue> getReportsComments() async {
    final Issue issues = Issue();
    Set<String> keys = await Prefs.getKeys();
    List issueKeys = keys.where((e) => e.contains("gh_issue_")).toList();
    ClientInformation info = await ClientInformation.fetch();
    for (var key in issueKeys) {
      String? issueFields = await Prefs.get(key);
      var issueFieldsDecoded = json.decode(issueFields!);
      final Issue issue = Issue(deviceId: info.deviceId);
      issue.fromJson(issueFieldsDecoded);
      String listCommentsEp = "$owner/$repo/issues/${issue.id}/comments";
      GhResponse response = await ghRequest.request("GET", listCommentsEp, "");
      issue.comments!.setMulti(response.response);
      issues.multi.add(issue);
    }
    return issues;
  }

  Future<bool> submitComment(String reportId, String comment) async {
    bool commented = false;
    String submitCommentEp = "$owner/$repo/issues/$reportId/comments";
    ClientInformation info = await ClientInformation.fetch();
    Map commentBody = {
      commentsBodyField:
          "$comment\n${deviceIdTemplate.replaceFirst(idMark, info.deviceId)}"
    };
    String commentBodyToString = json.encode(commentBody);
    GhResponse response =
        await ghRequest.request("POST", submitCommentEp, commentBodyToString);
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

    GhResponse response = await ghRequest.request("PUT", uploadImgEp, data);
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

  Future get isConnected async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
  }
}
