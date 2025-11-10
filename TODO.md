# TODO: Sync Cart with Firestore

- [x] Add toJson and fromJson methods to CartItem class
- [x] Add necessary imports (dart:async, firebase_auth, cloud_firestore)
- [x] Change _items to non-final in CartProvider
- [x] Add new properties to CartProvider (_userId, _authSubscription, _auth, _firestore)
- [x] Add constructor to CartProvider with auth listener
- [x] Add _fetchCart method to CartProvider
- [x] Add _saveCart method to CartProvider
- [x] Update addItem method to call _saveCart
- [x] Update removeItem method to use removeWhere and call _saveCart
- [x] Add dispose method to CartProvider
