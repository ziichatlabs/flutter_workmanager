import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

// Only keeping the task keys needed for OneOffTask
const simpleTaskKey = "be.tramckrijte.workmanagerExample.simpleTask";
const simpleDelayedTask = "be.tramckrijte.workmanagerExample.simpleDelayedTask";

const List<String> oneOffTasks = [
  simpleTaskKey,
  simpleDelayedTask,
];

// Pragma is mandatory if the App is obfuscated or using Flutter 3.1+
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    print("$task started. inputData = $inputData");
    await prefs.setString(task, 'Last ran at: ${DateTime.now()}');

    switch (task) {
      case simpleTaskKey:
        await prefs.setBool("test", true);
        print("Bool from prefs: ${prefs.getBool("test")}");
        return true;
      case simpleDelayedTask:
        print("$simpleDelayedTask was executed");
        return true;
      default:
        return false;
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool workmanagerInitialized = false;
  String _prefsString = "empty";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OneOffTask Example"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                "Plugin initialization",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton(
                onPressed: _initializeWorkmanager,
                child: const Text("Start the Flutter background service"),
              ),
              const SizedBox(height: 8),
              Text(
                "Register OneOffTask",
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              // Simple OneOffTask
              ElevatedButton(
                onPressed: _registerSimpleOneOffTask,
                child: const Text("Register OneOff Task"),
              ),

              // Delayed OneOffTask
              ElevatedButton(
                onPressed: _registerDelayedOneOffTask,
                child: const Text("Register Delayed OneOff Task"),
              ),

              const SizedBox(height: 8),
              Text(
                "Task cancellation",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton(
                onPressed: _cancelAllTasks,
                child: const Text("Cancel All"),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _refreshStats,
                child: const Text('Refresh stats'),
              ),
              const SizedBox(height: 10),
              Text(
                'Task run stats:\n'
                '${workmanagerInitialized ? '' : 'Workmanager not initialized'}'
                '\n$_prefsString',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeWorkmanager() async {
    if (Platform.isIOS) {
      final status = await Permission.backgroundRefresh.status;
      if (status != PermissionStatus.granted) {
        _showNoPermission(context, status);
        return;
      }
    }

    if (workmanagerInitialized) return;

    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
    setState(() => workmanagerInitialized = true);
  }

  void _registerSimpleOneOffTask() {
    Workmanager().registerOneOffTask(
      simpleTaskKey,
      simpleTaskKey,
      inputData: <String, dynamic>{
        'int': 1,
        'bool': true,
        'double': 1.0,
        'string': 'string',
        'array': [1, 2, 3],
      },
    );
  }

  void _registerDelayedOneOffTask() {
    Workmanager().registerOneOffTask(
      simpleDelayedTask,
      simpleDelayedTask,
      initialDelay: const Duration(seconds: 10),
    );
  }

  Future<void> _cancelAllTasks() async {
    await Workmanager().cancelAll();
    print('Cancel all tasks completed');
  }

  // Refresh/get saved prefs
  Future<void> _refreshStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final buffer = StringBuffer();
    for (final task in oneOffTasks) {
      buffer.write('\n$task:\n${prefs.getString(task)}\n');
    }

    _prefsString = buffer.toString();

    if (Platform.isIOS) {
      Workmanager().printScheduledTasks();
    }

    setState(() {});
  }

  void _showNoPermission(BuildContext context, PermissionStatus hasPermission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No permission'),
          content: Text(
            'Background app refresh is disabled, please enable in '
            'App settings. Status ${hasPermission.name}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
