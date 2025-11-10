import 'dart:async'; // 1. ADD THIS (for StreamSubscription)
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 2. ADD THIS
import 'package:cloud_firestore/cloud_firestore.dart'; // 3. ADD THIS

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  // 1. ADD THIS: A method to convert our CartItem object into a Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  // 2. ADD THIS: A factory constructor to create a CartItem from a Map
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      quantity: json['quantity'],
    );
  }
}

class CartProvider with ChangeNotifier {

  // 4. Change this: _items is no longer final
  List<CartItem> _items = [];

  // 5. ADD THESE: New properties for auth and database
  String? _userId; // Will hold the current user's ID
  StreamSubscription? _authSubscription; // To listen to auth changes

  // 6. ADD THESE: Get Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CartItem> get items => [..._items];

  double get totalPrice {
    return _items.fold(0.0, (total, item) => total + (item.price * item.quantity));
  }

  int get itemCount => _items.length;

  // 7. ADD THIS CONSTRUCTOR
  CartProvider() {
    // Listen to authentication changes
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // User is logged out
        _userId = null;
        _items = []; // Clear local cart
      } else {
        // User is logged in
        _userId = user.uid;
        _fetchCart(); // Load their cart from Firestore
      }
      // Notify listeners to update UI (e.g., clear cart badge on logout)
      notifyListeners();
    });
  }

  // 8. ADD THIS: Fetches the cart from Firestore
  Future<void> _fetchCart() async {
    if (_userId == null) return; // Not logged in, nothing to fetch

    try {
      // 1. Get the user's specific cart document
      final doc = await _firestore.collection('userCarts').doc(_userId).get();

      if (doc.exists && doc.data()!['cartItems'] != null) {
        // 2. Get the list of items from the document
        final List<dynamic> cartData = doc.data()!['cartItems'];

        // 3. Convert that list of Maps into our List<CartItem>
        //    (This is why we made CartItem.fromJson!)
        _items = cartData.map((item) => CartItem.fromJson(item)).toList();
      } else {
        // 4. The user has no saved cart, start with an empty one
        _items = [];
      }
    } catch (e) {
      _items = []; // On error, default to an empty cart
    }
    notifyListeners(); // Update the UI
  }

  // 9. ADD THIS: Saves the current local cart to Firestore
  Future<void> _saveCart() async {
    if (_userId == null) return; // Not logged in, nowhere to save

    try {
      // 1. Convert our List<CartItem> into a List<Map>
      //    (This is why we made toJson()!)
      final List<Map<String, dynamic>> cartData =
          _items.map((item) => item.toJson()).toList();

      // 2. Find the user's document and set the 'cartItems' field
      await _firestore.collection('userCarts').doc(_userId).set({
        'cartItems': cartData,
      });
    } catch (e) {
      // Handle error silently in production
    }
  }

  void addItem(String id, String name, double price) {
    var index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(id: id, name: name, price: price));
    }

    _saveCart(); // 10. ADD THIS LINE
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);

    _saveCart(); // 11. ADD THIS LINE
    notifyListeners();
  }

  // 1. ADD THIS: Creates an order in the 'orders' collection
  Future<void> placeOrder() async {
    // 2. Check if we have a user and items
    if (_userId == null || _items.isEmpty) {
      // Don't place an order if cart is empty or user is logged out
      throw Exception('Cart is empty or user is not logged in.');
    }

    try {
      // 3. Convert our List<CartItem> to a List<Map> using toJson()
      final List<Map<String, dynamic>> cartData =
          _items.map((item) => item.toJson()).toList();

      // 4. Get total price and item count from our getters
      final double total = totalPrice;
      final int count = itemCount;

      // 5. Create a new document in the 'orders' collection
      await _firestore.collection('orders').add({
        'userId': _userId,
        'items': cartData, // Our list of item maps
        'totalPrice': total,
        'itemCount': count,
        'status': 'Pending', // 6. IMPORTANT: For admin verification
        'createdAt': FieldValue.serverTimestamp(), // For sorting
      });

      // 7. Note: We DO NOT clear the cart here.
      //    We'll call clearCart() separately from the UI after this succeeds.

    } catch (e) {
      debugPrint('Error placing order: $e');
      // 8. Re-throw the error so the UI can catch it
      rethrow;
    }
  }

  // 9. ADD THIS: Clears the cart locally AND in Firestore
  Future<void> clearCart() async {
    // 10. Clear the local list
    _items = [];

    // 11. If logged in, clear the Firestore cart as well
    if (_userId != null) {
      try {
        // 12. Set the 'cartItems' field in their cart doc to an empty list
        await _firestore.collection('userCarts').doc(_userId).set({
          'cartItems': [],
        });
        debugPrint('Firestore cart cleared.');
      } catch (e) {
        debugPrint('Error clearing Firestore cart: $e');
      }
    }

    // 13. Notify all listeners (this will clear the UI)
    notifyListeners();
  }

  // 12. ADD THIS METHOD (or update it if it exists)
  @override
  void dispose() {
    _authSubscription?.cancel(); // Cancel the auth listener
    super.dispose();
  }
}
