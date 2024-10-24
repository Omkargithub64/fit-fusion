import 'package:fitfusion/config.dart';
import 'package:flutter/material.dart';
import 'package:glowy_borders/glowy_borders.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  File? _topImage;
  File? _bottomImage;
  File? _shoesImage;
  final picker = ImagePicker();
  bool _isUploading = false;

  Future<void> pickImage(String type) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        if (type == 'top') {
          _topImage = File(pickedFile.path);
        } else if (type == 'bottom') {
          _bottomImage = File(pickedFile.path);
        } else if (type == 'shoes') {
          _shoesImage = File(pickedFile.path);
        }
      }
    });
  }

  Future<void> uploadClothes() async {
    setState(() {
      _isUploading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var sessionCookie = prefs.getString('session');

    var request =
        http.MultipartRequest('POST', Uri.parse('${ConfigUrl.baseUrl}/upload'));

    request.headers['cookie'] = sessionCookie ?? '';

    if (_topImage != null) {
      request.files
          .add(await http.MultipartFile.fromPath('top', _topImage!.path));
    }
    if (_bottomImage != null) {
      request.files
          .add(await http.MultipartFile.fromPath('bottom', _bottomImage!.path));
    }
    if (_shoesImage != null) {
      request.files
          .add(await http.MultipartFile.fromPath('shoes', _shoesImage!.path));
    }

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        print('Uploaded Successfully');
        Navigator.pushNamed(context, '/home');
      } else {
        var responseBody = await response.stream.bytesToString();
        print('Upload Failed: $responseBody');
      }
    } catch (e) {
      print('Upload Error: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Clothes')),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 176, 177, 247),
                  ),
                  onPressed: () => pickImage('top'),
                  child: const Text(
                    'Pick Top Image',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 176, 177, 247),
                  ),
                  onPressed: () => pickImage('bottom'),
                  child: const Text(
                    'Pick Bottom Image',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 176, 177, 247),
                  ),
                  onPressed: () => pickImage('shoes'),
                  child: const Text(
                    'Pick Shoes Image',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 124, 126, 235),
                  ),
                  onPressed: uploadClothes,
                  child: const Text(
                    'Upload Clothes',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isUploading) ...[
            // ModalBarrier to block interactions
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
