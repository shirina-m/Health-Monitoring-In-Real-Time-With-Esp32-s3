import 'dart:io';
import 'package:path/path.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:healthmonitoring/components/textformfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddFile extends StatefulWidget {
  const AddFile({super.key});

  @override
  State<AddFile> createState() => _AddFileState();
}

class _AddFileState extends State<AddFile> {
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
      } catch (e) {
        print("==============================================here: $e");
      }
    }
    setState(() {});
  }

  addPatient() async {
    // Call the user's CollectionReference to add a new user
    try {
      if (formState.currentState!.validate()) {
        isLoading = true;
        setState(() {});
        return await patient
            .add({
              'patient': name.text,
              'id': FirebaseAuth.instance.currentUser!.uid
            })
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
    name.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add a patient'),
        ),
        body: isLoading
            ? const Text("Loading....")
            : Form(
                key: formState,
                child: Container(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(children: [
                      CostumeFormField(
                          hintText: 'patient name',
                          myController: name,
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
                                await addPatient();
                                AwesomeDialog(
                                        context: context,
                                        dialogType: DialogType.success,
                                        title: 'User added succefully',
                                        btnOkColor: const Color.fromARGB(
                                            255, 68, 8, 79),
                                        btnOkText: 'Go back',
                                        btnOkOnPress: () {
                                          Navigator.of(context)
                                              .pushNamedAndRemoveUntil(
                                                  "homepage", (Route) => false);
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
                      MaterialButton(
                        color: Colors.purple,
                        onPressed: () {
                          getImage();
                        },
                        child: const Text("Find an image from gallery"),
                      ),
                      if (file != null && url != null)
                        Image.network(
                          url!,
                          width: 200,
                          height: 200,
                        )
                    ])),
              ));
  }
}