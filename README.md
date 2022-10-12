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

## TODO
- [ ] Fetch issue comments & give user to discuss his issue/proposal from app with repo contributors

💡 Feel free to add any idea 

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
WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  GhSnitch.initialize(
      owner: dotenv.env['owner']!,
      token: dotenv.env['token']!,
      repo: dotenv.env['repo']!);
  if (kReleaseMode) {
    // For report exceptions & bugs Automaticlly
    GhReporte.listenToExceptions();
  }
  runApp(const MyApp());
```
For report issues Manually (from users) check _report method on [`example`](example/lib/main.dart)

If you want to test it in debug mode you can remove ReleaseMode condition

⚙️ Finally feel free to contribute ⚙️