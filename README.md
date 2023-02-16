<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

## Package for open github issue for crashes, issues & proposals

## Features
- Create labels for package
	- GhSnitch-external for Errors not caught by Flutter Framework
	- GhSnitch-internal for Errors caught by Flutter Framework
  - Reported by GhSnitch Package for know which issues reported from this package
- Report bugs on github issues with specific labels,assignees, milestone
  - Automaticlly when call `listenToExceptions` method in `main` as in example
  - Manually with `report` method
- Support offline case (save locally & send later when connection exist)
- Support get issue reported with all comments
- Support submit comments from user and reply from github issues by repo owners

## TODO
- [x] Fetch issue comments & give user to discuss his issue/proposal from app with repo contributors
- [ ] Fetch PR's & give user to discuss his new feature from app with repo contributors
- [ ] Create Custom screens for Issues/PR's & screen for user to chat & discuss by comments

💡 Feel free to add any idea 

## Getting started

After install package you need to generate [fine-grained personal access token<](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) choose fine-grained personal access token & select your repo & from Repository permissions check Issues
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
  GhSnitch.initialize(
      owner: owner,
      token: const String.fromEnvironment('token'),
      repo: const String.fromEnvironment("repo"));
  if (kReleaseMode) {
    // For report exceptions & bugs Automaticlly
    GhSnitch.listenToExceptions(assignees: [owner]);
  }
  runApp(const MyApp());
```
For report issues Manually (from users) check _report method on [`example`](example/lib/main.dart)

If you want to test it in debug mode you can remove ReleaseMode condition

⚙️ Finally feel free to contribute ⚙️
