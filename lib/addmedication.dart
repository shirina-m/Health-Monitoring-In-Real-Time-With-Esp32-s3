import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:healthmonitoring/components/textformfield.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AddMedication extends StatefulWidget {
  const AddMedication({super.key});

  @override
  State<AddMedication> createState() => _AddMedicationState();
}

class _AddMedicationState extends State<AddMedication> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  int timesPerDay = 1;
  bool isSaving = false;
  List<TimeOfDay> selectedTimes = [];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); // ✅ important for scheduling
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              dayPeriodTextColor:
                  Colors.black, // <-- changes AM/PM selected color
              dayPeriodColor:
                  Color(0xFF25D366), // optional: selected bg color
              hourMinuteTextColor: Colors.black,
              dialTextColor: Colors.black,
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF25D366), // picker primary color (dial, etc.)
              onPrimary: Colors.white, // text color on primary bg
              onSurface: Colors.black, // text color for dial numbers
            ),
          ),
          child: child!,
        );
      },
    );
    await Future.delayed(const Duration(milliseconds: 100));
    FocusScope.of(context).unfocus();
    if (picked != null) {
      setState(() => selectedTimes.add(picked));
    }
  }

  void scheduleNotifications(String pillName) {
    for (var time in selectedTimes) {
      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final scheduledTime = _nextInstanceOfTime(time);

      flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Time to take $pillName',
        'Tap to log your dose or check details.',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pill_channel',
            'Pill Reminders',
            channelDescription: 'Daily pill reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle, // ✅ required now
        matchDateTimeComponents: DateTimeComponents.time, // ✅ still used
      );
      print("Scheduling $pillName at $scheduledTime (${time.format(context)})");
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found")),
      );
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('patient')
        .where('id', isEqualTo: uid)
        .get();

    if (snapshot.docs.isEmpty) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Patient record not found")),
      );
      return;
    }

    final patientDocId = snapshot.docs.first.id;

    await FirebaseFirestore.instance
        .collection('patient')
        .doc(patientDocId)
        .collection('pills')
        .add({
      'name': nameController.text.trim(),
      'frequency': '$timesPerDay times/day',
      'times': selectedTimes
          .map((t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    scheduleNotifications(nameController.text.trim());

    if (mounted) {
      setState(() => isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medication added successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          appBar: AppBar(
            title: const Text("Add Medication"),
            backgroundColor: const Color.fromARGB(255, 28, 44, 69),
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CostumeFormField(
                      hintText: "Medication name",
                      myController: nameController,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? "Enter a name"
                          : null,
                    ),
                    const SizedBox(height: 24),
                    const Text("How many times per day?"),
                    SizedBox(
                      height: 150,
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                            initialItem: timesPerDay - 1),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            timesPerDay = index + 1;
                          });
                        },
                        children: List.generate(10, (index) {
                          return Center(
                            child: Text(
                              "${index + 1} times",
                              style: const TextStyle(fontSize: 18),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: pickTime,
                        icon: const Icon(Icons.alarm),
                        label: const Text("Add Reminder Time"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...selectedTimes.map((time) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text("• ${time.format(context)}"),
                        )),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveMedication,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              const Color.fromARGB(255, 28, 44, 69),
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Save Medication",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
    );
  }
}
