import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    try {
      return CartItem(
        id: json['id'] as String,
        name: json['name'] as String,
        quantity:
            json['quantity'] as int? ?? 1, // Default to 1 if quantity is null
        price: (json['price'] is int)
            ? (json['price'] as int).toDouble()
            : json['price'] as double,
        imageUrl: json['imageUrl'] as String,
      );
    } catch (e) {
      // print('Error creating CartItem from JSON: $e');
      // print('JSON data: $json');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'CartItem(id: $id, name: $name, quantity: $quantity, price: $price)';
  }
}

class CartProvider with ChangeNotifier {
  static const int maxQuantity = 999;
  String? _userId;
  Map<String, CartItem> _items = {};

  CartProvider() {
    // Don't load cart in constructor - wait for setUserId
  }

  Map<String, CartItem> get items => {..._items};
  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  Future<void> setUserId(String? userId) async {
    // print('Setting cart user ID: $userId (previous: $_userId)');

    try {
      if (_userId != userId) {
        // Save current cart data before switching user
        if (_userId != null && _items.isNotEmpty) {
          // print(
          //     'Saving cart for previous user: $_userId with ${_items.length} items');
          await saveCart();
        }

        _items = {};
        _userId = userId;

        if (userId != null) {
          await _loadCartFromPrefs();
        }

        notifyListeners();
      }
    } catch (e) {
      _items = {};
      notifyListeners();
    }
  }

  Future<void> _loadCartFromPrefs() async {
    if (_userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartKey = 'cart_${_userId}';
      final cartData = prefs.getString(cartKey);

      if (cartData != null && cartData.isNotEmpty) {
        try {
          final decodedData = json.decode(cartData) as Map<String, dynamic>;
          Map<String, CartItem> loadedItems = {};

          decodedData.forEach((key, value) {
            try {
              if (value is Map<String, dynamic>) {
                final cartItem = CartItem.fromJson(value);
                if (cartItem.quantity > 0) {
                  loadedItems[key] = cartItem;
                }
              }
            } catch (e) {
            }
          });

          // Merge loaded items with existing items
          _items.addAll(loadedItems);
          notifyListeners();
        } catch (e) {
        }
      }
    } catch (e) {
    }
  }

  Future<void> saveCart() async {
    if (_userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartKey = 'cart_${_userId}';

      // Convert cart items to JSON format
      final cartData = Map<String, dynamic>.fromEntries(
        _items.entries
            .map((entry) => MapEntry(entry.key, entry.value.toJson())),
      );

      final encodedData = json.encode(cartData);
      await prefs.setString(cartKey, encodedData);
    } catch (e) {
    }
  }

  void addItem(String productId, String name, double price, String imageUrl) {
    if (productId.isEmpty || _userId == null) {
      return;
    }

    if (name.isEmpty || price <= 0 || imageUrl.isEmpty) {
      return;
    }

    try {
      if (_items.containsKey(productId)) {
        // Update existing item's quantity
        final existingItem = _items[productId]!;
        if (existingItem.quantity < maxQuantity) {
          _items[productId] = CartItem(
            id: productId,
            name: existingItem.name,
            quantity: existingItem.quantity + 1,
            price: existingItem.price,
            imageUrl: existingItem.imageUrl,
          );
          saveCart();
          notifyListeners();
        }
      } else {
        // Add new item
        _items[productId] = CartItem(
          id: productId,
          name: name,
          quantity: 1,
          price: price,
          imageUrl: imageUrl,
        );
        saveCart();
        notifyListeners();
      }
    } catch (e) {
    }
  }

  void incrementQuantity(String productId) {
    // print('Incrementing quantity - ID: $productId, User: $_userId');
    // print('Current cart state before increment: ${_items.toString()}');

    if (productId.isEmpty || _userId == null) {
      // print('Cannot increment: productId is empty or no user is set');
      return;
    }

    if (_items.containsKey(productId)) {
      final item = _items[productId]!;
      if (item.quantity < maxQuantity) {
        _items[productId] = CartItem(
          id: productId,
          name: item.name,
          quantity: item.quantity + 1,
          price: item.price,
          imageUrl: item.imageUrl,
        );
        saveCart();
        notifyListeners();
      }
    }
  }

  void decrementQuantity(String productId) {
    // print('Decrementing quantity - ID: $productId, User: $_userId');

    if (productId.isEmpty || _userId == null) {
      // print('Cannot decrement: productId is empty or no user is set');
      return;
    }

    if (_items.containsKey(productId)) {
      final item = _items[productId]!;
      if (item.quantity > 1) {
        _items[productId] = CartItem(
          id: productId,
          name: item.name,
          quantity: item.quantity - 1,
          price: item.price,
          imageUrl: item.imageUrl,
        );
      } else {
        _items.remove(productId);
      }
      saveCart();
      notifyListeners();
      // print('Decremented quantity for item: $productId');
    }
  }

  void removeItem(String productId) {
    // print('Removing item from cart - ID: $productId, User: $_userId');

    if (productId.isEmpty || _userId == null) {
      // print('Cannot remove item: productId is empty or no user is set');
      return;
    }

    _items.remove(productId);
    saveCart();
    notifyListeners();
    // print('Removed item from cart. Total items: ${_items.length}');
  }

  void setQuantity(String productId, int quantity) {
    if (productId.isEmpty || _userId == null) return;
    if (!_items.containsKey(productId)) return;
    final item = _items[productId]!;
    final clamped = quantity.clamp(1, maxQuantity);
    _items[productId] = CartItem(
      id: productId,
      name: item.name,
      quantity: clamped,
      price: item.price,
      imageUrl: item.imageUrl,
    );
    saveCart();
    notifyListeners();
  }

  int getQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  void clear() {
    _items = {};
    saveCart();
    notifyListeners();
  }
}
