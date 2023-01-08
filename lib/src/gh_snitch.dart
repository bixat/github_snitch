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
  const String owner = String.fromEnvironment('owner');
  GhSnitch.initialize(
      owner: owner,
      token: const String.fromEnvironment('token'),
      repo: const String.fromEnvironment("repo"));
  if (!kReleaseMode) {
    // For report exceptions & bugs Automaticlly
    GhSnitch.listenToExceptions(assignees: [owner]);
  }""";
    assert(_instance.initialized, solve);
  }
}
