import 'package:fitfusion/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting

class ScheduleOutfitScreen extends StatefulWidget {
  const ScheduleOutfitScreen({super.key});

  @override
  _ScheduleOutfitScreenState createState() => _ScheduleOutfitScreenState();
}

class _ScheduleOutfitScreenState extends State<ScheduleOutfitScreen> {
  List<dynamic> savedOutfits = []; // Holds fetched saved outfits
  DateTime? selectedDate;
  int? selectedOutfitId;

  @override
  void initState() {
    super.initState();
    fetchSavedOutfits(); // Fetch outfits when the screen is initialized
  }

  Future<void> fetchSavedOutfits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');

    var response = await http.get(
      Uri.parse(
          '${ConfigUrl.baseUrl}/get_saved_outfits'), // Replace with your Flask API URL
      headers: {
        'cookie': sessionCookie ?? '',
      },
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        savedOutfits = data; // Set the fetched outfits to your state
      });
    } else {
      print('Failed to fetch saved outfits: ${response.statusCode}');
      // You can also show a snackbar or dialog to inform the user of the error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Outfit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Outfit:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: savedOutfits.length,
                itemBuilder: (context, index) {
                  var outfit = savedOutfits[index];
                  return Card(
                    child: ListTile(
                      title: Text('Outfit ${index + 1}'),
                      subtitle: Text('Created at: ${outfit['created_at']}'),
                      onTap: () {
                        setState(() {
                          selectedOutfitId = outfit[
                              'id']; // Assuming 'id' is the outfit identifier
                        });
                      },
                      tileColor: selectedOutfitId == outfit['id']
                          ? Colors.lightBlue[100]
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectDate,
              child: const Text('Select Date'),
            ),
            const SizedBox(height: 20),
            selectedDate != null
                ? Text(
                    'Selected Date: ${DateFormat.yMd().format(selectedDate!)}',
                    style: const TextStyle(fontSize: 16),
                  )
                : const Text(
                    'No Date Selected',
                    style: TextStyle(fontSize: 16),
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scheduleOutfit,
              child: const Text('Schedule Outfit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _scheduleOutfit() async {
    if (selectedOutfitId == null || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an outfit and a date.')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');
    int? userId = prefs.getInt('user_id');

    try {
      final response = await http.post(
        Uri.parse(
            '${ConfigUrl.baseUrl}/schedule_outfit'), // Replace with your Flask API URL
        headers: {
          'Content-Type': 'application/json',
          'cookie': sessionCookie ?? '',
        },
        body: jsonEncode({
          'outfit_id': selectedOutfitId,
          'schedule_date': selectedDate!.toIso8601String(),
          'user_id': userId, // Pass user ID
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit scheduled successfully')),
        );
      } else {
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to schedule outfit: ${response.body}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling outfit: $error')),
      );
    }
  }
}
