import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:healthmonitoring/note/add.dart';
import 'package:healthmonitoring/note/edit.dart';

class ViewNote extends StatefulWidget {
  final String patientId;
  const ViewNote({super.key, required this.patientId});

  @override
  State<ViewNote> createState() => _ViewNoteState();
}

class _ViewNoteState extends State<ViewNote> {
  List<QueryDocumentSnapshot> data = [];
  bool isLaoding = true;

  getData() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('patient')
        .doc(widget.patientId)
        .collection('note')
        .get();

    data.addAll(querySnapshot.docs);
    isLaoding = false;
    setState(() {});
  }

  @override
  void initState() {
    isLaoding = true;
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AddNote(docId: widget.patientId)));
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text("Note"),
        actions: [
          IconButton(
              onPressed: () async {
                GoogleSignIn googleSignIn = GoogleSignIn();
                googleSignIn.disconnect();
                await FirebaseAuth.instance.signOut();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil("login", (route) => false);
              },
              icon: const Icon(Icons.exit_to_app))
        ],
      ),
      body: isLaoding ==
              true //here we r saying if islaoding is true then show the text laoding otherwise show the gridview
          ? const Center(
              child: Text("Laoding...."),
            )
          : GridView.builder(
              itemCount: data.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2),
              itemBuilder: (context, i) {
                return InkWell(
                    onLongPress: () async {
                      AwesomeDialog(
                          context: context,
                          dialogType: DialogType.info,
                          animType: AnimType.rightSlide,
                          desc: 'What do you need',
                          btnCancelText: "Delete",
                          btnCancelOnPress: () async {
                            //Fix this
                            await FirebaseFirestore.instance
                                .collection('patient')
                                .doc(widget.patientId)
                                .collection('note')
                                .doc(data[i].id)
                                .delete();
                            Navigator.of(context).pop(MaterialPageRoute(
                                builder: (context) =>
                                    ViewNote(patientId: widget.patientId)));
                          },
                          btnOkText: "Update",
                          btnOkOnPress: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => EditNote(
                                    noteDocId: data[i].id,
                                    catagoryDocId: widget.patientId,
                                    oldNote: data[i]['notes'])));
                          }).show();
                    },
                    child: Card(
                        color: const Color.fromARGB(255, 61, 9, 93),
                        child: Center(
                          child: Column(
                            children: [
                              const Text(
                                "99",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 100,
                                ),
                              ),
                              Text("${data[i]['notes']}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ))
                            ],
                          ),
                        )));
              }),
    );
  }
}
