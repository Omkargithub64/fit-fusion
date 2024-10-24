import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitfusion/config.dart';
import 'package:glowy_borders/glowy_borders.dart'; // Import the glowy borders package

class Bodyimage extends StatefulWidget {
  const Bodyimage({super.key});

  @override
  State<Bodyimage> createState() => _BodyimageState();
}

class _BodyimageState extends State<Bodyimage> {
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ConfigUrl.baseUrl}/upload_body_image'),
    );
    request.headers['cookie'] = sessionCookie ?? '';
    request.files.add(
      await http.MultipartFile.fromPath('body_image', _selectedImage!.path),
    );

    var response = await request.send();

    setState(() {
      _isUploading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
      Navigator.pushNamed(context, '/home');
    } else {
      print('Failed to upload image: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Body Image'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        height: 300,
                        width: 200,
                        fit: BoxFit.cover,
                      )
                    : const Placeholder(
                        fallbackHeight: 300,
                        fallbackWidth: 200,
                      ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Select & Upload Image from Gallery'),
                ),
              ],
            ),
          ),
          if (_isUploading) ...[
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
    );
  }
}
