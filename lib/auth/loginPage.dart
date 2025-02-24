import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hawalik/assets/widgets/const.dart';
import 'package:hawalik/auth/signupPage.dart';
import 'package:hawalik/frontend/screens/homePage.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  String email = '';
  String pass = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kbackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // المحاذاة العمودية
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // المحاذاة الأفقية
              children: [
                Icon(
                  LucideIcons.truck,
                  size: 250,
                  color: kapp,
                ),
                const SizedBox(
                    height: 20), // مسافة بين الأيقونة والمحتوى التالي
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    style: TextStyle(color: Colors.black),
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      email = value;
                    },
                    decoration: const InputDecoration(
                        hintText: "Enter your Email",
                        hintStyle: TextStyle(color: Colors.black),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    style: TextStyle(color: Colors.black),
                    obscureText: true,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      pass = value;
                    },
                    decoration: const InputDecoration(
                        hintText: "Enter your Password",
                        hintStyle: TextStyle(color: Colors.black),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (email.isEmpty || pass.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Please enter both email and password")),
                              );
                              return;
                            }

                            setState(() {
                              isLoading = true;
                            });

                            try {
                              await _auth.signInWithEmailAndPassword(
                                  email: email, password: pass);
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Homepage(),
                                  ));

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Sign-in successful!")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Error: ${e.toString()}")),
                              );
                            } finally {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(kapp)),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Sign in", style: TextStyle(color: ktext)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // المحاذاة الأفقية
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.black),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Signup(),
                            ),
                          );
                        },
                        child: const Text(
                          "Signup",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                    onPressed: () async {
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("please write your email.")),
                        );
                        return;
                      }
                      await _auth.sendPasswordResetEmail(email: email);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("check your email.")));
                    },
                    child: const Text(
                      "Forgot your password?",
                      style: TextStyle(color: Colors.blue),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
