import 'package:fitfusion/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> updateProfile(String username, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');
    final response = await http.put(
      Uri.parse('${ConfigUrl.baseUrl}/edit_profile'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'cookie': sessionCookie ?? ''
      },
      body: jsonEncode(
        <String, String>{
          'username': username,
          'password': password,
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Profile updated: ${data['message']}');
      Navigator.pushNamed(context, '/profile');
    } else {
      print('Failed to update profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'New Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final username = _usernameController.text;
                final password = _passwordController.text;
                updateProfile(username, password);
              },
              child: const Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
