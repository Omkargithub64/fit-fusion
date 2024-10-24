import 'dart:convert';
import 'package:fitfusion/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> topUsers = [];
  int? currentUserRank;
  int currentUserLikes = 0;

  // Fetch leaderboard data from API
  Future<void> fetchLeaderboardData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionCookie = prefs.getString('session');

      final response = await http.get(
        Uri.parse('${ConfigUrl.baseUrl}/get_leaderbord'),
        headers: {
          'cookie': sessionCookie ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          topUsers = data['top_users'];
          currentUserRank = data['current_user_rank'];
          currentUserLikes = data['current_user_total_likes'];
        });
      } else {
        throw Exception('Failed to load leaderboard');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLeaderboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 218, 218, 236),
      body: topUsers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                children: [
                  // Display current user's rank and likes
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                          255, 255, 255, 255), // Light background card
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 213, 195, 255)
                              .withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Your Rank',
                          style: TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 123, 115, 238),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentUserRank != null ? '#$currentUserRank' : 'N/A',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(
                                255, 124, 126, 235), // Accent purple color
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total Likes: $currentUserLikes',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 148, 124, 255),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Leaderboard List
                  Expanded(
                    child: ListView.builder(
                      itemCount: topUsers.length,
                      itemBuilder: (context, index) {
                        final user = topUsers[index];
                        return Card(
                          color: Colors.white,
                          elevation: 5,
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          shadowColor: const Color.fromARGB(255, 151, 93, 245)
                              .withOpacity(0.15),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color.fromARGB(255, 124, 126, 235),
                              radius: 28,
                              child: Text(
                                user['rank'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user['username'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Color.fromARGB(255, 124, 126, 235),
                              ),
                            ),
                            trailing: Text(
                              '${user['total_likes']} likes',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 124, 126, 235),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
