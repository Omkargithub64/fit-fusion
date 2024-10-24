import 'package:fitfusion/screens/bodyimage.dart';
import 'package:fitfusion/screens/homepage.dart';
import 'package:fitfusion/screens/leaderboard.dart';
import 'package:fitfusion/screens/login.dart';
import 'package:fitfusion/screens/outfitgen.dart';
import 'package:fitfusion/screens/profile/profile.dart';
import 'package:fitfusion/screens/profile/saved.dart';
import 'package:fitfusion/screens/recomend/calenderscreen.dart';
import 'package:fitfusion/screens/recomend/outfitrecomendation.dart';
import 'package:fitfusion/screens/recomend/scheduleoutfit.dart';
import 'package:fitfusion/screens/signup.dart';
import 'package:fitfusion/screens/upload.dart';
import 'package:fitfusion/screens/uploadpost.dart';
import 'package:fitfusion/screens/wardrobe.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/upload': (context) => const Upload(),
        '/wardrobe': (context) => const Wardrobe(),
        '/outfitgen': (context) => const Outfitgen(),
        '/bodypicupload': (context) => const Bodyimage(),
        '/uploadfeed': (context) => const Uploadfeed(),
        '/leaderbord': (context) => const LeaderboardScreen(),
        '/profile': (context) => const UserImageScreen(),
        '/saved': (context) => const SavedOutfitsScreen(),
        '/recom': (context) => const RecommendOutfit(),
        '/schedule': (context) => const ScheduleOutfitScreen(),
        '/calender': (context) => const ScheduledOutfitScreen(),
      },
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
