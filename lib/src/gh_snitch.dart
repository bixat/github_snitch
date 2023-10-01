import 'package:github_snitch/src/models/issue.dart';

import 'utils/github_snitch_instance.dart';

/// A class that provides functionality to report issues and bugs on GitHub.
///
/// This class provides static methods for initializing the `GhSnitch` instance,
/// reporting issues, submitting comments, and listening to exceptions thrown in the app.
class GhSnitch {
  GhSnitch._();

  static GhSnitchInstance? _ghSnitchDelegate;

  /// A private static variable that returns the `GhSnitchInstance` instance used to interact with the GitHub API.
  static GhSnitchInstance get _instance {
    return _ghSnitchDelegate ??= GhSnitchInstance.instance;
  }

  /// Listens to exceptions thrown in the app and reports them as issues on GitHub.
  ///
  /// This method sets up a Flutter error handler to catch uncaught exceptions and report them as issues on GitHub.
  /// The issues will be created on the repository specified in the `initialize()` method.
  ///
  /// The optional `assignees` parameter is a list of GitHub usernames that will be assigned to the created issues.
  ///
  /// The optional `milestone` parameter is an integer that specifies the milestone for the created issues.
  ///
  /// Example usage:
  ///
  /// ```
  /// GhSnitch.listenToExceptions(assignees: ['username1', 'username2'], milestone: 1);
  /// ```
  static void listenToExceptions(
      {List<String>? assignees, int? milestone, List<String>? labels}) {
    _handleNotInitialized();
    _instance.listenToExceptions(
        milestone: milestone, assignees: assignees, labels: labels);
  }

  /// Initializes the `GhSnitch` instance with a GitHub token, owner of the repository, and the repository name.
  ///
  /// This method should only be called once in your application.
  ///
  /// Example usage:
  ///
  /// ```
  /// GhSnitch.initialize(token: 'your_github_token_here', owner: 'your_github_repo_owner_here', repo: 'your_github_repo_name_here');
  /// ```
  static initialize(
      {required String token, required String owner, required String repo}) {
    _instance.initialize(token: token, owner: owner, repo: repo);
  }

  /// Reports an issue or bug on GitHub with the given title and body.
  ///
  /// It also optionally allows for a screenshot, labels, assignees, and milestone to be added to the issue.
  ///
  /// This method returns a `Future<bool>` indicating whether the issue was reported successfully.
  ///
  /// Example usage:
  ///
  /// ```
  /// await GhSnitch.report(title: 'Example issue', body: 'This is an example issue report.', labels: ['bug']);
  /// ```
  static Future<bool> report(
      {required String title,
      required String body,
      String? screenShot,
      String? screenShotBranch,
      List<String>? labels,
      List<String>? assignees,
      int? milestone,
      String? userId}) {
    _handleNotInitialized();
    return _instance.report(
        title: title,
        body: body,
        screenShot: screenShot,
        screenShotsBranch: screenShotBranch,
        labels: labels,
        assignees: assignees,
        milestone: milestone,
        userId: userId);
  }

  /// Checks if the `GhSnitch` instance has been initialized or not.
  ///
  /// If it has not been initialized, it throws an assertion error with instructions on how to properly initialize the instance.
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

  /// Retrieves the comments for all reported issues.
  ///
  /// This method returns a `Future<Issue>`.
  ///
  /// Example usage:
  ///
  /// ```
  /// final comments = await GhSnitch.getReportsComments();
  /// ```
  static Future<Issue> getReportsComments() {
    return _instance.getReportsComments();
  }

  /// Submits a comment to the specified report ID.
  ///
  /// This method returns a `Future<bool>` indicating whether the comment was submitted successfully.
  ///
  /// Example usage:
  ///
  /// ```
  /// await GhSnitch.submitComment('123456789', 'This is a comment on the issue with ID 123456789.');
  /// ```
  static Future<bool> submitComment(String reportId, String comment) {
    return _instance.submitComment(reportId, comment);
  }
}
