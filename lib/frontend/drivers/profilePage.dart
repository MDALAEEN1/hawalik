import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hawalik/assets/widgets/const.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  _DriverProfilePageState createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("ملف السائق")),
        body: const Center(child: Text("⚠️ لم يتم تسجيل الدخول")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("ملف السائق الشخصي"),
        backgroundColor: kapp,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admin_drivers')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: Text("⚠️ لم يتم العثور على بيانات السائق"));
          }

          var driverData = snapshot.data!;
          String name = driverData['name'] ?? "غير معروف";
          String email = driverData['email'] ?? "غير متوفر";
          String phone = driverData['phone'] ?? "غير متوفر";
          double balance = driverData['balance'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child:
                              Icon(Icons.person, size: 100, color: Colors.blue),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow("👤 الاسم:", name),
                        _buildInfoRow("📧 البريد الإلكتروني:", email),
                        _buildInfoRow("📞 الهاتف:", phone),
                        _buildInfoRow("💰 الرصيد:", "$balance JD"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔹 ويدجت لإظهار صف من البيانات
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
