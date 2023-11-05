import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:github_snitch/github_snitch.dart';
import 'package:github_snitch/src/utils/extensions.dart';
import 'package:image_picker/image_picker.dart';

// ignore: must_be_immutable
class ReportForm extends StatelessWidget {
  final List<Issue>? issues;
  final ValueNotifier reportLoading;
  ReportForm(this.reportLoading, {super.key, this.issues});
  Uint8List? screenShot;
  final TextEditingController reportTitle = TextEditingController();
  final TextEditingController reportBody = TextEditingController();
  final GlobalKey<FormState> reportFormKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(24.0),
      scrollable: true,
      title: const Text('الإبلاغ عن مشكلة أو إقتراح'),
      content: Form(
        key: reportFormKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              validator: (String? text) {
                if (reportTitle.text.isEmpty) {
                  return "الرجاء وضع عنوان";
                }
                return null;
              },
              controller: reportTitle,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: context.primaryColor), //<-- SEE HERE
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: context.primaryColor), //<-- SEE HERE
                ),
                labelText: 'عنوان',
                labelStyle: TextStyle(
                    fontWeight: FontWeight.bold, color: context.primaryColor),
              ),
            ),
            const SizedBox(
              height: 10.0,
            ),
            TextFormField(
              controller: reportBody,
              maxLines: 15,
              validator: (String? text) {
                if (text!.isEmpty) {
                  return "الرجاء وضع وصف";
                }
                return null;
              },
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: context.primaryColor), //<-- SEE HERE
                ),
                border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: context.primaryColor), //<-- SEE HERE
                ),
                labelText: 'تفاصيل المشكلة أو الإقتراح',
                hintText: "Type your suggestion or issue",
                labelStyle: TextStyle(
                    fontWeight: FontWeight.bold, color: context.primaryColor),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("إرفاق صورة"),
                IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      screenShot = await image!.readAsBytes();
                    },
                    icon: Icon(
                      Icons.add_a_photo,
                      color: Theme.of(context).primaryColor,
                    )),
              ],
            )
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        ElevatedButton(
            style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(context.primaryColor)),
            onPressed: context.pop,
            child: Text(
              "إلغاء",
              style: TextStyle(color: Theme.of(context).colorScheme.background),
            )),
        ValueListenableBuilder(
            valueListenable: reportLoading,
            builder: (context, _, __) {
              return reportLoading.value
                  ? SizedBox(
                      height: 20.0,
                      width: 20.0,
                      child: CircularProgressIndicator(
                        color: context.primaryColor,
                      ))
                  : ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(context.accentColor)),
                      child: Text(
                        "إبلاغ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.background),
                      ),
                      onPressed: () async {
                        _report(context, screenShot);
                        // your code
                      });
            })
      ],
    );
  }

  Future<void> _report(BuildContext context, Uint8List? screenShot) async {
    bool isValid = reportFormKey.currentState!.validate();
    if (isValid) {
      reportLoading.value = true;
      bool sended = await GhSnitch.report(
          labels: ["from user"],
          assignees: ['M97Chahboun'],
          title: reportTitle.text,
          body: reportBody.text,
          screenShot: screenShot,
          screenShotBranch: "screenshots");
      reportLoading.value = false;
      if (sended && issues != null) {
        issues!.add(Issue.fromJson(
            {issueTitleField: reportTitle.text, issueStateField: 'open'}));
        if (context.mounted) context.pop();
      } else {
        // Fluttertoast.showToast(
        //     msg: 'حدث خطأ أثناء الإرسال، الرجاء المحاولة لاحقا',
        //     backgroundColor: Colors.redAccent);
      }
    }
  }
}
