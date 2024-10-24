import 'dart:convert';
import 'package:fitfusion/config.dart';
import 'package:fitfusion/screens/tryons.dart';
import 'package:flutter/material.dart';
import 'package:glowy_borders/glowy_borders.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Outfitgen extends StatefulWidget {
  const Outfitgen({super.key});

  @override
  _OutfitgenState createState() => _OutfitgenState();
}

class _OutfitgenState extends State<Outfitgen> {
  String? topImageUrl;
  String? bottomImageUrl;
  String? shoesImageUrl;
  late String bodyImage;
  bool isLoading = false;

  Future<void> requestOutfitImages() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');

    var response = await http.get(
      Uri.parse('${ConfigUrl.baseUrl}/generate'),
      headers: {
        'cookie': sessionCookie ?? '',
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        topImageUrl = data['best_combinations'][0]['top_image_url'];
        bottomImageUrl = data['best_combinations'][0]['bottom_image_url'];
        shoesImageUrl = data['best_combinations'][0]['shoes_image_url'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('Failed to get outfit images: ${response.statusCode}');
    }
  }

  Future<void> getmodel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');

    var response = await http.get(
      Uri.parse('${ConfigUrl.baseUrl}/get_clothes'),
      headers: {
        'cookie': sessionCookie ?? '',
      },
    );
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        bodyImage = data['body_image'][0];
      });
    } else {
      print('Failed to fetch clothes: ${response.statusCode}');
    }
  }

  Future<void> saveOutfit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');

    if (topImageUrl == null ||
        bottomImageUrl == null ||
        shoesImageUrl == null) {
      print('Outfit image URLs are missing');
      return;
    }

    final response = await http.post(
      Uri.parse('${ConfigUrl.baseUrl}/save_outfit'),
      headers: {
        'Content-Type': 'application/json',
        'cookie': sessionCookie ?? ''
      },
      body: jsonEncode({
        'top': topImageUrl,
        'bottom': bottomImageUrl,
        'shoes': shoesImageUrl,
      }),
    );

    if (response.statusCode == 200) {
      print('Outfit saved successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit saved successfully')),
      );
    } else {
      print('Failed to save outfit: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save outfit')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getmodel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: AnimatedGradientBorder(
            borderSize: 2,
            glowSize: 10,
            gradientColors: const [
              Color.fromARGB(206, 250, 36, 107),
              Color.fromARGB(225, 172, 56, 240),
              Color.fromARGB(251, 113, 127, 250),
              Color.fromARGB(255, 100, 255, 242)
            ],
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            child: SizedBox(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 30,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (topImageUrl != null)
                            AspectRatio(
                              aspectRatio: 3 / 4,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Image.network(
                                  topImageUrl!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          if (bottomImageUrl != null)
                            AspectRatio(
                              aspectRatio: 3 / 4,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Image.network(
                                  bottomImageUrl!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          if (shoesImageUrl != null)
                            AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Image.network(
                                  shoesImageUrl!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: isLoading ? null : requestOutfitImages,
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Generate Outfit'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/recom');
                            },
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            child: const Text('Recommend Outfit'),
                          ),
                          if (topImageUrl != null &&
                              bottomImageUrl != null &&
                              shoesImageUrl != null)
                            Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Tryons(
                                                topImage: topImageUrl!,
                                                bottomImage: bottomImageUrl!,
                                                model: bodyImage,
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          textStyle:
                                              const TextStyle(fontSize: 16),
                                        ),
                                        child: const Text('Try This Outfit'),
                                      ),
                                      ElevatedButton(
                                        onPressed: saveOutfit,
                                        style: ElevatedButton.styleFrom(
                                          textStyle:
                                              const TextStyle(fontSize: 16),
                                        ),
                                        child: const Text('Save Outfit'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Add your text here
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'AI Outfit Generator',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
