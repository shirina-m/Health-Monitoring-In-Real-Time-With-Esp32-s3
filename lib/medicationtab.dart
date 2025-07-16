import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthmonitoring/addmedication.dart';

class MedicationTab extends StatefulWidget {
  const MedicationTab({super.key});

  @override
  State<MedicationTab> createState() => _MedicationTabState();
}

class _MedicationTabState extends State<MedicationTab> {
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<String?> getPatientDocId() async {
    if (uid == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('patient')
        .where('id', isEqualTo: uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id; // return the doc ID
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Medications"),
        backgroundColor: const Color.fromARGB(255, 28, 44, 69),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: uid == null
            ? const Center(child: Text("User not logged in"))
            : FutureBuilder<String?>(
                future: getPatientDocId(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final patientDocId = snapshot.data;
                  if (patientDocId == null) {
                    return const Center(child: Text("User data not found."));
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('patient')
                        .doc(patientDocId)
                        .collection('pills')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No medications added yet",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        );
                      }

                      final pills = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: pills.length,
                        itemBuilder: (context, index) {
                          final pill =
                              pills[index].data() as Map<String, dynamic>;
                          final name = pill['name'] ?? 'Unnamed Pill';
                          final frequency = pill['frequency'] ?? '';
                          final timesList =
                              (pill['times'] as List?)?.cast<String>() ?? [];

                          return InkWell(
                            onTap: () {
                              // TODO: Navigate to edit screen
                            },
                            onLongPress: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Delete Medication"),
                                  content: const Text(
                                      "Are you sure you want to delete this medication?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseFirestore.instance
                                    .collection('patient')
                                    .doc(patientDocId)
                                    .collection('pills')
                                    .doc(pills[index].id)
                                    .delete();
                              }
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 3,
                              child: ListTile(
                                leading: const Icon(Icons.medication,
                                    color: Colors.blue),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "Times: ${timesList.join(', ')}\nFrequency: $frequency",
                                ),
                                isThreeLine: true,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddMedication()));
        },
        label: const Text(
          "Add Medication",
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(
          Icons.add,
          color: Color.fromARGB(255, 254, 254, 254),
        ),
        backgroundColor: const Color.fromARGB(255, 28, 44, 69),
      ),
    );
  }
}
