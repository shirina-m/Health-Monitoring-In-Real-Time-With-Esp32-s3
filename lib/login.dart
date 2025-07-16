import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthmonitoring/components/textformfield.dart';
import 'package:healthmonitoring/components/ui_helper.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.transparent,
//     appBar: AppBar(
//   backgroundColor: const Color(0xFF1C2C45),
//   elevation: 0,
//   centerTitle: true,
//   leading: Padding(
//     padding: const EdgeInsets.only(left: 16),
//     child: Icon(
//       Icons.lock_rounded,
//       color: Color.fromARGB(255, 194, 254, 187),
//       size: 28,
//     ),
//   ),
//   title: Text(
//     "Log In Page",
//     style: TextStyle(
//       fontFamily: 'Poppins', // or any modern font
//       fontSize: 20,
//       fontWeight: FontWeight.w600,
//       color: Color.fromARGB(255, 194, 254, 187),
//     ),
//   ),
//   actions: [
//     IconButton(
//       icon: Icon(Icons.info_outline_rounded),
//       onPressed: () {
//         // optional info/help
//       },
//       color: Color.fromARGB(255, 194, 254, 187),
//     ),
//   ],
// ),

      body: isLoading == true
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              padding: const EdgeInsets.all(10),
              child: ListView(
                children: [
                  //Logo Design
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
                              const Icon(Icons.lock_open_rounded,
                                  color: Color.fromARGB(255, 28, 44, 69),
                                  size: 24),
                              const SizedBox(width: 6),
                              Text(
                                "Login",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      fontSize: 22,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Login to continue using the app",
                            style: TextStyle(
                              color: Color.fromARGB(255, 101, 128, 172),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email
                          Text(
                            "Email",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 6),
                          CostumeFormField(
                            hintText: "Enter Your Email",
                            myController: email,
                            obsecuretext: false,
                            validator: (val) {
                              if (val == "") return "Can't Be Empty";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          Text(
                            "Password",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 6),
                          CostumeFormField(
                            hintText: "Enter Your Password",
                            myController: password,
                            obsecuretext: _obscurePassword,
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
                            validator: (val) {
                              if (val == "") return "Can't Be Empty";
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () async {
                                if (email.text == "") {
                                  AwesomeDialog(
                                    context: context,
                                    dialogType: DialogType.error,
                                    animType: AnimType.rightSlide,
                                    title: 'Error',
                                    desc: 'Email field can’t be empty',
                                  ).show();
                                  return;
                                }

                                try {
                                  await FirebaseAuth.instance
                                      .sendPasswordResetEmail(
                                          email: email.text);
                                  AwesomeDialog(
                                    context: context,
                                    dialogType: DialogType.success,
                                    animType: AnimType.rightSlide,
                                    title: 'Password Reset',
                                    desc:
                                        'A reset link has been sent to your email. Please check your inbox.',
                                  ).show();
                                } catch (e) {
                                  AwesomeDialog(
                                    context: context,
                                    dialogType: DialogType.error,
                                    animType: AnimType.rightSlide,
                                    title: 'Error',
                                    desc:
                                        'Please make sure the email is correct!',
                                  ).show();
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 80, 192, 67),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Log In button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formState.currentState!.validate()) {
                                  try {
                                    setState(() => isLoading = true);
                                    final credential = await FirebaseAuth
                                        .instance
                                        .signInWithEmailAndPassword(
                                            email: email.text.trim(),
                                            password: password.text);
                                    setState(() => isLoading = false);

                                    if (credential.user!.emailVerified) {
                                      Navigator.of(context)
                                          .pushReplacementNamed("dashboard");
                                    } else {
                                      await FirebaseAuth.instance.currentUser!
                                          .sendEmailVerification();
                                      AwesomeDialog(
                                        context: context,
                                        dialogType: DialogType.error,
                                        animType: AnimType.rightSlide,
                                        title: 'Error',
                                        desc: 'Please verify your email first.',
                                      ).show();
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    setState(() => isLoading = false);
                                    String errorMsg = switch (e.code) {
                                      'invalid-credential' ||
                                      'wrong-password' ||
                                      'user-not-found' =>
                                        'Email or password is incorrect.',
                                      'invalid-email' =>
                                        'The email address is badly formatted.',
                                      _ => e.message ??
                                          'An unknown error occurred.',
                                    };

                                    AwesomeDialog(
                                      context: context,
                                      dialogType: DialogType.error,
                                      animType: AnimType.rightSlide,
                                      title: 'Login Failed',
                                      desc: "Please Verify Your Email.",
                                    ).show();
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 28, 44, 69),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                "Log In",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                      color: const Color.fromARGB(
                                          255, 194, 254, 187),
                                    ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          const SizedBox(height: 12),

                          const SizedBox(height: 16),

                          // Register text
                          Center(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context)
                                    .pushReplacementNamed("signup");
                              },
                              child: RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Don’t have an account? ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color.fromARGB(255, 28, 44, 69),
                                      ),
                                    ),
                                    TextSpan(
                                      text: "Register",
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
                  )
                ],
              ),
            ),
    );
  }
}
