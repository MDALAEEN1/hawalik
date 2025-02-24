import 'package:flutter/material.dart';
import 'package:hawalik/firebase_options.dart';
import 'package:hawalik/frontend/admin/adminHomepage.dart';

import 'package:hawalik/frontend/screens/FilterPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hawalik/frontend/screens/foodPage.dart';
import 'package:hawalik/frontend/screens/myAllStuts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FoodPage(),
      routes: {
        '/filterPage': (context) => const FilterPage(),
      },
    );
  }
}
