import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hawalik/assets/widgets/const.dart';
import 'package:hawalik/frontend/drivers/MyOrdersPage.dart';
import 'package:hawalik/frontend/drivers/OrderDetailsPage.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _takeOrder(DocumentSnapshot order) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ يجب تسجيل الدخول لأخذ الطلب")),
        );
        return;
      }

      final String uid = user.uid;

      // 🛑 التحقق من عدد الطلبات النشطة للسائق
      QuerySnapshot myOrdersSnapshot = await _firestore
          .collection('my_orders')
          .doc(uid)
          .collection('orders')
          .get();

      if (myOrdersSnapshot.docs.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ لا يمكنك أخذ أكثر من طلبين في نفس الوقت!"),
          ),
        );
        return;
      }

      // ✅ السائق يمكنه أخذ الطلب
      final orderData = order.data() as Map<String, dynamic>;
      orderData['driverId'] = uid; // إضافة معرف السائق للطلب

      await _firestore
          .collection('my_orders')
          .doc(uid)
          .collection('orders')
          .doc(order.id)
          .set(orderData);

      await _firestore.collection('orders').doc(order.id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم أخذ الطلب بنجاح!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ خطأ: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kapp,
        title: const Text("جميع الطلبات"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("🚀 لا يوجد طلبات حالياً"));
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
                  trailing: ElevatedButton(
                    onPressed: () => _takeOrder(order),
                    child: const Text("أخذ الطلب"),
                  ),
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailsPage(orderData: orderData),
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
