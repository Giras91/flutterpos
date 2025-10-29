import 'product.dart';
import 'modifier_item_model.dart';

class CartItem {
  final Product product;
  int quantity;
  final List<ModifierItem> modifiers;
  final double priceAdjustment;

  CartItem(
    this.product,
    this.quantity, {
    this.modifiers = const [],
    this.priceAdjustment = 0.0,
  });

  /// Get the final price including modifiers
  double get finalPrice => product.price + priceAdjustment;

  /// Get the total price for this cart item (price * quantity)
  double get totalPrice => finalPrice * quantity;

  /// Get a display string for selected modifiers
  String getModifiersDisplay() {
    if (modifiers.isEmpty) return '';
    return modifiers.map((m) => m.name).join(', ');
  }

  /// Check if this cart item has the same product and modifiers as another
  bool hasSameConfiguration(Product otherProduct, List<ModifierItem> otherModifiers) {
    if (product.name != otherProduct.name) return false;
    if (modifiers.length != otherModifiers.length) return false;
    
    // Check if all modifier IDs match
    final thisModifierIds = modifiers.map((m) => m.id).toSet();
    final otherModifierIds = otherModifiers.map((m) => m.id).toSet();
    return thisModifierIds.difference(otherModifierIds).isEmpty &&
           otherModifierIds.difference(thisModifierIds).isEmpty;
  }
}
