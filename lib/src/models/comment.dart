import 'package:intl/intl.dart';

const String commentsBodyField = "body";
const String commentsCreatedAtField = "created_at";
const String deviceIdStr = "[device_id";

class Comment {
  String? body;
  String? date;
  bool isFromUser;
  bool isSended;
  List<Comment> multi = [];
  Comment({
    this.body,
    this.date,
    this.isFromUser = false,
    this.isSended = true,
  });

  void fromJson(Map<String, dynamic> json) {
    body = json[commentsBodyField];
    date = json[commentsCreatedAtField];
    String formattedDate =
        DateFormat('E, d MMM yyyy HH:mm:ss').format(DateTime.parse(date!));
    date = formattedDate;
    isFromUser = body!.contains(deviceIdStr);
    if (isFromUser) {
      body = body!
          .replaceRange(body!.indexOf(deviceIdStr), body!.length, "")
          .trim();
    }
  }

  void setMulti(List data) {
    List<Comment> listOfComent = data.map((e) {
      Comment comment = Comment();
      comment.fromJson(e);
      return comment;
    }).toList();
    multi = listOfComent;
  }
}
