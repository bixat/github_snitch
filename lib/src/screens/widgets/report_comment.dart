import 'package:flutter/material.dart';
import 'package:github_snitch/github_snitch.dart';
import 'package:github_snitch/src/utils/extensions.dart';

class CommentWidget extends StatelessWidget {
  final Comment comment;

  const CommentWidget({Key? key, required this.comment}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          left: comment.isFromUser ? 16 : 28,
          right: comment.isFromUser ? 28 : 16,
          top: 10,
          bottom: 10),
      child: Align(
        alignment:
            (comment.isFromUser ? Alignment.topRight : Alignment.topLeft),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: (comment.isFromUser
                ? context.primaryColor
                : context.accentColor),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                comment.body!,
                style: TextStyle(color: context.backgroundColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
