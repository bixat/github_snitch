import 'package:flutter/material.dart';
import 'package:github_snitch/github_snitch.dart';
import 'package:github_snitch/src/screens/report_chat.dart';
import 'package:github_snitch/src/screens/widgets/report_form.dart';
import 'package:github_snitch/src/utils/extensions.dart';

const maxWidth = 760.0;

// ignore: must_be_immutable
class Reports extends StatelessWidget {
  final ValueNotifier reportLoading = ValueNotifier(false);
  List<Issue> issues = [];
  Reports({super.key});
  Widget selectedIssue = const StartScreen();
  final updateSelectedIssue = ValueNotifier(false);
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isLg = width > maxWidth;
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            "Report a suggestion or issue",
          ),
          actions: [
            IconButton(
                onPressed: () {
                  _reporteIssueOrSuggestion(context);
                },
                icon: const Icon(Icons.add))
          ]),
      body: ValueListenableBuilder(
          valueListenable: updateSelectedIssue,
          builder: (context, _, __) {
            return Row(
              children: [
                Expanded(
                  child: FutureBuilder<Issue>(
                    future: GhSnitch.getReportsComments(),
                    builder: (BuildContext context,
                        AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.hasData) {
                        issues = snapshot.data.multi;
                        return ValueListenableBuilder(
                            valueListenable: reportLoading,
                            builder: (context, _, __) {
                              return ListView.builder(
                                itemCount: issues.length,
                                itemBuilder: (BuildContext context, int index) {
                                  Issue issue = issues[index];
                                  final commentsLength =
                                      issue.comments.multi.length;
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Card(
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(8.0),
                                        leading: Tooltip(
                                          message: issue.isOpen
                                              ? "In progress"
                                              : "Closed",
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
                                          final comment =
                                              IssueComments(issue: issue);
                                          if (isLg) {
                                            selectedIssue = comment;
                                            updateSelectedIssue.value =
                                                !updateSelectedIssue.value;
                                          } else {
                                            context.push(comment);
                                          }
                                        },
                                        trailing:
                                            const Icon(Icons.arrow_forward_ios),
                                      ),
                                    ),
                                  );
                                },
                              );
                            });
                      } else {
                        return Center(
                            child: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? const CircularProgressIndicator()
                                : const Text(
                                    "No issue or suggestion reported"
                                    "\n"
                                    "To report a suggestion or issue, click +",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    textDirection: TextDirection.rtl,
                                  ));
                      }
                    },
                  ),
                ),
                if (isLg) const VerticalDivider(),
                if (isLg)
                  Expanded(
                    child: selectedIssue,
                  )
              ],
            );
          }),
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

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("select issue & start chating with support"),
    );
  }
}
