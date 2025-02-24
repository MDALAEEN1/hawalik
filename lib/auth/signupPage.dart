import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hawalik/assets/widgets/const.dart';
import 'package:hawalik/frontend/screens/homePage.dart';
import 'package:lucide_icons/lucide_icons.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late String email = '';
  late String pass = '';
  late String firstName = '';
  late String lastName = '';
  late String birthDate = '';
  late String nationality = '';

  // متغير لتخزين التاريخ المختار
  DateTime selectedDate = DateTime.now();

  // دالة لاختيار التاريخ
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        birthDate =
            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: kbackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: screenHeight * 0.12,
              ),
              Icon(
                LucideIcons.truck,
                size: 250,
                color: kapp,
              ),
              // اسم المستخدم
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.black),
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        firstName = value;
                      },
                      decoration: const InputDecoration(
                          hintText: "First Name",
                          hintStyle: TextStyle(color: Colors.black),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.black),
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        lastName = value;
                      },
                      decoration: const InputDecoration(
                          hintText: "Last Name",
                          hintStyle: TextStyle(color: Colors.black),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // حقل اختيار تاريخ الميلاد
              GestureDetector(
                onTap: () =>
                    _selectDate(context), // استدعاء دالة اختيار التاريخ
                child: AbsorbPointer(
                  child: TextField(
                    style: TextStyle(color: Colors.black),
                    textAlign: TextAlign.center,
                    controller: TextEditingController(text: birthDate),
                    decoration: const InputDecoration(
                      hintText: "Birth Date",
                      hintStyle: TextStyle(color: Colors.black),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // الجنسية
              TextField(
                style: TextStyle(color: Colors.black),
                textAlign: TextAlign.center,
                onChanged: (value) {
                  nationality = value;
                },
                decoration: const InputDecoration(
                    hintText: "Nationality",
                    hintStyle: TextStyle(color: Colors.black),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
              const SizedBox(height: 10),

              // Email textField
              TextField(
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
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
              const SizedBox(height: 10),

              // Password textField
              TextField(
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
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
              const SizedBox(height: 15),

              // Sign-up button
              TextButton(
                onPressed: () async {
                  if (email.isEmpty ||
                      pass.isEmpty ||
                      firstName.isEmpty ||
                      lastName.isEmpty ||
                      birthDate.isEmpty ||
                      nationality.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  try {
                    // إنشاء حساب جديد
                    UserCredential userCredential =
                        await _auth.createUserWithEmailAndPassword(
                            email: email, password: pass);

                    // تخزين البيانات في Firestore بعد إنشاء الحساب
                    await _firestore
                        .collection('users')
                        .doc(userCredential.user?.uid)
                        .set({
                      'firstName': firstName,
                      'lastName': lastName,
                      'birthDate': birthDate,
                      'nationality': nationality,
                      'email': email,
                    });

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Homepage(),
                        ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Sign-up successful!")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                },
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.lightBlue)),
                child: const Text(
                  "Sign up",
                  style: TextStyle(color: ktext),
                ),
              ),
              const SizedBox(height: 20),

              // Row for login and password recovery
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Do you have an account? ",
                    style: TextStyle(color: Colors.black),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Sign in",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
