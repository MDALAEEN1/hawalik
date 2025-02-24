import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hawalik/assets/widgets/const.dart';
import 'package:hawalik/frontend/drivers/OrderDetailsPage.dart';

class MyOrdersPage extends StatefulWidget {
  @override
  _MyOrdersPageState createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("طلباتي")),
        body: const Center(child: Text("❌ يجب تسجيل الدخول لعرض الطلبات")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("طلباتي"),
        backgroundColor: kapp,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('my_orders')
            .doc(user!.uid)
            .collection('orders')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("🚀 لا يوجد لديك طلبات حالياً!"));
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              var orderData = order.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text("📌 الطلب #${order.id}"),
                  subtitle: Text(
                      "💰 السعر: JD${orderData['totalAmount']?.toStringAsFixed(2) ?? 'غير متوفر'}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsPage(
                          orderData: {
                            ...orderData, // 🔹 تأكد من تمرير كل البيانات
                            'orderId': order.id, // ✅ إضافة رقم الطلب
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
