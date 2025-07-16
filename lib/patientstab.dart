import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class PatientsTab extends StatefulWidget {
  const PatientsTab({super.key});

  @override
  State<PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends State<PatientsTab> {
  late FocusNode _searchFocusNode;
  bool isLoading = true;
  List<QueryDocumentSnapshot> linkedPatients = [];
  TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState(); // ← only once
    _searchFocusNode = FocusNode();
    loadLinkedPatients();
  }

  @override
  void dispose() {
    //_searchFocusNode.dispose();
    //usernameController.dispose();
    super.dispose();
  }

  Widget buildPatientsTopBar() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: const EdgeInsets.only(bottom: 5),
      color: theme.scaffoldBackgroundColor, // ← match the page background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Manage Patients",
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.textTheme.titleLarge
                  ?.color, // falls back to your default text color
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _vitalCircle(String label, dynamic value) {
    final theme = Theme.of(context);
    final bg = theme.primaryColor.withOpacity(0.1);
    final num? v =
        (value is num) ? value : num.tryParse(value?.toString() ?? "");

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: Text(
            v != null ? v.toStringAsFixed(0) : "--",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Future<void> loadLinkedPatients() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final linked = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("linkedPatients")
        .get();

    linkedPatients.addAll(linked.docs);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> handleRemovePatient(String patientId, String username) async {
    final currentUser = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser)
        .collection('linkedPatients')
        .doc(patientId)
        .delete();

    setState(() {
      linkedPatients.removeWhere((d) => d.id == patientId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unlinked $username'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).unfocus(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1) Custom header
                    buildPatientsTopBar(),

                    // 2) Search box in a rounded Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TypeAheadField<String>(
                            // Build the TextField
                            builder: (ctx, controller, focusNode) {
                              usernameController = controller;
                              _searchFocusNode = focusNode;
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  hintText: "Search & link patients",
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onSubmitted: (_) => focusNode.unfocus(),
                              );
                            },

                            // Firestore lookup
                            suggestionsCallback: (pattern) async {
                              final q = pattern.trim();
                              if (q.isEmpty) return const <String>[];
                              final snap = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('username', isGreaterThanOrEqualTo: q)
                                  .where('username',
                                      isLessThanOrEqualTo: '$q\uf8ff')
                                  .limit(10)
                                  .get();
                              return snap.docs
                                  .map((d) => d['username'] as String)
                                  .toList();
                            },

                            // Suggestion row
                            itemBuilder: (ctx, suggestion) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Text(suggestion,
                                    style: const TextStyle(fontSize: 14)),
                              );
                            },

                            // On tap
                            onSelected: (sel) {
                              usernameController.text = sel;
                              handleAddPatient();
                              usernameController.clear();
                              _searchFocusNode.unfocus();
                            },

                            // Hide box immediately
                            hideOnSelect: true,

                            // Style the floating suggestions box
                            decorationBuilder: (context, suggestionsBox) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(12),
                                  child: suggestionsBox,
                                ),
                              );
                            },

                            // Limit height & offset
                            constraints: const BoxConstraints(maxHeight: 200),
                            offset: const Offset(0, 4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3) Patient list fills the rest
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildLinkedPatientsSection(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLinkedPatientsSection() {
    return linkedPatients.isEmpty
        ? const Center(child: Text("No linked patients yet"))
        : ListView.builder(
            itemCount: linkedPatients.length,
            itemBuilder: (context, i) {
              final doc = linkedPatients[i];
              final username = (doc['username'] as String?) ?? 'Unnamed';

              final valueStream = FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL:
                    "https://healthmonitoring-21f90-default-rtdb.europe-west1.firebasedatabase.app",
              ).ref("Sensor/${doc.id}").onValue.asBroadcastStream();

              return Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Unlink Patient?'),
                          content: Text('Remove $username from your list?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Unlink')),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) => handleRemovePatient(doc.id, username),
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: PageStorageKey(doc.id),
                      title: Text(username),
                      subtitle: const Text("Live vitals preview ↓"),
                      maintainState: true,
                      children: [
                        StreamBuilder<DatabaseEvent>(
                          stream: valueStream,
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              );
                            }
                            final raw = snap.data!.snapshot.value;
                            if (raw == null) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text("No vitals available"),
                              );
                            }
                            final vitals = Map<String, dynamic>.from(
                              (raw as Map<Object?, Object?>).map(
                                (k, v) => MapEntry(k.toString(), v),
                              ),
                            );
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _vitalCircle(
                                          "AVG BPM", vitals['avg_bpm']),
                                      _vitalCircle("Heart Rate",
                                          vitals['heart_rate_bpm']),
                                      _vitalCircle("SpO₂", vitals['spo2']),
                                      _vitalCircle(
                                          "Temp °C", vitals['temperature_c']),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final controller =
                                          TextEditingController();
                                      final result = await showDialog<String>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Send Warning"),
                                          content: TextFormField(
                                            controller: controller,
                                            autofocus: true,
                                            maxLines: 3,
                                            decoration: const InputDecoration(
                                              hintText:
                                                  "Enter your warning message...",
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final msg =
                                                    controller.text.trim();
                                                if (msg.isNotEmpty) {
                                                  Navigator.pop(ctx, msg);
                                                }
                                              },
                                              child: const Text("Send"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (result != null && result.isNotEmpty) {
                                        await callCloudFunctionPush(
                                          uid: doc.id,
                                          customMessage: result,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  "Alert sent to $username."),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.warning,
                                        color: Colors.white),
                                    label: const Text("Warn Patient"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color.fromARGB(255, 28, 44, 69),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildAddPatientField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Link a User by Username",
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: usernameController,
                decoration: InputDecoration(
                  hintText: "Enter user's username",
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: handleAddPatient,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 28, 44, 69),
                foregroundColor: Colors.white, // Set text/icon color here
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Add"),
            )
          ],
        )
      ],
    );
  }

  Future<void> handleAddPatient() async {
    final enteredUsername = usernameController.text.trim();
    if (enteredUsername.isEmpty) {
      showError("Please enter a username.");
      return;
    }

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: enteredUsername)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        showError("No user found with this username.");
        return;
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;
      print("===============$userId");
      final currentUser = FirebaseAuth.instance.currentUser!.uid;

      if (userId == currentUser) {
        showError("You cannot add yourself.");
        return;
      }

      final alreadyLinked = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser)
          .collection('linkedPatients')
          .doc(userId)
          .get();

      if (alreadyLinked.exists) {
        showError("This user is already linked to your account.");
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser)
          .collection('linkedPatients')
          .doc(userId)
          .set({
        'username': userDoc['username'],
        'email': userDoc['email'],
        'linkedAt': Timestamp.now(),
      });

      linkedPatients.clear();
      final refreshed = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser)
          .collection('linkedPatients')
          .get();

      linkedPatients.addAll(refreshed.docs);
      setState(() {});
      usernameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text("User linked successfully."),
            backgroundColor: Colors.green[700]),
      );
    } catch (e) {
      print("==============================$e");
      showError("Something went wrong. Please try again.");
    }
  }

  void showError(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      title: 'Error',
      desc: message,
    ).show();
  }
}

Future<Map<String, dynamic>?> fetchVitals(String patientUid) async {
  print("➡️ Fetching vitals for UID: $patientUid");

  final db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://healthmonitoring-21f90-default-rtdb.europe-west1.firebasedatabase.app",
  );

  final dbRef = db.ref("Sensor/$patientUid");

  try {
    final snapshot = await dbRef.get();
    print("📦 Snapshot: exists=${snapshot.exists}, value=${snapshot.value}");

    if (snapshot.exists && snapshot.value != null) {
      final raw = Map<String, dynamic>.from(
        (snapshot.value as Map<Object?, Object?>).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      print("✅ Vitals found for $patientUid: $raw");
      return raw;
    } else {
      print("❌ No vitals found for UID: $patientUid");
    }
  } catch (e, stack) {
    print("❌ Exception in fetchVitals: $e");
    print("📛 Stack trace: $stack");
  }

  return null;
}

Future<void> callCloudFunctionPush({
  required String uid,
  String customMessage =
      'Your doctor has flagged your vitals. Please check your app.',
}) async {
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final userData = userDoc.data();

  if (userData == null || !userData.containsKey('fcmToken')) {
    print("❌ User or FCM token not found.");
    return;
  }

  final token = userData['fcmToken'];
  const String cloudFunctionUrl =
      'https://us-central1-healthmonitoring-21f90.cloudfunctions.net/sendPush';

  final response = await http.post(
    Uri.parse(cloudFunctionUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'token': token,
      'title': 'Doctor Alert',
      'body': customMessage,
    }),
  );

  if (response.statusCode == 200) {
    print('✅ Notification sent via Cloud Function!');
  } else {
    print('❌ Cloud Function failed: ${response.body}');
  }
}

class PatientSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => "Search patients";

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(onPressed: () => query = "", icon: const Icon(Icons.clear))
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      onPressed: () => close(context, ""), icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  Widget _buildResults(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No matches"));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final u = docs[i]['username'];
            return ListTile(
              title: Text(u),
              onTap: () => close(context,
                  u), // now `context` is the one passed into _buildResults
            );
          },
        );
      },
    );
  }
}
