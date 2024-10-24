import 'package:fitfusion/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Wardrobe extends StatefulWidget {
  const Wardrobe({super.key});

  @override
  State<Wardrobe> createState() => _WardrobeState();
}

class _WardrobeState extends State<Wardrobe> {
  List<String> tops = [];
  List<String> bottoms = [];
  List<String> shoes = [];
  List<String> bodyImage = [];

  Future<void> fetchClothes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');

    var url = Uri.parse('${ConfigUrl.baseUrl}/get_clothes');
    var response = await http.get(
      url,
      headers: {
        'cookie': sessionCookie ?? '',
      },
    );
    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      setState(() {
        tops = _extractImageList(data['top']);
        bottoms = _extractImageList(data['bottom']);
        shoes = _extractImageList(data['shoes']);
        bodyImage = _extractImageList(data['body_image']);
      });
    } else {
      print('Failed to fetch clothes: ${response.statusCode}');
    }
  }

  Future<void> deleteCloth(String category, String imageUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');

    var url = Uri.parse('${ConfigUrl.baseUrl}/delete_cloth');
    var response = await http.post(
      url,
      headers: {
        'cookie': sessionCookie ?? '',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'category': category,
        'image_url': imageUrl,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        if (category == 'top') {
          tops.remove(imageUrl);
        } else if (category == 'bottom') {
          bottoms.remove(imageUrl);
        } else if (category == 'shoes') {
          shoes.remove(imageUrl);
        }
      });
    } else {
      print('Failed to delete cloth: ${response.statusCode}');
    }
  }

  List<String> _extractImageList(dynamic data) {
    if (data is List) {
      return List<String>.from(data);
    } else if (data is String) {
      return [data];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    fetchClothes();
  }

  Widget buildCategory(String title, List<String> images, String category) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C7EEB))),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:
                          Image.network(images[index], height: 100, width: 100),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        icon:
                            const Icon(Icons.cancel, color: Color(0xFF99072B)),
                        onPressed: () async {
                          bool? confirmDelete = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Item"),
                              content: const Text(
                                  "Are you sure you want to delete this item?"),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel")),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Delete")),
                              ],
                            ),
                          );

                          if (confirmDelete == true) {
                            deleteCloth(category, images[index]);
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  ElevatedButton buildStyledButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7C7EEB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Center(
                child: bodyImage.isNotEmpty
                    ? Image.network(
                        bodyImage[0],
                        height: 300,
                        width: 200,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        "https://res.cloudinary.com/dfr9yu2mi/image/upload/v1729089091/vmozo9o0fvfs6ao31dwm.png",
                        height: 300,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 20),
              buildStyledButton("Upload Body Image", () {
                Navigator.pushNamed(context, '/bodypicupload');
              }),
              const SizedBox(height: 20),
              buildCategory('Tops', tops, 'top'),
              const SizedBox(height: 20),
              buildCategory('Bottoms', bottoms, 'bottom'),
              const SizedBox(height: 20),
              buildCategory('Shoes', shoes, 'shoes'),
              const SizedBox(height: 20),
              buildStyledButton("Upload Clothes", () {
                Navigator.pushNamed(context, '/upload');
              }),
            ],
          ),
        ),
      ),
    );
  }
}
