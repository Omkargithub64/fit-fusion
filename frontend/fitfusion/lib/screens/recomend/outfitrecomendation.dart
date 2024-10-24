import 'package:fitfusion/config.dart';
import 'package:flutter/material.dart';
import 'package:glowy_borders/glowy_borders.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecommendOutfit extends StatefulWidget {
  const RecommendOutfit({super.key});

  @override
  State<RecommendOutfit> createState() => _RecommendOutfitState();
}

class _RecommendOutfitState extends State<RecommendOutfit> {
  List<String> tops = [];
  List<String> bottoms = [];
  List<String> shoes = [];
  List<String> bodyImage = [];

  String? selectedTop;
  String? selectedBottom;
  String? selectedShoes;

  List<Map<String, dynamic>> bestCombinations = [];
  bool isLoading = false;

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

  Future<void> recommendOutfit(String category) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');
    String? selectedImageUrl;

    if (category == 'top') {
      selectedImageUrl = selectedTop;
    } else if (category == 'bottom') {
      selectedImageUrl = selectedBottom;
    } else if (category == 'shoes') {
      selectedImageUrl = selectedShoes;
    }

    if (selectedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an image from the selected category')),
      );
      return;
    }

    setState(() {
      isLoading = true; // Start loading indicator
    });

    var url = Uri.parse('${ConfigUrl.baseUrl}/recommend');
    var response = await http.post(
      url,
      headers: {
        'cookie': sessionCookie ?? '',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'category': category,
        'image_url': selectedImageUrl,
      }),
    );

    setState(() {
      isLoading = false; // Stop loading indicator
    });

    if (response.statusCode == 200) {
      var recommendations = json.decode(response.body);

      setState(() {
        bestCombinations = List<Map<String, dynamic>>.from(
            recommendations['best_combinations']);
      });
    } else {
      print('Failed to recommend outfit: ${response.statusCode}');
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
                  color: Color.fromARGB(255, 124, 126, 235))),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                bool isSelected = (category == 'top' &&
                        images[index] == selectedTop) ||
                    (category == 'bottom' && images[index] == selectedBottom) ||
                    (category == 'shoes' && images[index] == selectedShoes);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (category == 'top') {
                        selectedTop = (selectedTop == images[index])
                            ? null
                            : images[index];
                      } else if (category == 'bottom') {
                        selectedBottom = (selectedBottom == images[index])
                            ? null
                            : images[index];
                      } else if (category == 'shoes') {
                        selectedShoes = (selectedShoes == images[index])
                            ? null
                            : images[index];
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? const Color.fromARGB(255, 124, 126, 235)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Image.network(images[index],
                            height: 100, width: 100),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => recommendOutfit(category),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 124, 126, 235),
            ),
            child: Text('Recommend based on $title',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget buildRecommendations() {
    if (bestCombinations.isEmpty) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Recommended Outfits',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 124, 126, 235),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: bestCombinations.length,
            itemBuilder: (context, index) {
              var outfit = bestCombinations[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(255, 124, 126, 235),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      outfit['top_image_url'],
                      height: 80,
                      width: 80,
                    ),
                    const SizedBox(height: 8),
                    Image.network(
                      outfit['bottom_image_url'],
                      height: 80,
                      width: 80,
                    ),
                    const SizedBox(height: 8),
                    Image.network(
                      outfit['shoes_image_url'],
                      height: 40,
                      width: 40,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 124, 126, 235),
        foregroundColor: Colors.white,
        title: const Text('Recommend Outfit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              ListView(
                children: [
                  const SizedBox(height: 20),
                  buildCategory('Tops', tops, 'top'),
                  buildCategory('Bottoms', bottoms, 'bottom'),
                  buildCategory('Shoes', shoes, 'shoes'),
                  buildRecommendations(),
                  const SizedBox(height: 20),
                ],
              ),
              if (isLoading) ...[
                const ModalBarrier(
                  color: Colors.black54,
                  dismissible: false,
                ),
                // Animated gradient border during upload
                const Center(
                  child: AnimatedGradientBorder(
                    borderSize: 2,
                    glowSize: 10,
                    gradientColors: [
                      Color.fromARGB(206, 250, 36, 107),
                      Color.fromARGB(225, 172, 56, 240),
                      Color.fromARGB(251, 113, 127, 250),
                      Color.fromARGB(255, 100, 255, 242),
                    ],
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    child: SizedBox(
                      width: double.infinity,
                      height: 2,
                      child: Center(), // Spinner inside the glowing border
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
