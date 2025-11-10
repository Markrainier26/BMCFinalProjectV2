import 'package:ecommers_app/widgets/product_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommers_app/screens/admin_panel_screen.dart';
import 'package:ecommers_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:ecommers_app/screens/cart_screen.dart'; // 2. ADD THIS
import 'package:provider/provider.dart'; // 3. ADD THIS
import 'package:ecommers_app/screens/order_history_screen.dart'; // 1. ADD THIS



// Converted to StatefulWidget to fetch and store user's role
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. A state variable to hold the user's role. Default to 'user'.
  String _userRole = 'user';
  // 2. Get the current user from Firebase Auth
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // 3. This function runs ONCE when the screen is first created
  @override
  void initState() {
    super.initState();
    // 4. Call our function to get the role as soon as the screen loads
    _fetchUserRole();
  }

  // 5. This is our new function to get data from Firestore
  Future<void> _fetchUserRole() async {
    // 6. If no one is logged in, do nothing
    if (_currentUser == null) return;
    try {
      // 7. Go to the 'users' collection, find the document
      //    matching the current user's ID
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      // 8. If the document exists...
      if (doc.exists && doc.data() != null) {
        // 9. ...call setState() to save the role to our variable
        setState(() {
          final data = doc.data()!;
          _userRole = (data['role'] is String) ? data['role'] as String : 'user';
        });
      }
    } catch (e) {
      // If there's an error, they'll just keep the 'user' role
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching user role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 10. Move the _signOut function inside this class
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 1. Use the _currentUser variable we defined
        title: Text(_currentUser != null ? 'Welcome, ${_currentUser.email}' : 'Home'),
        actions: [

          // 1. --- ADD THIS NEW WIDGET ---
          // This is a special, efficient way to use Provider
          Consumer<CartProvider>(
            // 2. The "builder" function rebuilds *only* the icon
            builder: (context, cart, child) {
              // 3. Custom badge implementation using Stack
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      // 4. Navigate to the CartScreen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  // 5. Only show the badge if the count is > 0
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cart.itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // 2. --- ADD THIS NEW BUTTON ---
          IconButton(
            icon: const Icon(Icons.receipt_long), // A "receipt" icon
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),

          // 3. --- THIS IS THE MAGIC ---
          //    This is a "collection-if". The IconButton will only
          //    be built IF _userRole is equal to 'admin'.
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),

          // 5. The logout button (always visible)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _signOut, // 6. Call our _signOut function
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 2. This is our query to Firestore
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true) // 3. Show newest first
            .snapshots(),
        
        builder: (context, snapshot) {
          // 5. STATE 1: While data is loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 6. STATE 2: If an error occurs
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 7. STATE 3: If there's no data (or no products)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found. Add some in the Admin Panel!'),
            );
          }

          // 8. STATE 4: We have data!
          final products = snapshot.data!.docs;

          // 9. Use GridView.builder for a 2-column grid
          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              // 1. Get the whole document
              final productDoc = products[index];
              // 2. Get the data map
              final productData = productDoc.data() as Map<String, dynamic>;
              
              return ProductCard(
                productName: productData['name'] ?? 'Unknown Product',
                price: (productData['price'] as num?)?.toDouble() ?? 0.0,
                imageUrl: productData['imageUrl'] ?? '',
                productData: productData,
                productId: productDoc.id,
              );
            },
          );
        },
      ),
    );
  }
}

