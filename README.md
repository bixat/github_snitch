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

Package for report app crashes & issues to it github repo

## Features
- Create labels for package
	- GhReporter-external for Errors not caught by Flutter Framework
	- GhReporter-internal for Errors caught by Flutter Framework
- Report bugs on github issues with specific labels,assignees, milestone
  - Automatic when initialize package as in example
  - Manually with report method
- Support offline case (save locally & send later when connection exist)

## Getting started

After install package you need to generate [Personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
We need also `owner username` & `repo name`

We will use [dotenv](https://pub.dev/packages/flutter_dotenv) package for save this sensive keys
## Usage
Create file .env
```
owner=owner username
repo=repo name
token=token genrated
```
```And add this file to .gitignore```

Then Add this code before runApp method
```dart
if (kReleaseMode) {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    GhReporter ghReporter = GhReporter(
        owner: dotenv.env['owner']!,
        token: dotenv.env['token']!,
        repo: dotenv.env['repo']!);
    ghReporter.initialze();
  }
  runApp(const MyApp());
```

If you want to test it in debug mode you can remove lReleaseMode condition


[`example`](example/lib/main.dart).

