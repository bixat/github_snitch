import 'package:github_snitch/src/models/issue.dart';

import 'utils/github_snitch_instance.dart';

class GhSnitch {
  GhSnitch._();

  static GhSnitchInstance? _ghSnitchDelegate;

  static GhSnitchInstance get _instance {
    return _ghSnitchDelegate ??= GhSnitchInstance.instance;
  }

  /// Listen to exceptions & bugs then report it on github Automaticlly
  static void listenToExceptions({List<String>? assignees, int? milestone}) {
    _handleNotInitialized();
    _instance.listenToExceptions(milestone: milestone, assignees: assignees);
  }

  /// Initialize GhSnitch
  static initialize(
      {required String token, required String owner, required String repo}) {
    _instance.initialize(token: token, owner: owner, repo: repo);
  }

  /// Report issue or proposal manually
  static Future<bool> report(
      {required String title,
      required String body,
      List<String>? labels,
      List<String>? assignees,
      int? milestone}) {
    _handleNotInitialized();
    return _instance.report(
        title: title,
        body: body,
        labels: labels,
        assignees: assignees,
        milestone: milestone);
  }

  static _handleNotInitialized() {
    String solve =
        """GhSnitch not initialized, add this code before runApp method \nWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  GhSnitch.initialize(
      owner: dotenv.env['owner']!,
      token: dotenv.env['token']!,
      repo: dotenv.env['repo']!);
  if (kReleaseMode) {
    // For report exceptions & bugs Automaticlly
    GhSnitch.listenToExceptions();
  }""";
    assert(_instance.initialized, solve);
  }

  static Future<Issue> getReportsComments() {
    return _instance.getReportsComments();
  }

  static Future<bool> submitComment(String reportId, String comment) {
    return _instance.submitComment(reportId, comment);
  }
}
