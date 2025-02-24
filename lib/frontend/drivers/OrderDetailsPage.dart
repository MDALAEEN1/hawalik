import 'package:flutter/material.dart';
import 'package:hawalik/assets/widgets/const.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔹 استيراد Firestore
import 'package:firebase_auth/firebase_auth.dart';

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailsPage({super.key, required this.orderData});

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  String restaurantName = "جارِ التحميل..."; // 🔹 اسم المطعم الافتراضي
  String getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
    _fetchRestaurantName();
  }

  /// 🔹 جلب اسم المطعم باستخدام restaurantId من Firestore
  Future<void> _fetchRestaurantName() async {
    String restaurantId = widget.orderData['restaurantId'] ?? '';
    if (restaurantId.isNotEmpty) {
      try {
        DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
            .collection('restaurants') // 🔹 اسم مجموعة المطاعم في Firestore
            .doc(restaurantId)
            .get();

        if (restaurantDoc.exists) {
          setState(() {
            restaurantName = restaurantDoc['name'] ?? 'غير متوفر';
          });
        } else {
          setState(() {
            restaurantName = 'غير متوفر';
          });
        }
      } catch (e) {
        setState(() {
          restaurantName = 'خطأ في التحميل';
        });
        debugPrint("❌ خطأ في جلب اسم المطعم: $e");
      }
    }
  }

  Future<void> _markAsDelivered() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text("هل أنت متأكد أنك تريد حذف هذا الطلب؟"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // ❌ إلغاء
              child: const Text("إلغاء"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // ✅ تأكيد
              child: const Text("حذف"),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception("❌ لا يوجد مستخدم مسجل!");
        }

        String? orderId = widget.orderData['orderId']; // 🔹 استخدم String?

        if (orderId == null || orderId.isEmpty) {
          throw Exception("❌ رقم الطلب غير موجود!");
        }

        await FirebaseFirestore.instance
            .collection('my_orders')
            .doc(user.uid)
            .collection("orders")
            .doc(orderId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم تسليم الطلب وحذفه بنجاح")),
        );

        Navigator.pop(context);
      } catch (e) {
        debugPrint("❌ خطأ في حذف الطلب: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ أثناء حذف الطلب")),
        );
      }
    }
  }

  void _openMap(double lat, double lng) async {
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      debugPrint("❌ لا يمكن فتح الخريطة");
    }
  }

  void _callPhoneNumber(String phoneNumber) async {
    final url = "tel:$phoneNumber";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      debugPrint("❌ لا يمكن إجراء المكالمة");
    }
  }

  @override
  Widget build(BuildContext context) {
    double? latitude = widget.orderData['userLocation']?['latitude'];
    double? longitude = widget.orderData['userLocation']?['longitude'];
    double totalAmount = widget.orderData['totalAmount'] ?? 0.0;
    double deliveryFee = widget.orderData['deliveryFee'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("تفاصيل الطلب"),
        backgroundColor: kapp,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDeliveryInfo(latitude, longitude),
            const SizedBox(height: 10),
            _buildProductList(
                widget.orderData['products'] as List<dynamic>? ?? []),
            ElevatedButton(
              onPressed: _markAsDelivered,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("✅ تم التسليم",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("💰 المجموع: JD${totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text("🚚 التوصيل: JD${deliveryFee.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(double? latitude, double? longitude) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                "📌 رقم الطلب", widget.orderData['orderId'] ?? 'غير متوفر'),
            _buildInfoRow("🏠 اسم المطعم",
                restaurantName), // 🔹 عرض اسم المطعم بعد التحميل
            _buildInfoRow(
                "👤 اسم المستلم", widget.orderData['userName'] ?? 'غير متوفر'),
            _buildInfoRow(
                "📞 رقم الهاتف", widget.orderData['userPhone'] ?? 'غير متوفر',
                isPhone: true),
            _buildInfoRow("📍 الموقع",
                widget.orderData['userLocation']?['address'] ?? 'غير محدد'),
            if (latitude != null && longitude != null)
              TextButton(
                onPressed: () => _openMap(latitude, longitude),
                child: const Text("🔍 عرض الموقع على الخريطة",
                    style: TextStyle(color: Colors.blue)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<dynamic> products) {
    return Expanded(
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("🛍️ المنتجات المطلوبة:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    var item = products[index];
                    return ListTile(
                      title: Text(item['productName'] ?? 'منتج غير معروف'),
                      subtitle: Text("الكمية: ${item['quantity'] ?? 1}"),
                      trailing: Text(
                          "JD${item['productPrice']?.toStringAsFixed(2) ?? '0.00'}"),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          isPhone
              ? GestureDetector(
                  onTap: () => _callPhoneNumber(value),
                  child: Text(value,
                      style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline)),
                )
              : Text(value),
        ],
      ),
    );
  }
}
