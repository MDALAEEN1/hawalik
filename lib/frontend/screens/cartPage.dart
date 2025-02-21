import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hawalik/assets/widgets/const.dart';
import 'package:hawalik/frontend/screens/OrderConfirmationPage.dart';
import 'package:hawalik/frontend/widgets/customcart.dart';

class CartPage extends StatefulWidget {
  final String restaurantId; // معرّف المطعم

  const CartPage({super.key, required this.restaurantId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kbackground,
      appBar: AppBar(
        backgroundColor: kapp,
        title: const Text(
          "YOUR CART",
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .collection('cart')
            .where('restaurantId',
                isEqualTo:
                    widget.restaurantId) // جلب المنتجات الخاصة بالمطعم فقط
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(
              child: Text(
                "Your cart is empty",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            );
          }

          double totalAmount = 0.0;
          List<Map<String, dynamic>> cartItems = [];

          for (var product in products) {
            final Map<String, dynamic> productData =
                product.data() as Map<String, dynamic>;

            final priceString = productData['productPrice'] ?? "0";
            final price = double.tryParse(priceString.toString()) ?? 0.0;
            final quantity = productData.containsKey('quantity')
                ? productData['quantity'] as int
                : 1;

            totalAmount += price * quantity;

            // إضافة المنتج إلى قائمة المنتجات
            cartItems.add({
              'productId': product.id,
              'productName': productData['productName'] ?? "Unknown",
              'productPrice': price,
              'quantity': quantity,
              'productImage': productData['productImage'] ?? "",
            });
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final Map<String, dynamic> productData =
                        product.data() as Map<String, dynamic>;

                    final productId = product.id;
                    final productName = productData['productName'] ?? "Unknown";
                    final priceString = productData['productPrice'] ?? "0";
                    final productPrice =
                        double.tryParse(priceString.toString()) ?? 0.0;
                    final quantity = productData.containsKey('quantity')
                        ? productData['quantity'] as int
                        : 1;
                    final productImage = productData['productImage'] ?? "";

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomCart(
                              massageText: productName,
                              massagePrice: productPrice,
                              quantity: quantity,
                              imageUrl: productImage,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Confirm Delete"),
                                    content: const Text(
                                        "Are you sure you want to delete this product?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm == true) {
                                await _firestore
                                    .collection('users')
                                    .doc(_auth.currentUser?.uid)
                                    .collection('cart')
                                    .doc(productId)
                                    .delete();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total: \$${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(kapp)),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => OrderConfirmationPage(
                                    totalAmount: totalAmount,
                                    restaurantId: widget.restaurantId,
                                    cartItems:
                                        cartItems, // إرسال قائمة المنتجات
                                  )),
                        );

                        // بعد تأكيد الطلب، حذف جميع المنتجات الخاصة بالمطعم من السلة
                      },
                      child: const Text(
                        'Confirm Order',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
