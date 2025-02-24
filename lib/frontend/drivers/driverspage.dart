import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hawalik/assets/widgets/const.dart';
import 'package:hawalik/frontend/drivers/OrderDetailsPage.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ **جلب عدد الطلبات التي أخذها السائق**
  Future<int> _getDriverOrderCount(String uid) async {
    QuerySnapshot ordersSnapshot = await _firestore
        .collection('my_orders')
        .doc(uid)
        .collection('orders')
        .get();
    return ordersSnapshot.docs.length; // عدد الطلبات
  }

  /// ✅ **دالة أخذ الطلب**
  Future<void> _takeOrder(DocumentSnapshot order) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ يجب تسجيل الدخول لأخذ الطلب")),
      );
      return;
    }

    final String uid = user.uid;
    final orderData = order.data() as Map<String, dynamic>;

    // 🛑 **التأكد من عدد الطلبات الحالية**
    int currentOrders = await _getDriverOrderCount(uid);
    if (currentOrders >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠️ لا يمكنك أخذ أكثر من طلبين في نفس الوقت!")),
      );
      return;
    }

    // 🛑 **تأكيد أخذ الطلب**
    bool confirm = await _showConfirmationDialog();
    if (!confirm) return;

    try {
      // ✅ **جلب بيانات السائق**
      DocumentSnapshot driverSnapshot =
          await _firestore.collection('admin_drivers').doc(uid).get();

      if (!driverSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ لم يتم العثور على بيانات السائق!")),
        );
        return;
      }

      double driverBalance = driverSnapshot['balance'] ?? 0; // رصيد السائق
      double deliveryFee = orderData['deliveryFee'] ?? 0; // رسوم التوصيل
      double deductionAmount = deliveryFee * 0.15; // حساب الخصم (15%)

      if (driverBalance < deductionAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("❌ لا يوجد لديك رصيد كافٍ لأخذ هذا الطلب!")),
        );
        return;
      }

      // ✅ **تحديث رصيد السائق بعد الخصم**
      double newBalance = driverBalance - deductionAmount;
      await _firestore.collection('admin_drivers').doc(uid).update({
        'balance': newBalance,
      });

      // ✅ **تحديث بيانات الطلب وإضافة معرف السائق**
      orderData['driverId'] = uid;

      // 🏪 **إضافة الطلب إلى قائمة طلبات المطعم**
      if (orderData.containsKey('restaurantId')) {
        await _firestore
            .collection('restaurants')
            .doc(orderData['restaurantId'])
            .collection('orders')
            .doc(order.id)
            .set(orderData);
      }

      // 🚗 **إضافة الطلب إلى طلبات السائق**
      await _firestore
          .collection('my_orders')
          .doc(uid)
          .collection('orders')
          .doc(order.id)
          .set(orderData);

      // 🗑 **حذف الطلب من القائمة العامة بعد أخذه**
      await _firestore.collection('orders').doc(order.id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "✅ تم أخذ الطلب بنجاح! ✅\n💰 تم خصم $deductionAmount JD من رصيدك.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ خطأ: $e")),
      );
    }
  }

  /// 🔹 **نافذة تأكيد أخذ الطلب**
  Future<bool> _showConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("تأكيد أخذ الطلب"),
            content: const Text("هل أنت متأكد أنك تريد أخذ هذا الطلب؟"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("إلغاء"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("تأكيد"),
              ),
            ],
          ),
        ) ??
        false;
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
