import 'package:github_snitch/src/models/comment.dart';

const String issueIdField = "number";
const String issueTitleField = "title";
const String issueStateField = "state";
const String issueCommentsField = "comments";

class Issue {
  String? id;
  String? title;
  String? state;
  bool isOpen = false;
  Comment comments = Comment();
  List<Issue> multi = [];

  Issue();

  Issue.fromJson(Map<String, dynamic> json) {
    id = json[issueIdField].toString();
    title = json[issueTitleField];
    state = json[issueStateField];
    isOpen = state == "open";
  }
}
