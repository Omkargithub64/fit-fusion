import 'package:fitfusion/config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for text fields
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Function to handle login
  Future<void> login() async {
    var url = Uri.parse('${ConfigUrl.baseUrl}/login');
    var response = await http.post(
      url,
      body: json.encode({
        'username': usernameController.text,
        'password': passwordController.text,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      if (response.headers.containsKey('set-cookie')) {
        var sessionCookie = response.headers['set-cookie'];
        if (sessionCookie != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('session', sessionCookie);
        }
      }

      Navigator.pushNamed(context, '/home');
    } else {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Login Failed'),
          content: Text('Please check your credentials and try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo or icon
                  const Icon(
                    Icons.lock_open,
                    size: 80,
                    color: Color.fromARGB(255, 124, 126, 235),
                  ),
                  const SizedBox(height: 50),

                  // Welcome message
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Login to your account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Username TextField
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      hintText: 'Email / Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password TextField
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Login Button with Gradient Effect
                  ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets
                          .zero, // Important for making gradient fill the button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 124, 126, 235),
                            Color.fromARGB(255, 82, 147, 236),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 300,
                          minHeight: 50,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign-up prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Color(0xFF7A7A7A)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color.fromARGB(255, 124, 126, 235),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
