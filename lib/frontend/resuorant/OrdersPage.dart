import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrdersPage extends StatelessWidget {
  final String restaurantId;

  const OrdersPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text('الطلبات'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .collection('orders')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("🚀 لا يوجد طلبات حالياً"));
          }

          final orders = snapshot.data!.docs;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final orderData = orderDoc.data() as Map<String, dynamic>;

              // ✅ جلب بيانات الطلب
              final String customerName = orderData['userName'] ?? 'غير متوفر';
              final String customerPhone =
                  orderData['userPhone'] ?? 'غير متوفر';
              final String driverName = orderData['driverName'] ?? 'غير معين';
              final String driverPhone =
                  orderData['driverPhone'] ?? 'غير متوفر';
              final String deliveryLocation =
                  orderData['deliveryLocation'] ?? 'غير محدد';
              final List<dynamic> products = orderData['products'] ?? [];
              final String totalPrice = orderData['totalAmount'] != null
                  ? orderData['totalAmount'].toString()
                  : 'غير متوفر';
              final String orderStatus =
                  orderData['status'] ?? 'قيد التحضير'; // ✅ جلب حالة الطلب

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "👤 الزبون: $customerName",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text("📞 هاتف الزبون: $customerPhone"),
                      Text("📍 مكان التوصيل: $deliveryLocation"),
                      const SizedBox(height: 8),
                      const Divider(),
                      const Text(
                        "🛍 المنتجات المطلوبة:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: products.map((product) {
                          if (product is Map<String, dynamic>) {
                            final String name =
                                product['productName'] ?? 'غير معروف';
                            final double price =
                                (product['productPrice'] ?? 0).toDouble();
                            final int quantity =
                                (product['quantity'] ?? 1).toInt();

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                "🔹 $name - ${price.toStringAsFixed(2)} JD × $quantity",
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          }
                          return const Text("🔹 بيانات المنتج غير صحيحة");
                        }).toList(),
                      ),
                      const Divider(),
                      Text("🚗 السائق: $driverName"),
                      Text("📞 هاتف السائق: $driverPhone"),
                      const Divider(),
                      Text(
                        "📦 حالة الطلب: $orderStatus",
                        style: TextStyle(
                          fontSize: 16,
                          color: orderStatus == "جاهز للتوصيل"
                              ? Colors.green
                              : orderStatus == "قيد التوصيل"
                                  ? Colors.blue
                                  : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "💰 السعر الإجمالي: $totalPrice JD",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // ✅ زر "تم التجهيز" يظهر فقط إذا كان الطلب "قيد التحضير"
                              if (orderStatus == "قيد التحضير")
                                ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('restaurants')
                                        .doc(restaurantId)
                                        .collection('orders')
                                        .doc(orderDoc.id)
                                        .update({'status': 'جاهز للتوصيل'});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("✅ تم تجهيز الطلب!"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text("✅ تم التجهيز"),
                                ),

                              const SizedBox(width: 8),

                              // ✅ زر ديناميكي: "مع السائق" أو "حذف الطلب"
                              ElevatedButton(
                                onPressed: () async {
                                  if (orderStatus == "جاهز للتوصيل") {
                                    // ✅ تحديث الحالة إلى "قيد التوصيل"
                                    await FirebaseFirestore.instance
                                        .collection('restaurants')
                                        .doc(restaurantId)
                                        .collection('orders')
                                        .doc(orderDoc.id)
                                        .update({'status': 'قيد التوصيل'});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("📦 الطلب مع السائق!"),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  } else if (orderStatus == "قيد التوصيل") {
                                    // ✅ حذف الطلب بعد التأكيد
                                    bool confirmDelete = await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("🗑️ حذف الطلب"),
                                            content: const Text(
                                                "هل أنت متأكد أنك تريد حذف هذا الطلب؟"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text("إلغاء"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text(
                                                  "حذف",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                        false;

                                    if (confirmDelete) {
                                      await FirebaseFirestore.instance
                                          .collection('restaurants')
                                          .doc(restaurantId)
                                          .collection('orders')
                                          .doc(orderDoc.id)
                                          .delete();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text("🗑️ تم حذف الطلب!"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orderStatus == "جاهز للتوصيل"
                                      ? Colors.blue
                                      : Colors.red,
                                ),
                                child: Text(orderStatus == "جاهز للتوصيل"
                                    ? "📦 مع السائق"
                                    : "🗑️ حذف الطلب"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
