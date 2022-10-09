import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'utils/constants.dart';
import 'utils/gh_requests.dart';
import 'utils/gh_response.dart';
import 'utils/prefs.dart';

class GhReporter {
  late String token;
  late String owner;
  late String repo;
  late GhRequest ghRequest;
  static GhReporter get instance => GhReporter();
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
      await createLabel(fromGhReporterPackage,
          "Errors caught by Github reporter package", "970206");
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
          labels.add(fromGhReporterPackage);
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

  initialize({required token, required owner, required repo}) {
    this.token = token;
    this.owner = owner;
    this.repo = repo;
    ghRequest = GhRequest(token);
  }

  Future<void> listenToExceptions() async {
    reportSavedIssues();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      prepareAndReport(
          details.exception.toString(), details.stack!, externalIssueLabel);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      prepareAndReport(error.toString(), stack, internalIssueLabel);
      return true;
    };
  }

  prepareAndReport(String exception, StackTrace stack, String label) {
    bool issueNotFromPackage =
        !stack.toString().contains("github_report_issues");
    if (issueNotFromPackage) {
      String body = stack.toString();
      if (body.contains("#10")) {
        body = body.substring(0, stack.toString().indexOf("#10"));
      }
      report(
          title: exception.toString(),
          labels: [label, bugLabel],
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
      if (response.statusCode == 201 ||
          response.response["errors"][0]["code"] == "already_exists") {
        log("✅ Label Created");
        Prefs.setLabel(label, true);
      } else {
        log("❌ Echec to Create Label");
        log(response.response.toString());
      }
    }
  }

  Future<bool> issueNotCreated(String title, String endpoint) async {
    String params = "?state=all&labels=$fromGhReporterPackage";
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
