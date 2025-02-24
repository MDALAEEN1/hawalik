import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hawalik/frontend/screens/ProductDetailsPage.dart'; // Ensure the import is correct

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  @override
  Widget build(BuildContext context) {
    final routeArgument =
        ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;
    final String category =
        routeArgument?['category'] as String? ?? 'HOT DRINK';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: Text("$category"),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('restaurants').snapshots(),
          builder: (context, restaurantSnapshot) {
            if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (restaurantSnapshot.hasError) {
              return Center(
                  child: Text("حدث خطأ: ${restaurantSnapshot.error}"));
            }
            if (!restaurantSnapshot.hasData ||
                restaurantSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("لا توجد مطاعم متاحة"));
            }

            final restaurantDocs = restaurantSnapshot.data!.docs;

            return ListView.builder(
              itemCount: restaurantDocs.length,
              itemBuilder: (context, index) {
                final restaurant = restaurantDocs[index];
                final restaurantId = restaurant.id;
                final restaurantName = restaurant['name'] ?? "مطعم مجهول";

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .collection('menu')
                      .where('category', isEqualTo: category)
                      .snapshots(),
                  builder: (context, menuSnapshot) {
                    if (!menuSnapshot.hasData ||
                        menuSnapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    final menuDocs = menuSnapshot.data!.docs;

                    return Column(
                      children: menuDocs.map((product) {
                        final productName = product['name'] ?? 'بدون اسم';
                        final productPrice =
                            product['price']?.toString() ?? '0.0';
                        final imageUrl = product['imageUrl'] ?? '';
                        final productDescription =
                            product['description'] ?? 'لا يوجد وصف';
                        final ingredients =
                            List<String>.from(product['ingredients'] ?? []);

                        return GestureDetector(
                          key: ValueKey(
                              product.id), // Unique key for each product
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsPage(
                                  productName: productName,
                                  productDescription: productDescription,
                                  productPrice: productPrice,
                                  productImage: imageUrl,
                                  ingredients: ingredients,
                                  restaurantId: restaurantId,
                                  restaurant:
                                      restaurant.data() as Map<String, dynamic>,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 10.0),
                            child: Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Container(
                                height: 120,
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(imageUrl,
                                              width: 100,
                                              height: double.infinity,
                                              fit: BoxFit.cover)
                                          : const Icon(
                                              Icons.image_not_supported,
                                              size: 100,
                                              color: Colors.grey),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            productName,
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            productDescription,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "from $restaurantName",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "$productPrice \JD",
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
                                    SizedBox(
                                      width: 20,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
