import 'package:github_snitch/src/models/comment.dart';

const String issueIdField = "number";
const String issueTitleField = "title";
const String issueStateField = "state";
const String issueBodyField = "body";
const String issueLabelsField = "labels";
const String issueFieldMilstone = "milestone";
const String issueCommentsField = "comments";

class Issue {
  String? id;
  String? title;
  String? state;
  bool isOpen = false;
  Comment comments = Comment();
  List<Issue> multi = [];
  List<String> labels = [];
  String? body;
  int? milestone;

  Issue();

  Issue.fromJson(Map<String, dynamic> json) {
    id = json[issueIdField].toString();
    title = json[issueTitleField];
    state = json[issueStateField];
    labels = List<String>.from(json[issueLabelsField]);
    body = json[issueBodyField];
    milestone = json[issueFieldMilstone];
    isOpen = state == "open";
  }
}
