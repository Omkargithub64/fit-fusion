import 'package:fitfusion/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glowy_borders/glowy_borders.dart';

class Uploadfeed extends StatefulWidget {
  const Uploadfeed({super.key});

  @override
  State<Uploadfeed> createState() => _UploadfeedState();
}

class _UploadfeedState extends State<Uploadfeed> {
  File? _image;
  final picker = ImagePicker();
  bool isLoading = false;

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadimage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var sessionCookie = prefs.getString('session');
    var request = http.MultipartRequest(
        'POST', Uri.parse('${ConfigUrl.baseUrl}/upload_public_image'));
    request.headers['cookie'] = sessionCookie ?? '';

    if (_image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image', _image!.path));
    }

    setState(() {
      isLoading = true;
    });

    try {
      var response = await request.send();
      setState(() {
        isLoading = false;
      });
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image Uploaded Successfully')));
        Navigator.pushNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to Upload Image')));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Upload Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Image")),
      body: Center(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _image == null
                    ? const Text('No image selected.')
                    : Image.file(
                        _image!,
                        height: 500,
                      ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      isLoading ? null : pickImage, // Disable when loading
                  child: const Text("Select Image"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isLoading || _image == null
                      ? null
                      : uploadimage, // Disable when loading or no image
                  child: const Text("Upload Image"),
                ),
              ],
            ),
            if (isLoading) ...[
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
      ),
    );
  }
}
