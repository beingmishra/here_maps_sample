import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:here_maps_sample/environment.dart';
import 'package:here_maps_sample/screens/splash_screen.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeHERESDK();
  await GetStorage.init();
  runApp(const MyApp());
}

// method to init here sdk
void _initializeHERESDK() async {
  // Needs to be called before accessing SDKOptions to load necessary libraries.
  SdkContext.init(IsolateOrigin.main);
  SDKOptions sdkOptions = SDKOptions.withAccessKeySecret(Environment.accessKeyId, Environment.accessKeySecret);
  try {
    await SDKNativeEngine.makeSharedInstance(sdkOptions);
  } on InstantiationException {
    throw Exception("Failed to initialize the HERE SDK.");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Here maps example',
      theme: ThemeData(
        useMaterial3: false,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }

}
