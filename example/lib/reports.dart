import 'package:flutter/material.dart';
import 'package:github_snitch/github_snitch.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class Reports extends StatelessWidget {
  Reports({super.key});
  final TextEditingController reportTitle = TextEditingController();
  final TextEditingController reportBody = TextEditingController();
  final GlobalKey<FormState> reportFormKey = GlobalKey<FormState>();
  final ValueNotifier reportLoading = ValueNotifier(false);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
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
            List<Issue> issues = snapshot.data.multi;
            return ListView.builder(
              itemCount: issues.length,
              itemBuilder: (BuildContext context, int index) {
                Issue issue = issues[index];
                return ListTile(
                  leading: CircleAvatar(
                    maxRadius: 20,
                    child:
                        Icon(issue.isOpen ? Icons.timelapse_sharp : Icons.done),
                  ),
                  title: Text(
                    issue.title!,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (BuildContext context) {
                      return ChatScreen(issue: issue);
                    }));
                  },
                  trailing: const Icon(Icons.arrow_forward_ios),
                );
              },
            );
          } else {
            return Center(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const CircularProgressIndicator()
                    : const Text("Empty"));
          }
        },
      ),
    );
  }

  Future<dynamic> _reporteIssueOrSuggestion(BuildContext context) {
    String? path;
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            title: const Text("Report Issue or suggestion"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Form(
                key: reportFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      validator: (String? text) {
                        if (reportTitle.text.isEmpty) {
                          return "Empty title";
                        }
                        return null;
                      },
                      controller: reportTitle,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextFormField(
                      controller: reportBody,
                      maxLines: 15,
                      validator: (String? text) {
                        if (text!.isEmpty) {
                          return "Empty description";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: "Description",
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          // Pick an image
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery);
                          path = image!.path;
                        },
                        icon: const Icon(Icons.add_a_photo))
                  ],
                ),
              ),
            ),
            actions: [
              ValueListenableBuilder(
                  valueListenable: reportLoading,
                  builder: (context, _, __) {
                    return reportLoading.value
                        ? const SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator())
                        : ElevatedButton(
                            child: const Text(
                              "Report",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              // Report issues or suggestions from app users
                              await _report(context, path);
                              // your code
                            });
                  })
            ],
          );
        });
  }

  Future<void> _report(BuildContext context, String? path) async {
    bool isValid = reportFormKey.currentState!.validate();
    if (isValid) {
      reportLoading.value = true;
      bool sended = await GhSnitch.report(
          labels: ["from user"],
          assignees: [const String.fromEnvironment('owner')],
          title: reportTitle.text,
          body: reportBody.text,
          screenShotBranch: "develop",
          screenShot: path);
      reportLoading.value = false;
      if (sended) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      } else {
        const snackBar = SnackBar(
          content: Text("Somthing wrong, try later"),
        );
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }
}

class IssueComments extends StatelessWidget {
  IssueComments({super.key, required this.issue});
  final Issue issue;
  final TextEditingController commentController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: SafeArea(
          child: Container(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_outlined,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(
                  width: 2,
                ),
                CircleAvatar(
                  maxRadius: 20,
                  child:
                      Icon(issue.isOpen ? Icons.timelapse_sharp : Icons.done),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Text(
                    issue.title!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          ListView.builder(
            itemCount: issue.comments.multi.length,
            shrinkWrap: true,
            padding: const EdgeInsets.only(top: 10, bottom: 60),
            itemBuilder: (context, index) {
              Comment comment = issue.comments.multi[index];
              return Message(
                comment: comment,
              );
            },
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.only(left: 16, bottom: 10),
              height: 60,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                          hintText: "Type message...",
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(right: 20),
                    width: 60,
                    height: 60,
                    child: Center(
                      child: FloatingActionButton(
                        onPressed: () async {
                          if (commentController.text.length > 5) {
                            bool isSended = await GhSnitch.submitComment(
                                issue.id!, commentController.text);
                            if (isSended) {
                              commentController.clear();
                            } else {}
                          } else {
                            //TODO: handle else
                          }
                        },
                        backgroundColor: Colors.blue,
                        elevation: 0,
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Message extends StatelessWidget {
  const Message({super.key, required this.comment});
  final Comment comment;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          right: comment.isFromUser ? 0.0 : 60.0,
          left: comment.isFromUser ? 60.0 : 0.0),
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        decoration: BoxDecoration(
          color: comment.isFromUser ? Colors.blue[200] : Colors.grey[400],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.body!,
              style: TextStyle(
                color: comment.isFromUser ? Colors.black : Colors.white,
                fontSize: 18.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  comment.date.toString(),
                  style: TextStyle(
                    color: comment.isFromUser
                        ? Colors.black.withOpacity(0.6)
                        : Colors.white.withOpacity(0.6),
                    fontSize: 12.0,
                  ),
                ),
                Icon(
                    comment.isSended ? Icons.done : Icons.access_time_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Generated by ChatGPT3

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.issue});
  final Issue issue;
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Future<void> _handleSubmitted(String text) async {
    GhSnitch.submitComment(widget.issue.id!, _commentController.text)
        .then((value) => setState(
              () {
                widget.issue.comments.multi.last.isSended = value;
              },
            ));
    _commentController.clear();
    String formattedDate =
        DateFormat('E, d MMM yyyy HH:mm:ss').format(DateTime.now());
    setState(() {
      widget.issue.comments.multi.add(Comment(
        body: text,
        date: formattedDate,
        isFromUser: true,
        isSended: false,
      ));
    });
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 100,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.issue.title!,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.issue.comments.multi.length,
              itemBuilder: (BuildContext context, int index) {
                Comment comment = widget.issue.comments.multi[index];
                return Message(
                  comment: comment,
                );
              },
            ),
          ),
          const Divider(height: 1.0),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    onSubmitted: _handleSubmitted,
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                      contentPadding: EdgeInsets.all(16.0),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleSubmitted(_commentController.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0)
        ],
      ),
    );
  }
}
