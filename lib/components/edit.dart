import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:healthmonitoring/components/textformfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPatient extends StatefulWidget {
  final String? docId;
  final String oldName;
  const EditPatient({super.key, required this.docId, required this.oldName});

  @override
  State<EditPatient> createState() => _EditPatientState();
}

class _EditPatientState extends State<EditPatient> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  TextEditingController name = TextEditingController();
  bool isLoading = false;

  CollectionReference patient =
      FirebaseFirestore.instance.collection('patient');

  EditPatientName() async {
    // Call the user's CollectionReference to add a new user
    if (formState.currentState!.validate()) {
      try {
        isLoading = true;
        setState(() {});
        await patient.doc(widget.docId).update({
          'patient': name.text,
        });
        setState(() {});
      } catch (e) {
        isLoading = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    name.text = widget.oldName;
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
                                await EditPatientName();
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.success,
                                  desc: 'Patient changed succesfuly',
                                  btnOkColor:
                                      const Color.fromARGB(255, 68, 8, 79),
                                  btnOkText: 'Go back',
                                  btnOkOnPress: () {
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                            "homepage", (Route) => false);
                                  },
                                  btnCancelOnPress: () {
                                    return;
                                  },
                                ).show();
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
