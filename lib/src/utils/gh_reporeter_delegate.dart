
import 'package:github_reporter/github_reporter.dart';

class GhReporterDelegate {
  GhReporterDelegate._();

  static GhReporter? ghReporterDelegate;

  static GhReporter get instance {
    return ghReporterDelegate ??= GhReporter.instance;
  }

  static initialize({required token, required owner, required repo}) {
    instance.initialize(token: token, owner: owner, repo: repo);
  }
}