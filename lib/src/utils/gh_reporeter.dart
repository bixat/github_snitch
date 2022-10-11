import '../report_issue.dart';

class GhReporter {
  GhReporter._();

  static GhReporterIssues? _ghReporterDelegate;

  static GhReporterIssues get _instance {
    return _ghReporterDelegate ??= GhReporterIssues.instance;
  }

  /// Listen to exceptions & bugs then report it on github Automaticlly
  static void listenToExceptions() {
    _handleNotInitialized();
    _instance.listenToExceptions();
  }

  /// Initialize GhReporter
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
        """GhReporter not initialized, add this code before runApp method \nWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  GhReporterDelegate.initialize(
      owner: dotenv.env['owner']!,
      token: dotenv.env['token']!,
      repo: dotenv.env['repo']!);
  if (kReleaseMode) {
    // For report exceptions & bugs Automaticlly
    GhReporterDelegate.listenToExceptions();
  }""";
    assert(_instance.initialized, solve);
  }
}
