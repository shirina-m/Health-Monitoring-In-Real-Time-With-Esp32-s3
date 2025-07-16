import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:healthmonitoring/components/add.dart';
import 'package:healthmonitoring/dashboard.dart';
//import 'package:healthmonitoring/design.dart';
//import 'package:healthmonitoring/homepage.dart';
import 'package:healthmonitoring/hometab.dart';
import 'package:healthmonitoring/login.dart';
import 'package:healthmonitoring/patientstab.dart';
import 'package:healthmonitoring/profiletab.dart';
import 'package:healthmonitoring/signup.dart';
//import 'package:healthmonitoring/users.dart';
import 'package:timezone/data/latest.dart' as tz;

// 1️⃣ Global notifier for theme
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android);
  await flutterLocalNotificationsPlugin.initialize(settings);
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

/// 🔍 Decide the first screen to show
Future<Widget> determineStartScreen() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      await user.reload(); // 🔁 Refresh from Firebase
      final freshUser = FirebaseAuth.instance.currentUser;
      if (freshUser == null) return const Login();
      return const Dashboard();
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      return const Login();
    }
  } else {
    return const Login();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color _primaryGreen = Color(0xFF25D366);
  static const Color _darkAccent = Color.fromARGB(255, 28, 44, 69);
  static const Color _white = Colors.white;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,

          theme: ThemeData(
            primaryColor: _primaryGreen,
            scaffoldBackgroundColor: const Color.fromARGB(255, 235, 234, 234),
            colorScheme: const ColorScheme.light(
              primary: _primaryGreen,
              secondary: _darkAccent,
              surface: _white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: _darkAccent,
              titleTextStyle: TextStyle(
                color: _white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              iconTheme: IconThemeData(color: _white),
              elevation: 2,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: _primaryGreen,
              foregroundColor: _white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: _white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: _darkAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: _primaryGreen, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black87),
              titleLarge:
                  TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            cardTheme: CardThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),

          darkTheme: ThemeData.dark().copyWith(
            primaryColor: _primaryGreen,
            scaffoldBackgroundColor: Colors.grey.shade900,
            colorScheme: const ColorScheme.dark(
              primary: _primaryGreen,
              secondary: _darkAccent,
              surface: Color.fromARGB(255, 28, 44, 69),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: _darkAccent,
              titleTextStyle: TextStyle(
                color: _white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              iconTheme: IconThemeData(color: _white),
              elevation: 2,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: _primaryGreen,
              foregroundColor: _white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: _white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: _white),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: _primaryGreen, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintStyle: TextStyle(color: Colors.grey.shade300),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.grey.shade200),
              titleLarge: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            cardTheme: CardThemeData(
              color: Colors.grey.shade800,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),

          /// ✅ Use FutureBuilder to determine correct starting page
          home: FutureBuilder<Widget>(
            future: determineStartScreen(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                return snapshot.data!;
              }
            },
          ),

          routes: {
            'signup': (context) => const Signup(),
            'login': (context) => const Login(),
            //'homepage': (context) => const Homepage(),
            'addfile': (context) => const AddFile(),
            //'userfilter': (context) => const UsersFilter(),
           // 'design': (context) => const Design(),
            'hometab': (context) => const HomeTab(),
            'patientstab': (context) => const PatientsTab(),
            'profiletab': (context) => const ProfileTab(),
            'dashboard': (context) => const Dashboard(),
          },
        );
      },
    );
  }
}
