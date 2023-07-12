Sure, here you go:

# GitHub Snitch

GitHub Snitch is a Flutter package that helps you report bugs and issues on GitHub automatically. It can also be used to submit comments on existing issues.

## Features
- Report bugs on GitHub issues with specific labels, assignees, and milestones
  - Automatically when calling the `listenToExceptions` method in `main` as shown in the example
  - Manually with the `report` method
- Support offline cases (save locally and send later when a connection exists)
- Get reported issues with all comments
- Submit comments from the user and reply from GitHub issues by repository owners
- Include screenshots in the report for better issue clarification.
- Create follow labels for package
	- GhSnitch-external for Errors not caught by Flutter Framework
	- GhSnitch-internal for Errors caught by Flutter Framework
  - Reported by GhSnitch Package for knowing which issues are reported from this package


## Getting Started

After install package you need to generate [fine-grained personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) choose fine-grained personal access token & select your repo & from Repository permissions check Issues
Access: Read and write.

We need also `owner username` & `repo name`

We will use Environment variables for save this sensive keys
## Usage

For run or build app just pass --dart-define for every key as example :

```
flutter build apk --split-per-abi --dart-define owner=owner --dart-define repo=repo --dart-define token=token
```

Then Add this code before runApp method
As you see we used keys from Environment
```dart
WidgetsFlutterBinding.ensureInitialized();
  const String owner = String.fromEnvironment('owner');
  String appFlavor = 'x';
  String appVersion = '2.0.0';
  GhSnitch.initialize(
      owner: owner,
      token: const String.fromEnvironment('token'),
      repo: const String.fromEnvironment("repo"));
  if (kReleaseMode) {
    // For report exceptions & bugs Automaticlly
    GhSnitch.listenToExceptions(assignees: [owner], labels: [appFlavor, appVersion]);
  }
  runApp(const MyApp());
```
Now that GitHub Snitch is initialized, you can start reporting bugs and issues. To do this, you can call the `report` method:

```dart
GhSnitch.report(
  title: '<issue-title>',
  body: '<issue-body>',
  screenShot: '<screenshot-url>',
  screenShotBranch: '<screenshot-branch>',
  labels: <List<String>?>,
  assignees: <List<String>?>,
  milestone: <int?>,
);
```

The `report` method takes the following parameters:

* `title`: The title of the issue.
* `body`: The body of the issue.
* `screenShot`: The URL of the screenshot.
* `screenShotBranch`: The branch of the repository where the screenshot is located.
* `labels`: A list of labels for the issue.
* `assignees`: A list of users to assign the issue to.
* `milestone`: The milestone to associate the issue with.

## Listening to Exceptions

GitHub Snitch can also be used to listen to exceptions and bugs. To do this, you can call the `listenToExceptions` method:

```
GhSnitch.listenToExceptions(
  assignees: <List<String>?>,
  milestone: <int?>,
);
```

The `listenToExceptions` method takes the following parameters:

* `assignees`: A list of users to assign the issue to.
* `milestone`: The milestone to associate the issue with.

When an exception or bug is detected, GitHub Snitch will automatically create an issue on GitHub.

## Submitting Comments

GitHub Snitch can also be used to submit comments on existing issues. To do this, you can call the `submitComment` method:

```dart
GhSnitch.submitComment(
  reportId: '<issue-id>',
  comment: '<comment-text>',
);
```

The `submitComment` method takes the following parameters:

* `reportId`: The ID of the issue.
* `comment`: The text of the comment.

## Conclusion

GitHub Snitch is a powerful tool that can help you keep track of bugs and issues on GitHub. It can also be used to submit comments on existing issues. If you're looking for a way to improve your GitHub workflow, I highly recommend checking out GitHub Snitch.

Feel free to contribute to this package by opening issues or submitting pull requests on [GitHub ↗](https://github.com/M97Chahboun/github_snitch).