import 'package:animate_do/animate_do.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthmonitoring/components/vitalcard.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://healthmonitoring-21f90-default-rtdb.europe-west1.firebasedatabase.app/",
  );

  DatabaseReference? ref;
  bool isConnecting = true;
  bool isConnected = false;
  String? uid;
  String? userName;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('patient')
        .where('id', isEqualTo: uid)
        .get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        userName = snapshot.docs.first['name'];
      });
    }
  }

  void _setupNotifications() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token
    String? token = await _messaging.getToken();
    print('📲 FCM Token: $token');

    // Save token as part of a list in Firestore
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final snapshot = await userDoc.get();

    if (snapshot.exists) {
      List<dynamic> tokens = snapshot.data()?['fcmTokens'] ?? [];

      if (!tokens.contains(token)) {
        tokens.add(token);
        await userDoc.set({'fcmTokens': tokens}, SetOptions(merge: true));
        print('✅ Token added to fcmTokens array.');
      } else {
        print('ℹ️ Token already exists, skipping.');
      }
    } else {
      await userDoc.set({
        'fcmTokens': [token]
      });
      print('📥 Token list created for user.');
    }

    // Local notifications init
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  Future<String?> fetchESP32IP() async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          "https://healthmonitoring-21f90-default-rtdb.europe-west1.firebasedatabase.app/",
    );

    final dbRef = db.ref().child("Sensor/device_ip");

    print("⚙ Fetching ESP32 IP...");
    try {
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        print("📦 IP type: ${snapshot.value.runtimeType}");
        final ip = snapshot.value.toString();
        print("🔥 ESP32 IP: $ip");
        return ip;
      } else {
        print("🚫 No IP found in database");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching IP: $e");
      return null;
    }
  }

  Future<void> sendUIDToESP32(String uid, String ip) async {
    final uri = Uri.parse("http://$ip/setUID");
    print("================================$ip\\$uid\\$uri");
    try {
      final response = await http.post(uri,
          body: uid); //.timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        print("UID sent to ESP32");
      }
    } catch (e) {
      print("Error sending UID: $e");
    }
  }

  Future<void> setupConnection() async {
    uid = FirebaseAuth.instance.currentUser!.uid;
    final ip = await fetchESP32IP();
    print("==========================$ip");
    if (ip != null) {
      sendUIDToESP32(uid!, ip);
      setState(() {
        isConnected = true;
        isConnecting = false;
      });
    } else {
      setState(() {
        isConnecting = false;
        isConnected = false;
      });
    }

    ref = database.ref("Sensor/$uid");
    print("🔥 Firebase path = ${ref!.path}");
  }

  @override
  void initState() {
    super.initState();
    _setupNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupConnection();
      fetchUserName();
    });
    uid = FirebaseAuth.instance.currentUser!.uid;
  }

  Widget buildHealthBox({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.2),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.black87),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi ${userName ?? 'User'} 👋",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Here’s your latest health data",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isConnecting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!isConnected || ref == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 48),
            const SizedBox(height: 20),
            const Text(
              "Failed to connect to your device.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isConnecting
                    ? null
                    : () async {
                        setState(() {
                          isConnecting = true;
                        });

                        final ip = await fetchESP32IP();

                        if (ip != null) {
                          sendUIDToESP32(uid!, ip);
                          ref = database.ref("Sensor/$uid");
                          setState(() {
                            isConnected = true;
                            isConnecting = false;
                          });
                        } else {
                          setState(() {
                            isConnecting = false;
                            isConnected = false;
                          });

                          // 🔥 Show Snackbar if connection fails again
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "ESP32 connection failed. Please try again."),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: isConnecting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text("Retrying..."),
                        ],
                      )
                    : const Text("Retry Connection"),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: ref!.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text("No vitals data yet..."));
        }

        final data = snapshot.data!.snapshot.value as Map;

        final heartRate = double.tryParse(data['heart_rate_bpm'].toString())
                ?.toStringAsFixed(1) ??
            '--';

        final avgRate =
            double.tryParse(data['avg_bpm'].toString())?.toStringAsFixed(1) ??
                '--';

        final temp = double.tryParse(data['temperature_c'].toString())
                ?.toStringAsFixed(1) ??
            '--';

        final oxygen =
            double.tryParse(data['spo2'].toString())?.toStringAsFixed(1) ??
                '--';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildTopBar(),
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: VitalCard(
                  value: heartRate,
                  label: "Heart Rate",
                  icon: Icons.favorite,
                  color: Colors.red,
                  iconBuilder: (icon) => Pulse(
                    infinite: true,
                    duration: const Duration(seconds: 1),
                    child: Icon(icon, size: 36, color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 900),
                      child: VitalCard(
                        value: avgRate,
                        label: "Average BPM",
                        icon: Icons.show_chart,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 900),
                      child: VitalCard(
                        value: temp,
                        label: "Temperature",
                        icon: Icons.thermostat,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FadeInUp(
                duration: const Duration(milliseconds: 1100),
                child: VitalCard(
                  value: oxygen,
                  label: "Oxygen",
                  icon: Icons.water_drop,
                  color: Colors.green,
                ),
              ),
              Container(
                height: 20,
              ),
              FadeInUp(
                duration: const Duration(milliseconds: 1100),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setupConnection();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 28, 44, 69),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      "Connect",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
