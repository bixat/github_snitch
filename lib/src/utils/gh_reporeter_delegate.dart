import '../report_issue.dart';

class GhReporterDelegate {
  GhReporterDelegate._();

  static GhReporter? ghReporterDelegate;

  static GhReporter get instance {
    return ghReporterDelegate ??= GhReporter.instance;
  }

  /// Listen to exceptions & bugs then report it on github Automaticlly
  static void listenToExceptions() {
    instance.listenToExceptions();
  }

  /// Initialize GhReporter
  static initialize({required token, required owner, required repo}) {
    instance.initialize(token: token, owner: owner, repo: repo);
  }

  /// Report issue or proposal manually
  static Future<bool> report(
      {required String title,
      required String body,
      List<String>? labels,
      List<String>? assignees,
      int? milestone}) {
    return instance.report(
        title: title,
        body: body,
        labels: labels,
        assignees: assignees,
        milestone: milestone);
  }
  
}
