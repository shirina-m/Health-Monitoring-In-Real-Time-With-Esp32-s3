import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthmonitoring/note/addn.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:healthmonitoring/note/editn.dart';


class ViewPage extends StatefulWidget {
  final String categoryID;
  const ViewPage({super.key, required this.categoryID});

  @override
  State<ViewPage> createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  bool isLoading = true;
  List<QueryDocumentSnapshot> data = [];

  getData() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("patients")
        .doc(widget.categoryID)
        .collection("note")
        .get();
    data.addAll(querySnapshot.docs);
    isLoading = false;
    setState(() {});
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color.fromARGB(255, 28, 44, 69),
          child: const Icon(
            Icons.add,
            color: Color.fromARGB(255, 194, 254, 187),
          ),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => NotePage(docid: widget.categoryID)));
          },
        ),
        appBar: AppBar(
          title: Text(
            "ViewPage",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          actions: [
            IconButton(
                color: const Color.fromARGB(255, 194, 254, 187),
                onPressed: () async {
                  GoogleSignIn googleSignIn = GoogleSignIn();
                  googleSignIn.disconnect();
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil("login", (route) => false);
                },
                icon: const Icon(Icons.exit_to_app_outlined))
          ],
        ),
        body: WillPopScope(
            child: isLoading == true
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    itemCount: data.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisExtent: 160),
                    itemBuilder: (context, i) {
                      return InkWell(
                          onLongPress: () {
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.warning,
                              animType: AnimType.rightSlide,
                              title: 'Warning',
                              desc:
                                  'Are you Sure You Want To Delete The Following Note',
                              btnCancelText: "Delete",
                              btnCancelOnPress: () async {
                                await FirebaseFirestore.instance
                                    .collection("patients")
                                    .doc(widget.categoryID)
                                    .collection("note")
                                    .doc(data[i].id)
                                    .delete();
                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (context) => ViewPage(categoryID: widget.categoryID)));
                              },
                            ).show();
                          },
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => EditNote(
                                    notedocid: data[i].id,
                                    categorydocID: widget.categoryID,
                                    Value: data[i]['note'])));
                          },
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: const Color.fromARGB(
                                255, 28, 44, 69), // dark background
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            Color.fromARGB(255, 194, 254, 187),
                                        child: Icon(Icons.note_alt_outlined,
                                            color: Colors.black),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Patient",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Expanded(
                                    child: Text(
                                      "${data[i]['note']}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ));
                    }),
            onWillPop: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil("homepage", (route) => false);
              return Future.value(false);
            }));
  }
}