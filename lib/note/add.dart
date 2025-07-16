import 'dart:io';
import 'package:path/path.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:healthmonitoring/components/textformfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthmonitoring/note/view.dart';
import 'package:image_picker/image_picker.dart';

class AddNote extends StatefulWidget {
  final String docId;
  const AddNote({super.key, required this.docId});

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  bool isSelected = false;
  TextEditingController note = TextEditingController();
  File? file;
  String? url;
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  TextEditingController name = TextEditingController();
  bool isLoading = false;

  CollectionReference patient =
      FirebaseFirestore.instance.collection('patient');

  getImage() async {
    final ImagePicker picker = ImagePicker();
// Pick an image.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
// Capture a photo.

    if (image != null) {
      file = File(image.path);
      var imageName = basename(image.path);
      FirebaseStorage storage = FirebaseStorage.instanceFor(
          bucket: "gs://healthmonitoring-21f90.firebasestorage.app");
      var refStorage = storage.ref().child("image").child(imageName);

      try {
        await refStorage.putFile(file!);

        url = await refStorage.getDownloadURL();
        isSelected = true;
      } catch (e) {
        print("==============================================here: $e");
      }
    }
    setState(() {});
  }

  addNote() async {
    CollectionReference collectionNote = FirebaseFirestore.instance
        .collection('patient')
        .doc(widget.docId)
        .collection("note");
    // Call the user's CollectionReference to add a new user
    try {
      if (formState.currentState!.validate()) {
        isLoading = true;
        setState(() {});
        return await collectionNote
            .add({'notes': note.text, 'url': url ?? "none"})
            .then((value) => print("User Added"))
            .catchError((error) => print("Failed to add user: $error"));
      }
    } catch (e) {
      isLoading = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add a note'),
        ),
        body: isLoading
            ? const Text("Loading....")
            : Form(
                key: formState,
                child: Container(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(children: [
                      CostumeFormField(
                          hintText: 'Write a note',
                          myController: note,
                          validator: (val) {
                            if (val == '') return 'Can not be empty';
                            return null;
                          }),
                      Container(
                          color: Colors.black,
                          margin: const EdgeInsets.all(10.0),
                          child: MaterialButton(
                            onPressed: () async {
                              if (formState.currentState!.validate()) {
                                await addNote();
                                AwesomeDialog(
                                        context: context,
                                        dialogType: DialogType.success,
                                        title: 'Note added succesfuly',
                                        btnOkColor: const Color.fromARGB(
                                            255, 68, 8, 79),
                                        btnOkText: 'Go back',
                                        btnOkOnPress: () {
                                          Navigator.of(context).pop(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ViewNote(
                                                          patientId:
                                                              widget.docId)));
                                        },
                                        btnCancelOnPress: () {
                                          return;
                                        },
                                        btnCancelText: 'Add more')
                                    .show();
                              } else {
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.error,
                                  title: 'Something went wrong',
                                  btnOkColor:
                                      const Color.fromARGB(255, 68, 8, 79),
                                  btnOkOnPress: () {
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                            "homepage", (Route) => false);
                                  },
                                ).show();
                              }
                            },
                            child: const Text(
                              'Add',
                              style: TextStyle(color: Colors.white),
                            ),
                          )),
                      Container(
                          color: isSelected == false
                              ? Colors.black
                              : Colors.purple,
                          margin: const EdgeInsets.all(10.0),
                          child: MaterialButton(
                            onPressed: () async {
                              await getImage();
                              if (isSelected) {
                                AwesomeDialog(
                                        context: context,
                                        dialogType: DialogType.success,
                                        title: 'Note added succesfuly',
                                        btnOkColor: const Color.fromARGB(
                                            255, 68, 8, 79),
                                        btnOkText: 'Go back',
                                        btnOkOnPress: () {
                                          Navigator.of(context).pop(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ViewNote(
                                                          patientId:
                                                              widget.docId)));
                                        },
                                        btnCancelOnPress: () {
                                          return;
                                        },
                                        btnCancelText: 'Add more')
                                    .show();
                              } else {
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.error,
                                  title: 'Something went wrong',
                                  btnOkColor:
                                      const Color.fromARGB(255, 68, 8, 79),
                                  btnOkOnPress: () {
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                            "homepage", (Route) => false);
                                  },
                                ).show();
                              }
                            },
                            child: isSelected == false
                                ? const Text(
                                    "Upload an image",
                                    style: TextStyle(color: Colors.white),
                                  )
                                : const Text("Image is uploaded",
                                    style: TextStyle(color: Colors.white)),
                          )),
                    ])),
              ));
  }
}
