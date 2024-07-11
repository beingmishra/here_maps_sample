import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_storage/get_storage.dart';
import 'package:here_maps_sample/screens/home_screen.dart';
import 'package:here_maps_sample/utils/general_functions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final box = GetStorage();

  Future<List<dynamic>> _loadUserData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/user_data.json');
      print(jsonString);
      return json.decode(jsonString);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  void _login() async {
    final userDataArr = await _loadUserData();
    if (userDataArr.isEmpty) {
      showSnackBar(context, 'Error loading user data', false);
      return;
    }

    final email = emailController.text;
    final password = passwordController.text;

    if(email.isEmpty){
      showSnackBar(context, 'Invalid email', false);
      return;
    }

    if(password.isEmpty){
      showSnackBar(context, 'Invalid password', false);
      return;
    }

    var isSuccess = false;

    for (var userData in userDataArr) {
      if (userData['email'] == email && userData['password'] == password) {
        isSuccess = true;
        break;
      }
    }

    if(isSuccess){
      box.write("login", true);
      Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      showSnackBar(context, 'Login successful!', true);
    }else{
      showSnackBar(context, 'Invalid email or password.', false);
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 16,
              ),
              const Text("Welcome back !", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),),
              const SizedBox(
                height: 8,
              ),
              const Text("Enter your credentials below to continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),),
              const SizedBox(
                height: 46,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(100)
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter email"
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(100)
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter password"
                  ),
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(42)
                  ),
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}