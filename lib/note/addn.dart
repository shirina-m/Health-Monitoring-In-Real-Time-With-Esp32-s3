import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:healthmonitoring/components/textformfield.dart';
import 'package:healthmonitoring/components/ui_helper.dart';
import 'package:healthmonitoring/note/viewvitals.dart';

class NotePage extends StatefulWidget {
  final String docid;
  const NotePage({super.key, required this.docid});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  GlobalKey<FormState> formState = GlobalKey();
  TextEditingController note = TextEditingController();
  bool isLoading = false;

  addNote() async {
    CollectionReference noteCollection = FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.docid)
        .collection("note");
    isLoading = true;
    setState(() {});
    if (formState.currentState!.validate()) {
      try {
        DocumentReference response = await noteCollection.add({
          "note": note.text,
        });

        // here to implement for the application we are trying to make we need to add the username
        // and the UID that is associated with that username.
        isLoading = false;
        setState(() {});
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ViewPage(categoryID: widget.docid)));
      } catch (e) {
        isLoading = false;
        setState(() {});
        print("Error $e");
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Error',
          desc: 'Something Wrong Occured Try Again',
        ).show();
      }
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Page",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: formState,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: CostumeFormField(
                        hintText: "Enter Note",
                        myController: note,
                        validator: (val) {
                          if (val == "") {
                            return "Can't Be Empty";
                          }
                          return null;
                        }),
                  ),
                  ButtonDesign(
                      onPressed: () {
                        addNote();
                      },
                      title: "add")
                ],
              )),
    );
  }
}
