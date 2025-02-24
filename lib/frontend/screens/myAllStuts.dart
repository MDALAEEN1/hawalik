import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserOrdersPage extends StatefulWidget {
  @override
  _UserOrdersPageState createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> orderedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadUserOrders();
  }

  Future<void> _loadUserOrders() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    List<Map<String, dynamic>> tempOrders = [];

    // جلب جميع المطاعم
    QuerySnapshot restaurantSnapshot =
        await _firestore.collection('restaurants').get();

    for (var restaurant in restaurantSnapshot.docs) {
      String restaurantId = restaurant.id;

      // جلب جميع الطلبات الخاصة بالمستخدم في هذا المطعم
      QuerySnapshot orderSnapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      for (var order in orderSnapshot.docs) {
        var orderData = order.data() as Map<String, dynamic>;
        List<dynamic> products = orderData['products'] ?? [];
        String status = orderData['status'] ?? 'غير محدد';
        String driverId = orderData['driverId'] ?? '';
        double totalPrice = orderData['totalAmount'] ?? 0.0; // جلب السعر الكلي

        // جلب معلومات السائق من مجموعة admin_drivers
        var driverData = await _getDriverDetails(driverId);

        // إضافة الطلب مع جميع المنتجات ومعلومات السائق
        tempOrders.add({
          'restaurantName': restaurant['name'] ?? 'مطعم غير معروف',
          'orderStatus': status,
          'driverName': driverData['name'] ?? 'غير متوفر',
          'driverPhone': driverData['phone'] ?? 'غير متوفر',
          'totalPrice': totalPrice, // تخزين السعر الكلي
          'products': products,
          'isWaitingForDriver': status == 'غير محدد' ||
              driverId.isEmpty, // تحديد إذا كان في انتظار سائق
        });
      }
    }

    setState(() {
      orderedProducts = tempOrders;
    });
  }

  Future<Map<String, dynamic>> _getDriverDetails(String driverId) async {
    // البحث عن السائق في مجموعة admin_drivers باستخدام driverId
    DocumentSnapshot driverSnapshot =
        await _firestore.collection('admin_drivers').doc(driverId).get();

    if (driverSnapshot.exists) {
      return driverSnapshot.data() as Map<String, dynamic>;
    } else {
      return {'driverName': 'غير متوفر', 'driverPhone': 'غير متوفر'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("📦 جميع طلباتك",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: orderedProducts.isEmpty
          ? const Center(
              child: Text("📭 لا يوجد لديك طلبات سابقة",
                  style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
              itemCount: orderedProducts.length,
              itemBuilder: (context, index) {
                var order = orderedProducts[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عرض اسم المطعم وحالة الطلب
                        Text(
                          "🏠 المطعم: ${order['restaurantName']}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "📦 حالة الطلب: ${order['orderStatus']}",
                          style:
                              const TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                        const SizedBox(height: 10),

                        // عرض معلومات السائق
                        Text(
                          "🚗 اسم السائق: ${order['driverName']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "📞 رقم هاتف السائق: ${order['driverPhone']}",
                          style: const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 10),

                        // عرض السعر الكلي
                        Text(
                          "💵 السعر الكلي: JD${order['totalPrice']}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        // عرض رسالة في انتظار سائق إذا كانت الحالة تتطلب ذلك
                        if (order['isWaitingForDriver'])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "⏳ الطلب في انتظار سائق",
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.orange),
                            ),
                          ),

                        const SizedBox(height: 10),
                        // عرض المنتجات في هذا الطلب
                        ...order['products'].map<Widget>((product) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "🍔 المنتج: ${product['productName'] ?? 'منتج غير معروف'}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "💵 السعر: JD${product['productPrice'] ?? 0.0}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  "🔢 العدد: ${product['quantity'] ?? 1}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
