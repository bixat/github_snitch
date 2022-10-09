import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:github_reporter/github_reporter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  GhReporterDelegate.initialize(
      owner: dotenv.env['owner']!,
      token: dotenv.env['token']!,
      repo: dotenv.env['repo']!);
  if (kReleaseMode) {
    // For report exceptions & bugs Automaticlly
    GhReporterDelegate.listenToExceptions();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report Issues on your repo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Github Reporter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final TextEditingController reportTitle = TextEditingController();
  final TextEditingController reportBody = TextEditingController();
  final GlobalKey<FormState> reportFormKey = GlobalKey<FormState>();
  final ValueNotifier reportLoading = ValueNotifier(false);
  void _incrementCounter() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return const Screen([]);
    }));
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  int h = 55;
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () {
                _reporteIssueOrSuggestion(context);
              },
              icon: const Icon(Icons.report))
        ],
      ),
      body: Row(
        // Column is also a layout widget. It takes a list of children and
        // arranges them vertically. By default, it sizes itself to fit its
        // children horizontally, and tries to be as tall as its parent.
        //
        // Invoke "debug painting" (press "p" in the console, choose the
        // "Toggle Debug Paint" action from the Flutter Inspector in Android
        // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
        // to see the wireframe for each widget.
        //
        // Column has various properties to control how it sizes itself and
        // how it positions its children. Here we use mainAxisAlignment to
        // center the children vertically; the main axis here is the vertical
        // axis because Columns are vertical (the cross axis would be
        // horizontal).
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'You have pushed the button this many times:',
          ),
          //Text(h),
          Text(
            '$_counter',
            style: Theme.of(context).textTheme.headline4,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<dynamic> _reporteIssueOrSuggestion(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            title: const Text("Report Issue or suggestion"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Form(
                key: reportFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      validator: (String? text) {
                        if (reportTitle.text.isEmpty) {
                          return "Empty title";
                        }
                        return null;
                      },
                      controller: reportTitle,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        icon: Icon(Icons.account_box),
                      ),
                    ),
                    TextFormField(
                      controller: reportBody,
                      maxLines: 15,
                      validator: (String? text) {
                        if (text!.isEmpty) {
                          return "Empty description";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: "Description",
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        icon: Icon(Icons.email),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              ValueListenableBuilder(
                  valueListenable: reportLoading,
                  builder: (context, _, __) {
                    return reportLoading.value
                        ? const SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator())
                        : ElevatedButton(
                            child: const Text(
                              "Report",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              // Report issues or suggestions from app users
                              await _report(context);
                              // your code
                            });
                  })
            ],
          );
        });
  }

  Future<void> _report(BuildContext context) async {
    bool isValid = reportFormKey.currentState!.validate();
    if (isValid) {
      reportLoading.value = true;
      bool sended = await GhReporterDelegate.report(
          //TODO: manage new labels
          labels: ["from user"],
          assignees: [dotenv.env['owner']!],
          title: reportTitle.text,
          body: reportBody.text);
      reportLoading.value = false;
      if (sended) {
        Navigator.of(context).pop();
      } else {
        const snackBar = SnackBar(
          content: Text("Somthing wrong, try later"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }
}

class Screen extends StatelessWidget {
  const Screen(this.wrong, {super.key});
  final dynamic wrong;
  @override
  Widget build(BuildContext context) {
    return Center(
      // ignore: prefer_interpolation_to_compose_strings
      child: Text("Hello" + wrong),
    );
  }
}
