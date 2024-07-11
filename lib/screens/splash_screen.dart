import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:here_maps_sample/screens/home_screen.dart';
import 'package:here_maps_sample/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  final box = GetStorage();

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if(box.hasData('login')){
        Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }else{
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset("assets/images/bw_logo.jpg"),
      ),
    );
  }
}
