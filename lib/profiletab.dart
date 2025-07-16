import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:light_dark_theme_toggle/light_dark_theme_toggle.dart';

// ← Import your main.dart (where themeNotifier lives)
import 'package:healthmonitoring/main.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? username;
  String? role;
  String? email;
  bool isLoading = true;

  // 2️⃣ A local bool to hold the current theme state:
  bool isLightMode = true;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
    // Initialize local switch from the global notifier:
    isLightMode = themeNotifier.value == ThemeMode.light;
  }

  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    setState(() {
      username = userDoc['username'] ?? 'N/A';
      role = userDoc['role'] ?? 'N/A';
      email = user?.email ?? 'N/A';
      isLoading = false;
    });
  }

  Future<void> sendResetPassword() async {
    try {
      if (email != null && email != 'N/A') {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email!);
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.rightSlide,
          title: 'Password Reset',
          desc:
              'A reset link has been sent to your email. Please check your inbox.',
        ).show();
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Error',
        desc: 'Failed to send reset link. Please try again.',
      ).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: ClipOval(
                        child: Image.asset(
                          'images/appLogo.png', // your logo asset
                          fit: BoxFit.cover,
                          width: 70,
                          height: 70,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(username ?? "Unknown",
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(email ?? "No email",
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text("Role: $role",
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),

                    // 💡 Dark/Light mode toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: LightDarkThemeToggle(
                        value: isLightMode,
                        onChanged: (newValue) {
                          setState(() {
                            isLightMode = newValue;
                          });
                          // 🔄 Update the global ThemeMode
                          themeNotifier.value =
                              newValue ? ThemeMode.light : ThemeMode.dark;
                        },
                        themeIconType: ThemeIconType.classic,
                        size: 36.0,
                        color: Colors.grey,
                        tooltip: isLightMode
                            ? 'Switch to Dark Mode'
                            : 'Switch to Light Mode',
                      ),
                    ),

                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.lock_reset,
                                color: Colors.blue),
                            title: const Text("Change Password"),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: sendResetPassword,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading:
                                const Icon(Icons.logout, color: Colors.red),
                            title: const Text("Logout"),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final googleSignIn = GoogleSignIn();
                              if (await googleSignIn.isSignedIn()) {
                                await googleSignIn
                                    .signOut(); // safer than disconnect
                              }

                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  "login", (route) => false);
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
