import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:github_report_issues/src/prefs.dart';

import 'gh_requests.dart';
import 'gh_response.dart';

//TODO:Remove this token
//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
class GhReporter {
  GhReporter({required this.token, required this.owner, required this.repo}) {
    ghRequest = GhRequests(token);
  }
  final String token;
  final String owner;
  final String repo;
  late GhRequests ghRequest;

  Future<bool> report(
      {required String title,
      required String body,
      List<String>? labels,
      List<String>? assignees,
      int? milestone}) async {
    bool connected = await isConnected;
    if (connected) {
      await createLabel("GhReporter-external",
          "Errors not caught by Flutter Framework", "f0c2dd");
      await createLabel("GhReporter-internal",
          "Errors caught by Flutter Framework", "6a4561");
      String issueEndpoint = "$owner/$repo/issues";
      bool notCreated = await issueNotCreated(title, issueEndpoint);
      if (notCreated) {
        Map<String, dynamic> issueBody = {
          "owner": owner,
          "repo": repo,
          "title": title,
          "body": body,
        };
        if (assignees != null) {
          issueBody["assignees"] = assignees;
        }
        if (labels != null) {
          issueBody["labels"] = labels;
        }

        if (milestone != null) {
          issueBody["milestone"] = milestone;
        }

        String issueBodyToString = json.encode(issueBody);

        GhResponse response =
            await ghRequest.request("POST", issueEndpoint, issueBodyToString);
        if (response.statusCode == 201) {
          log("✅ Issue reported");
          return true;
        } else {
          log("❌ Echec to report Issue");
          log(response.response.toString());
          return false;
        }
      } else {
        log("Issue Already Created");
        return true;
      }
    } else {
      Map issue = {
        "title": title,
        "body": body,
      };
      String issueToString = json.encode(issue);
      Prefs.set("github_report_issue${title.hashCode}", issueToString);
      return false;
    }
  }

  reportSavedIssues() async {
    List prefsKeys = (await Prefs.getKeys()).toList();
    List olderIssues =
        prefsKeys.where((e) => e.contains("github_report_issue")).toList();
    print(olderIssues);
    if (olderIssues.isNotEmpty) {
      for (var e in olderIssues) {
        String? issueFromPref = await Prefs.get(e);
        var issueToMap = json.decode(issueFromPref!);
        bool reported =
            await report(title: issueToMap["title"], body: issueToMap["body"]);
        if (reported) {
          Prefs.remove(e);
        }
      }
    }
  }

  Future<void> initialze() async {
    reportSavedIssues();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      bool issueNotFromPackage =
          !details.stack.toString().contains("github_report_issues");
      if (issueNotFromPackage) {
        report(
            title: details.exception.toString(),
            labels: ["GhReporter-external", "bug"],
            body:
                "${details.exception}\n${details.stack.toString().substring(0, details.stack.toString().indexOf("#10"))}");
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      bool issueNotFromPackage =
          !stack.toString().contains("github_report_issues");
      if (issueNotFromPackage) {
        report(
            title: error.toString(),
            body: "$error\n$stack",
            labels: ["GhReporter-internal", "bug"]);
      }
      return true;
    };
  }

  createLabel(String label, String description, String color) async {
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
      if (response.statusCode == 201) {
        log("✅ Label Created");
        Prefs.setLabel(label, true);
      } else {
        log("❌ Echec to Create Label");
        log(response.response.toString());
      }
    }
  }

  Future<bool> issueNotCreated(String title, String endpoint) async {
    String params = "?state=all&labels=GhReporter-external";
    GhResponse ghResponse =
        await ghRequest.request("GET", endpoint + params, "");
    if (ghResponse.statusCode == 200) {
      bool notExist = true;
      for (var e in (ghResponse.response as List)) {
        if (e["title"] == title) {
          notExist = false;
        }
      }
      return notExist;
    }
    return false;
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
