import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:healthmonitoring/components/textformfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthmonitoring/note/view.dart';

class EditNote extends StatefulWidget {
  final String oldNote;
  final String noteDocId;
  final String catagoryDocId;
  const EditNote(
      {super.key,
      required this.noteDocId,
      required this.catagoryDocId,
      required this.oldNote});

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  TextEditingController note = TextEditingController();
  bool isLoading = false;

  editNote() async {
    CollectionReference collectionNote = FirebaseFirestore.instance
        .collection('patient')
        .doc(widget.catagoryDocId)
        .collection("note");
    // Call the user's CollectionReference to add a new user
    try {
      if (formState.currentState!.validate()) {
        isLoading = true;
        setState(() {});
        return await collectionNote.doc(widget.noteDocId).update({
          'notes': note.text,
        });
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
  void initState() {
    note.text = widget.oldNote;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Edit'),
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
                                await editNote();
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
                                                          patientId: widget
                                                              .catagoryDocId)));
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
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                          ))
                    ])),
              ));
  }
}
