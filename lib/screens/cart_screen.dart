import 'package:ecommers_app/providers/cart_provider.dart';
import 'package:ecommers_app/screens/order_success_screen.dart'; // 1. ADD THIS
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 2. Change this to a StatefulWidget
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  // 3. Create the State
  State<CartScreen> createState() => _CartScreenState();
}

// 4. Rename the class to _CartScreenState
class _CartScreenState extends State<CartScreen> {

  // 5. Add our loading state variable
  bool _isLoading = false;

  // 6. Move the build method inside here
  @override
  Widget build(BuildContext context) {
    // 1. Get the cart. This time, we *want* to listen (default)
    //    so this screen rebuilds when we remove an item.
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Column(
        children: [
          // 2. The list of items
          Expanded(
            // 3. If cart is empty, show a message
            child: cart.items.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final cartItem = cart.items[index];
                      // 4. A ListTile to show item details
                      return ListTile(
                        leading: CircleAvatar(
                          // Show a mini-image (or first letter)
                          child: Text(cartItem.name.isNotEmpty ? cartItem.name[0] : '?'),
                        ),
                        title: Text(cartItem.name),
                        subtitle: Text('Qty: ${cartItem.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 5. Total for this item
                            Text(
                              '₱${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}'),
                            // 6. Remove button
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.red),
                              tooltip: 'Decrease quantity or remove item',
                              onPressed: () {
                                // 7. Call the removeItem function
                                cart.removeItem(cartItem.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // 8. The Total Price Summary
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₱${cart.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 4. --- ADD THIS NEW BUTTON ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50), // Wide button
              ),

              // 5. Disable button if loading OR if cart is empty
              onPressed: (_isLoading || cart.items.isEmpty) ? null : () async {
                // 6. Start the loading spinner
                setState(() {
                  _isLoading = true;
                });

                try {
                  // 7. Get provider (listen: false is for functions)
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);

                  // 8. Call our new methods
                  await cartProvider.placeOrder();
                  await cartProvider.clearCart();

                  // 9. Navigate to success screen
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
                      (route) => false,
                    );
                  }

                } catch (e) {
                  // 10. Show error if placeOrder() fails
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to place order: $e')),
                    );
                  }
                } finally {
                  // 11. ALWAYS stop the spinner
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },

              // 12. Show spinner or text based on loading state
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Place Order'),
            ),
          ),
        ],
      ),
    );
  }
}
