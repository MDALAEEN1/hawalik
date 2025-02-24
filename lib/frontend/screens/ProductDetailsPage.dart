// ProductDetailsPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hawalik/frontend/screens/StorePage.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productName;
  final String productDescription;
  final String productPrice;
  final String productImage;
  final List<String> ingredients;
  final String restaurantId;
  final Map<String, dynamic> restaurant; // Add restaurant data

  const ProductDetailsPage({
    super.key,
    required this.productName,
    required this.productDescription,
    required this.productPrice,
    required this.productImage,
    required this.ingredients,
    required this.restaurantId,
    required this.restaurant, // Pass restaurant data
  });

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late List<String> selectedIngredients;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    selectedIngredients = List.from(widget.ingredients);
  }

  void _toggleIngredient(String ingredient) {
    setState(() {
      if (selectedIngredients.contains(ingredient)) {
        selectedIngredients.remove(ingredient);
      } else {
        selectedIngredients.add(ingredient);
      }
    });
  }

  void _incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void _addToCart() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك سجل دخولك أولاً')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .add({
        'productName': widget.productName,
        'productDescription': widget.productDescription,
        'productPrice': widget.productPrice,
        'productImage': widget.productImage,
        'ingredients': selectedIngredients,
        'quantity': quantity,
        'restaurantId': widget.restaurantId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.productName} تم إضافته إلى السلة')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إضافة المنتج: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => StorePage(
                  restaurantId: widget.restaurantId,
                  restaurant: widget.restaurant, // Pass restaurant data
                ),
              ),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.network(widget.productImage,
                    height: 400, fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              Text(
                widget.productName,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                widget.productDescription,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Text(
                "السعر: ${widget.productPrice} JD",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "الكمية:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.red),
                        onPressed: _decrementQuantity,
                      ),
                      Text(
                        "$quantity",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: _incrementQuantity,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "المكونات",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8.0,
                children: widget.ingredients.map((ingredient) {
                  final isSelected = selectedIngredients.contains(ingredient);
                  return ChoiceChip(
                    label: Text(ingredient),
                    selected: isSelected,
                    onSelected: (selected) => _toggleIngredient(ingredient),
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addToCart,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue),
                ),
                child: const Text("إضافة إلى السلة"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
