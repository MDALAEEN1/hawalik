import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String driverName = "غير معين";
  String driverPhone = "غير متوفر";
  String orderStatus = "قيد المراجعة";
  double deliveryFee = 0.0;
  double totalAmount = 0.0;
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // جلب الطلب النشط لهذا المستخدم
    QuerySnapshot orderSnapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (orderSnapshot.docs.isNotEmpty) {
      var orderData = orderSnapshot.docs.first.data() as Map<String, dynamic>;

      setState(() {
        totalAmount = orderData['totalAmount'] ?? 0.0;
        deliveryFee = orderData['deliveryFee'] ?? 0.0;
        orderStatus = orderData['status'] ?? "قيد المراجعة";
        cartItems =
            List<Map<String, dynamic>>.from(orderData['products'] ?? []);

        if (orderData.containsKey('driverId')) {
          _loadDriverData(orderData['driverId']);
        }
      });
    }
  }

  Future<void> _loadDriverData(String driverId) async {
    DocumentSnapshot driverDoc =
        await _firestore.collection('drivers').doc(driverId).get();

    if (driverDoc.exists) {
      setState(() {
        driverName = driverDoc['name'] ?? "غير معروف";
        driverPhone = driverDoc['phone'] ?? "غير متوفر";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double finalAmount = totalAmount + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("🛒 سلة المشتريات",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ معلومات السائق
            _buildDriverInfo(),
            const SizedBox(height: 15),
            // ✅ تفاصيل الطلب
            _buildOrderDetails(finalAmount),
            const SizedBox(height: 15),
            // ✅ قائمة المنتجات
            Expanded(child: _buildCartItemsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfo() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.blue, size: 30),
        title: Text("🚗 اسم السائق: $driverName",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text("📞 رقم الهاتف: $driverPhone",
            style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildOrderDetails(double finalAmount) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("💰 المبلغ الإجمالي: JD${totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18)),
            Text("🚚 رسوم التوصيل: JD${deliveryFee.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const Divider(),
            Text("📦 إجمالي الدفع: JD${finalAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            const SizedBox(height: 10),
            Text("🔄 حالة الطلب: $orderStatus",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsList() {
    return cartItems.isEmpty
        ? const Center(
            child: Text("🛒 لا توجد منتجات في السلة حالياً",
                style: TextStyle(fontSize: 18, color: Colors.grey)))
        : ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              var item = cartItems[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.fastfood,
                      color: Colors.orange, size: 30),
                  title: Text(item['productName'] ?? "منتج غير معروف",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "💵 السعر: JD${item['productPrice']?.toStringAsFixed(2) ?? 'غير متوفر'}",
                      style: const TextStyle(fontSize: 16)),
                  trailing: Text("🔢 العدد: ${item['quantity']}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
  }
}
