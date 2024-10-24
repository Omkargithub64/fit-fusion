import 'package:fitfusion/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Social extends StatefulWidget {
  const Social({super.key});

  @override
  State<Social> createState() => _SocialState();
}

class _SocialState extends State<Social> {
  List<dynamic> images = [];

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    final response =
        await http.get(Uri.parse('${ConfigUrl.baseUrl}/get_public_images'));

    if (response.statusCode == 200) {
      setState(() {
        images = json.decode(response.body)['images'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load images')),
      );
    }
  }

  Future<void> _likeImage(int imageId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var sessionCookie = prefs.getString('session');
    final response = await http.post(
      Uri.parse('${ConfigUrl.baseUrl}/like_image'),
      headers: {
        'cookie': sessionCookie ?? '',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'image_id': imageId}),
    );

    if (response.statusCode == 200) {
      _fetchImages();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to like image')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 124, 126, 235),
        onPressed: () {
          Navigator.pushNamed(context, '/uploadfeed');
        },
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
      body: images.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Card(
                    elevation: 5,
                    shadowColor: const Color.fromARGB(62, 0, 0, 0),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10)),
                          child: CachedNetworkImage(
                            imageUrl: image['image_url'],
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Center(child: Icon(Icons.error)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '${image['username']}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 104, 81, 233)),
                              onPressed: () {
                                _likeImage(image['image_id']);
                              },
                              child: const Text(
                                'Like',
                                style: TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255)),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'Likes: ${image['like_count']}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
