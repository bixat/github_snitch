import 'package:flutter/material.dart';
import 'package:github_snitch/github_snitch.dart';
import 'package:github_snitch/src/screens/report_chat.dart';
import 'package:github_snitch/src/screens/widgets/report_form.dart';
import 'package:github_snitch/src/utils/extensions.dart';

// ignore: must_be_immutable
class Reports extends StatelessWidget {
  final ValueNotifier reportLoading = ValueNotifier(false);
  List<Issue> issues = [];
  Reports({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            "الإبلاغ عن إقتراح أو مشكلة",
            // style: TextStyle(color: context.primaryColor),
          ),
          actions: [
            IconButton(
                onPressed: () {
                  _reporteIssueOrSuggestion(context);
                },
                icon: const Icon(Icons.add))
          ]),
      body: FutureBuilder<Issue>(
        future: GhSnitch.getReportsComments(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            issues = snapshot.data.multi;
            return ValueListenableBuilder(
                valueListenable: reportLoading,
                builder: (context, _, __) {
                  return ListView.builder(
                    itemCount: issues.length,
                    itemBuilder: (BuildContext context, int index) {
                      Issue issue = issues[index];
                      final commentsLength = issue.comments.multi.length;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(8.0),
                            leading: Tooltip(
                              message: issue.isOpen ? "In progress" : "Closed",
                              child: CircleAvatar(
                                maxRadius: 20,
                                child: Icon(issue.isOpen
                                    ? Icons.timelapse_sharp
                                    : Icons.done),
                              ),
                            ),
                            subtitle: Text(
                                "$commentsLength Comment${commentsLength > 1 ? "s" : ""}"),
                            title: Text(
                              issue.title!,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              context.push(IssueComments(issue: issue));
                            },
                            trailing: const Icon(Icons.arrow_forward_ios),
                          ),
                        ),
                      );
                    },
                  );
                });
          } else {
            return Center(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const CircularProgressIndicator()
                    : const Text(
                        "لم تبلغ أي مشكلة أو إقتراح"
                        "\n"
                        "لتبليغ إقتراح أو مشكلة إضغط على +",
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textDirection: TextDirection.rtl,
                      ));
          }
        },
      ),
    );
  }

  Future<dynamic> _reporteIssueOrSuggestion(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return ReportForm(reportLoading, issues: issues);
        });
  }
}
