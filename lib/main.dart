import 'package:flutter/material.dart';
import 'package:hawalik/auth/loginPage.dart';
import 'package:hawalik/firebase_options.dart';
import 'package:hawalik/frontend/screens/FilterPage.dart';
import 'package:hawalik/frontend/drivers/driverspage.dart';
import 'package:hawalik/frontend/resuorant/RestaurantMenuAdminPage.dart';
import 'package:hawalik/frontend/screens/foodPage.dart';
import 'package:firebase_core/firebase_core.dart';

import 'frontend/drivers/homePage.dart';

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
      home: Homepage(),
      routes: {
        '/filterPage': (context) => const FilterPage(),
      },
    );
  }
}
