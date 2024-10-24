import 'dart:convert';
import 'package:fitfusion/config.dart';
import 'package:fitfusion/screens/profile/editprofile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserImageScreen extends StatefulWidget {
  const UserImageScreen({super.key});

  @override
  _UserImageScreenState createState() => _UserImageScreenState();
}

class _UserImageScreenState extends State<UserImageScreen> {
  List<dynamic> userImages = [];
  String userName = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchUserImages();
  }

  Future<void> fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var sessionCookie = prefs.getString('session');

    final response = await http.get(
      Uri.parse('${ConfigUrl.baseUrl}/profile'),
      headers: {
        'cookie': sessionCookie ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userName = data['username'];
      });
    } else {
      print('Failed to load user data');
    }
  }

  Future<void> fetchUserImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var sessionCookie = prefs.getString('session');

    final response = await http.get(
      Uri.parse('${ConfigUrl.baseUrl}/profile'),
      headers: {
        'cookie': sessionCookie ?? '',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        userImages = json.decode(response.body)['uploads'];
      });
    } else {
      print('Failed to load images: ${response.body}');
    }
  }

  Future<void> deletePost(int postId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var sessionCookie = prefs.getString('session');
    final response = await http.delete(
      Uri.parse('${ConfigUrl.baseUrl}/delete_post'),
      headers: {
        'cookie': sessionCookie ?? '',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'post_id': postId}),
    );

    if (response.statusCode == 200) {
      fetchUserImages();
    } else {
      print('Failed to delete post: ${response.body}');
    }
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('session');
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                        'https://via.placeholder.com/150'), // Placeholder image
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EditProfileScreen()));
                    },
                    child: const Text('Edit Profile'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/saved');
                    },
                    child: const Text('Saved'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/calender');
                    },
                    child: const Text('Scheduled'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Instagram-like grid with 3 images per row
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
                childAspectRatio: 1,
              ),
              itemCount: userImages.length,
              itemBuilder: (context, index) {
                final image = userImages[index];
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Center(
                                  child: Image.network(
                                    image['url'],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Image.network(
                        image['url'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Post'),
                              content: const Text(
                                  'Are you sure you want to delete this post?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    deletePost(image['id']);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            ElevatedButton(
              onPressed: logout,
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
