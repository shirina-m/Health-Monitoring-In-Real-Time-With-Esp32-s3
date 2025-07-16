import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthmonitoring/components/textformfield.dart';
import 'package:healthmonitoring/components/ui_helper.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isLoading = false;
  String selectedRole = 'patient';
  bool _obscurePassword = true;

  @override
  void dispose() {
    username.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            Form(
              key: formState,
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: CenterLogo()),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.person_add_alt_1_rounded,
                            color: Color.fromARGB(255, 28, 44, 69), size: 24),
                        const SizedBox(width: 6),
                        Text(
                          "Sign Up",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Create an account to get started",
                      style: TextStyle(
                        color: Color.fromARGB(255, 101, 128, 172),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text("Username",
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 6),
                    CostumeFormField(
                      hintText: "Enter Your Username",
                      myController: username,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Can't be empty";
                        if (val.contains(' ')) {
                          return "Username cannot contain spaces";
                        }
                        if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(val)) {
                          return "Only letters and numbers allowed";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text("Email", style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 6),
                    CostumeFormField(
                      hintText: "Enter Your Email",
                      myController: email,
                      validator: (val) => val == "" ? "Can't Be Empty" : null,
                    ),
                    const SizedBox(height: 16),
                    Text("Password",
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 6),
                    CostumeFormField(
                      hintText: "Enter Your Password",
                      myController: password,
                      obsecuretext: _obscurePassword,
                      validator: (val) => val == "" ? "Can't Be Empty" : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text("Select Role",
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            showGeneralDialog(
                              context: context,
                              barrierLabel: "Role Info",
                              barrierDismissible: true,
                              barrierColor: Colors.black.withOpacity(0.3),
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                              pageBuilder: (context, anim1, anim2) => Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.85,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.info_outline,
                                                color: Color.fromARGB(
                                                    255, 28, 44, 69)),
                                            SizedBox(width: 8),
                                            Text("Role Info",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: Color.fromARGB(
                                                        255, 28, 44, 69))),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        const Text(
                                          "• Patients can view and monitor their own vitals.\n"
                                          "• Caregivers can track vitals of linked patients.",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87),
                                        ),
                                        const SizedBox(height: 20),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            style: TextButton.styleFrom(
                                                foregroundColor:
                                                    const Color.fromARGB(
                                                        255, 28, 44, 69)),
                                            child: const Text("Got it",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              transitionBuilder: (context, anim1, _, child) =>
                                  FadeTransition(
                                opacity: CurvedAnimation(
                                    parent: anim1, curve: Curves.easeOut),
                                child: ScaleTransition(
                                    scale: CurvedAnimation(
                                        parent: anim1,
                                        curve: Curves.easeOutBack),
                                    child: child),
                              ),
                            );
                          },
                          child: Icon(Icons.info_outline,
                              size: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration:
                            const InputDecoration(border: InputBorder.none),
                        items: const [
                          DropdownMenuItem(
                              value: 'patient', child: Text('Patient')),
                          DropdownMenuItem(
                              value: 'caregiver', child: Text('Caregiver')),
                        ],
                        onChanged: isLoading
                            ? null
                            : (val) => setState(() => selectedRole = val!),
                      ),
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ButtonDesign(
                            title: "Sign Up",
                            onPressed: () async {
                              if (formState.currentState!.validate()) {
                                setState(() => isLoading = true);
                                final existing = await FirebaseFirestore
                                    .instance
                                    .collection('users')
                                    .where('username',
                                        isEqualTo: username.text.trim())
                                    .get();

                                if (existing.docs.isNotEmpty) {
                                  setState(() => isLoading = false);
                                  AwesomeDialog(
                                    context: context,
                                    dialogType: DialogType.error,
                                    animType: AnimType.rightSlide,
                                    title: 'Username Taken',
                                    desc:
                                        'This username is already in use. Please choose another one.',
                                  ).show();
                                  return;
                                }

                                try {
                                  final credential = await FirebaseAuth.instance
                                      .createUserWithEmailAndPassword(
                                    email: email.text.trim(),
                                    password: password.text,
                                  );

                                  await FirebaseAuth.instance.currentUser!
                                      .sendEmailVerification();

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(credential.user!.uid)
                                      .set({
                                    'username': username.text.trim(),
                                    'email': email.text.trim(),
                                    'role': selectedRole,
                                  });

                                  await FirebaseFirestore.instance
                                      .collection('patients')
                                      .doc(credential.user!.uid)
                                      .set({
                                    'id': credential.user!.uid,
                                    'name': username.text.trim(),
                                  });

                                  await FirebaseFirestore.instance
                                      .collection('patient')
                                      .doc(credential.user!.uid)
                                      .set({
                                    'id': credential.user!.uid,
                                    'name': username.text.trim(),
                                  });

                                  setState(() => isLoading = false);
                                  username.clear();
                                  email.clear();
                                  password.clear();

                                  AwesomeDialog(
                                    context: context,
                                    dialogType: DialogType.success,
                                    animType: AnimType.rightSlide,
                                    title: 'Success',
                                    desc:
                                        'A verification email has been sent—please check your inbox to activate your account.\n Account created successfully!',
                                    btnOkOnPress: () {
                                      Navigator.of(context)
                                          .pushReplacementNamed("login");
                                    },
                                  ).show();
                                } on FirebaseAuthException catch (e) {
                                  setState(() => isLoading = false);
                                  if (e.code == 'weak-password') {
                                    AwesomeDialog(
                                      context: context,
                                      dialogType: DialogType.error,
                                      animType: AnimType.rightSlide,
                                      title: 'Error',
                                      desc:
                                          'The password provided is too weak.',
                                    ).show();
                                  } else if (e.code == 'email-already-in-use') {
                                    AwesomeDialog(
                                      context: context,
                                      dialogType: DialogType.error,
                                      animType: AnimType.rightSlide,
                                      title: 'Error',
                                      desc:
                                          'The account already exists for that email.',
                                    ).show();
                                  }
                                } catch (e) {
                                  setState(() => isLoading = false);
                                  print(e);
                                }
                              }
                            },
                          ),
                    const SizedBox(height: 16),
                    Center(
                      child: InkWell(
                        onTap: () =>
                            Navigator.of(context).pushReplacementNamed("login"),
                        child: RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 28, 44, 69),
                                ),
                              ),
                              TextSpan(
                                text: "Log In",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
