import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';

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
          labels.add(fromGhRSnitchPackage);
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

  void initialize(
      {required String token, required String owner, required String repo}) {
    this.token = token;
    this.owner = owner;
    this.repo = repo;
    ghRequest = GhRequest(token);
  }

  void listenToExceptions() {
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

  Future<bool> prepareAndReport(
      String exception, StackTrace stack, String label) {
    bool issueNotFromPackage = !stack.toString().contains("github_snitch");
    if (issueNotFromPackage) {
      String body = stack.toString();
      if (body.contains("#10")) {
        body = body.substring(0, stack.toString().indexOf("#10"));
      }
      return report(
          title: exception.toString(),
          labels: [label, bugLabel],
          body: "**$exception**\n\n```$body```");
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

  Future<bool> issueNotCreated(String title, String endpoint) async {
    String params = "?state=all&labels=$fromGhRSnitchPackage";
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
