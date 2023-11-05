import 'package:flutter/material.dart';
import 'package:github_snitch/github_snitch.dart';
import 'package:github_snitch/src/screens/widgets/report_comment.dart';
import 'package:github_snitch/src/utils/extensions.dart';

class IssueComments extends StatelessWidget {
  final Issue issue;
  final TextEditingController commentController = TextEditingController();
  final ValueNotifier refreshComments = ValueNotifier(false);

  IssueComments({Key? key, required this.issue}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: context.pop, icon: const Icon(Icons.arrow_forward_ios))
        ],
        title: Text(
          issue.title!,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.primaryColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            maxRadius: 15,
            child: Icon(issue.isOpen ? Icons.timelapse_sharp : Icons.done),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ValueListenableBuilder(
                valueListenable: refreshComments,
                builder: (context, _, __) {
                  return ListView.builder(
                    itemCount: issue.comments.multi.length,
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 10, bottom: 100),
                    itemBuilder: (context, index) {
                      Comment comment = issue.comments.multi[index];
                      return CommentWidget(comment: comment);
                    },
                  );
                }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25.0, horizontal: 16),
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: context.backgroundColor,
                  border: Border.all(color: context.primaryColor)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(8),
                          hintText: "كتابة رسالة...",
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none),
                    ),
                  ),
                  CircleAvatar(
                    child: Center(
                      child: FloatingActionButton(
                        onPressed: () async {
                          await submitComment(context);
                        },
                        backgroundColor: context.primaryColor,
                        elevation: 0,
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5.0,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> submitComment(BuildContext context) async {
    if (commentController.text.isNotEmpty) {
      bool isSended =
          await GhSnitch.submitComment(issue.id!, commentController.text);
      if (isSended) {
        issue.comments.multi
            .add(Comment(body: commentController.text, isFromUser: true));
        refreshComments.value = !refreshComments.value;
        commentController.clear();
      } else {
        const snackBar = SnackBar(
          content: Text('حدث خطأ أثناء الإرسال، الرجاء المحاولة لاحقا'),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    }
  }
}
