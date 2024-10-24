import 'package:fitfusion/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedOutfitsScreen extends StatefulWidget {
  const SavedOutfitsScreen({super.key});

  @override
  _SavedOutfitsScreenState createState() => _SavedOutfitsScreenState();
}

class _SavedOutfitsScreenState extends State<SavedOutfitsScreen> {
  List<dynamic> savedOutfits = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSavedOutfits();
  }

  Future<void> _fetchSavedOutfits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');

    try {
      final response = await http.get(
        Uri.parse('${ConfigUrl.baseUrl}/get_saved_outfits'),
        headers: {
          'cookie': sessionCookie ?? '',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          savedOutfits = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load outfits';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _removeSavedOutfit(int outfitId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');

    try {
      final response = await http.delete(
        Uri.parse('${ConfigUrl.baseUrl}/delete_saved_outfit/$outfitId'),
        headers: {
          'cookie': sessionCookie ?? '',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          savedOutfits.removeWhere((outfit) => outfit['id'] == outfitId);
        });
        print('Outfit removed successfully');
      } else {
        print('Failed to remove outfit: ${response.body}');
      }
    } catch (error) {
      print('Error removing outfit: $error');
    }
  }

  void _confirmDeleteOutfit(int outfitId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Outfit'),
        content: const Text('Are you sure you want to delete this outfit?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _removeSavedOutfit(outfitId);
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Outfits'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : savedOutfits.isEmpty
                  ? const Center(child: Text('No saved outfits found.'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: savedOutfits.length,
                              itemBuilder: (context, index) {
                                var outfit = savedOutfits[index];
                                return Card(
                                  elevation: 4,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'Outfit ${index + 1}',
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    onPressed: () {
                                                      _confirmDeleteOutfit(
                                                          outfit['id']);
                                                    },
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                'Created at: ${outfit['created_at']}',
                                                style: const TextStyle(
                                                    color: Colors.grey),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Image.network(
                                                    outfit['top'],
                                                    height: 100,
                                                    width: 100,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  Image.network(
                                                    outfit['bottom'],
                                                    height: 100,
                                                    width: 100,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  Image.network(
                                                    outfit['shoes'],
                                                    height: 100,
                                                    width: 100,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/schedule');
                            },
                            child: const Text('Schedule Outfit'),
                          ),
                        ],
                      ),
                    ),
    );
  }
}