const String commentsBodyField = "body";
const String commentsDateField = "date";
const String deviceIdStr = "[device_id";

class Comment {
  String? body;
  String? date;
  bool isFromUser;
  List<Comment> multi = [];
  Comment({
    this.body,
    this.date,
    this.isFromUser = false,
  });

void fromJson(Map<String, dynamic> json) {
    body = json[commentsBodyField];
    date = json[commentsDateField];
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
