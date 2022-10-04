import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'gh_requests.dart';
import 'gh_response.dart';

//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
class GhReporter {
  GhReporter({required this.token, required this.owner, required this.repo}) {
    ghRequest = GhRequests(token);
  }
  final String token;
  final String owner;
  final String repo;
  late GhRequests ghRequest;

  void report(
      {required String title,
      required String body,
      List<String>? labels,
      List<String>? assignees,
      int? milestone}) async {
    if (!kReleaseMode) {
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
        } else {
          log("❌ Echec to report Issue");
          log(response.response.toString());
        }
      } else {
        log("Issue Already Created");
      }
    }
  }

  Future<void> overrideExceptions() async {
    await createLabel("GhReporter-external",
        "Errors not caught by Flutter Framework", "f0c2dd");
    await createLabel(
        "GhReporter-internal", "Errors caught by Flutter Framework", "6a4561");

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (!details.stack.toString().contains("github_report_issues")) {
        report(
            title: details.exception.toString(),
            labels: ["GhReporter-external", "bug"],
            body:
                "${details.exception}\n${details.stack.toString().substring(0, details.stack.toString().indexOf("#10"))}");
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (!stack.toString().contains("github_report_issues")) {
        report(
            title: error.toString(),
            body: "$error\n$stack",
            labels: ["GhReporter-internal", "bug"]);
      }
      return true;
    };
  }

  createLabel(String label, String description, String color) async {
    String labelEndpoint = "$owner/$repo/labels";

    Map labelBody = {"name": label, "description": description, "color": color};

    String labelBodyToString = json.encode(labelBody);
    GhResponse response =
        await ghRequest.request("POST", labelEndpoint, labelBodyToString);
    if (response.statusCode == 201) {
      log("✅ Label Created");
    } else {
      log("❌ Echec to Create Label");
      log(response.response.toString());
    }
  }

  Future<bool> issueNotCreated(String title, String endpoint) async {
    Map<dynamic, dynamic> filterBody = {
      "state": "all",
      "labels": ["GhReporter-external", "GhReporter-external"]
    };
    String encodeBody = json.encode(filterBody);
    GhResponse ghResponse =
        await ghRequest.request("GET", "$endpoint?title=$title", encodeBody);
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
}
