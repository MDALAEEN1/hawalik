import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDriversPage extends StatefulWidget {
  const AdminDriversPage({super.key});

  @override
  _AdminDriversPageState createState() => _AdminDriversPageState();
}

class _AdminDriversPageState extends State<AdminDriversPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();

  /// 🔹 دالة لإظهار نافذة إدخال البريد الإلكتروني لإضافة سائق
  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("إضافة سائق جديد"),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: "البريد الإلكتروني",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                emailController.clear();
                Navigator.pop(context);
              },
              child: const Text("إلغاء"),
            ),
            TextButton(
              onPressed: () {
                _addDriver();
                Navigator.pop(context);
              },
              child: const Text("إضافة"),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 دالة لإضافة سائق جديد عبر البريد الإلكتروني
  void _addDriver() async {
    String email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ الرجاء إدخال البريد الإلكتروني")),
      );
      return;
    }

    try {
      print("🔍 البحث عن المستخدم بالبريد: $email");

      // 🔹 البحث عن المستخدم داخل مجموعة users
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      print("📌 عدد النتائج: ${userQuery.docs.length}");

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ السائق غير مسجل في النظام")),
        );
        return;
      }

      // 🔹 جلب بيانات المستخدم
      var userData = userQuery.docs.first;
      String uid = userData.id; // 🔥 UID الخاص بالمستخدم

      print("✅ السائق موجود، UID: $uid");

      // 🔹 التحقق مما إذا كان السائق مضافًا مسبقًا
      DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance
          .collection('admin_drivers')
          .doc(uid)
          .get();

      if (driverSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ هذا السائق مضاف مسبقًا")),
        );
        return;
      }

      // 🔹 إضافة السائق إلى Firestore
      await FirebaseFirestore.instance
          .collection('admin_drivers')
          .doc(uid)
          .set({
        'uid': uid,
        'email': email,
        'name': userData['firstName'] ?? 'غير معروف',
        'phone': userData['phone'] ?? 'غير متوفر',
        'balance': 0, // الرصيد الافتراضي
      });

      print("✅ تم إضافة السائق بنجاح!");

      emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم إضافة السائق بنجاح")),
      );
    } catch (e) {
      print("❌ خطأ أثناء البحث عن السائق: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ حدث خطأ أثناء البحث عن السائق: $e')),
      );
    }
  }

  /// 🔹 دالة لفتح نافذة تعبئة الرصيد
  void _showAddBalanceDialog(String driverId, int currentBalance) {
    balanceController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("إضافة رصيد للسائق"),
          content: TextField(
            controller: balanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "المبلغ",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء"),
            ),
            TextButton(
              onPressed: () async {
                int addedBalance = int.tryParse(balanceController.text) ?? 0;
                if (addedBalance <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠️ الرجاء إدخال مبلغ صحيح")),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('admin_drivers')
                    .doc(driverId)
                    .update({'balance': currentBalance + addedBalance});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ تم إضافة الرصيد بنجاح!")),
                );

                Navigator.pop(context);
              },
              child: const Text("إضافة"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة السائقين"),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDriverDialog,
        child: const Icon(Icons.person_add),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "قائمة السائقين",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('admin_drivers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("⚠️ لا يوجد سائقين مسجلين"));
                  }

                  final drivers = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      final driverId = driver.id;
                      final driverName = driver['name'];
                      final driverEmail = driver['email'];
                      final driverPhone = driver['phone'];
                      final driverBalance = (driver['balance'] as num)
                          .toInt(); // Ensures int type

                      return Card(
                        child: ListTile(
                          title: Text(
                            driverName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                          subtitle: Text(
                              "📧 $driverEmail\n📞 $driverPhone\n💰 الرصيد: ${driverBalance.toString()} JD"),
                          onTap: () => _showAddBalanceDialog(
                              driverId, driverBalance), // Now expects int
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
