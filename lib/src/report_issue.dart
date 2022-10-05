import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'constants.dart';
import 'gh_requests.dart';
import 'gh_response.dart';
import 'prefs.dart';

class GhReporter {
  GhReporter({required this.token, required this.owner, required this.repo}) {
    ghRequest = GhRequest(token);
  }
  final String token;
  final String owner;
  final String repo;
  late GhRequest ghRequest;

  Future<bool> report(
      {required String title,
      required String body,
      List<String>? labels,
      List<String>? assignees,
      int? milestone}) async {
    bool connected = await isConnected;
    if (connected) {
      await createLabel(externalIssueLabel,
          "Errors not caught by Flutter Framework", "f0c2dd");
      await createLabel(
          internalIssueLabel, "Errors caught by Flutter Framework", "6a4561");
      String issueEndpoint = "$owner/$repo/issues";
      bool notCreated = await issueNotCreated(title, issueEndpoint);
      if (notCreated) {
        Map<String, dynamic> issueBody = {
          ownerBody: owner,
          repoBody: repo,
          bodyTitle: title,
          bodyBody: body,
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
        bodyTitle: title,
        bodyBody: body,
        dateBody: DateTime.now().toUtc().toString()
      };
      String issueToString = json.encode(issue);
      Prefs.set("github_report_issue${title.hashCode}", issueToString);
      return true;
    }
  }

  reportSavedIssues() async {
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
        }
      }
    }
  }

  Future<void> initialize() async {
    reportSavedIssues();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      prepareIssue(
          details.exception.toString(), details.stack!, externalIssueLabel);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      prepareIssue(error.toString(), stack, internalIssueLabel);
      return true;
    };
  }

  prepareIssue(String exception, StackTrace stack, String label) {
    bool issueNotFromPackage =
        !stack.toString().contains("github_report_issues");
    if (issueNotFromPackage) {
      String body = stack.toString();
      if (body.contains("#10")) {
        body = body.substring(0, stack.toString().indexOf("#10"));
      }
      report(
          title: exception.toString(),
          labels: [label, "bug"],
          body: "**$exception**\n\n```$body```");
    }
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
    String params = "?state=all&labels=bug";
    GhResponse ghResponse =
        await ghRequest.request("GET", endpoint + params, "");
    if (ghResponse.statusCode == 200) {
      bool notExist = true;
      for (var e in (ghResponse.response as List)) {
        if (e[bodyTitle] == title) {
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
