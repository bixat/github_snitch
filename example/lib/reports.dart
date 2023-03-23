import 'package:flutter/material.dart';
import 'package:github_snitch/github_snitch.dart';
import 'package:image_picker/image_picker.dart';

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
                      return IssueComments(issue: issue);
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
                        icon: Icon(Icons.account_box),
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
                        icon: Icon(Icons.email),
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
              return CommentWidget(comment: comment);
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

class CommentWidget extends StatelessWidget {
  const CommentWidget({super.key, required this.comment});
  final Comment comment;
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
            color:
                (comment.isFromUser ? Colors.grey.shade300 : Colors.blueAccent),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(comment.body!),
            ],
          ),
        ),
      ),
    );
  }
}
