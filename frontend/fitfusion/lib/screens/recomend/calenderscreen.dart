import 'package:fitfusion/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScheduledOutfitScreen extends StatefulWidget {
  const ScheduledOutfitScreen({super.key});

  @override
  _ScheduledOutfitScreenState createState() => _ScheduledOutfitScreenState();
}

class _ScheduledOutfitScreenState extends State<ScheduledOutfitScreen> {
  List<dynamic> _scheduledOutfits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchScheduledOutfits(); // Load scheduled outfits on startup
  }

// Fetch the scheduled outfits from the backend
  Future<void> _fetchScheduledOutfits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionCookie = prefs.getString('session');

    // Set the desired schedule date (modify as per your requirement)
    String scheduleDate = '2024-10-19'; // For example

    final response = await http.get(
      Uri.parse(
        '${ConfigUrl.baseUrl}/scheduled_outfits?schedule_date=$scheduleDate', // Include the schedule_date parameter
      ),
      headers: {
        'cookie': sessionCookie ?? '' // If using token-based auth
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _scheduledOutfits = jsonDecode(response.body);
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch scheduled outfits')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Outfits'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scheduledOutfits.isEmpty
              ? const Center(child: Text('No scheduled outfits found.'))
              : ListView.builder(
                  itemCount: _scheduledOutfits.length,
                  itemBuilder: (context, index) {
                    final outfit = _scheduledOutfits[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            'Outfit ID: ${outfit['outfit_id']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(
                            'Scheduled Date: ${outfit['schedule_date']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          leading: const Icon(Icons.checkroom, size: 40),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
