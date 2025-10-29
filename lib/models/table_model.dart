import 'cart_item.dart';

enum TableStatus {
  available,
  occupied,
  reserved,
}

class RestaurantTable {
  final String id;
  final String name;
  final int capacity;
  TableStatus status;
  List<CartItem> orders;
  DateTime? occupiedSince;
  String? customerName;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.capacity,
    this.status = TableStatus.available,
    List<CartItem>? orders,
    this.occupiedSince,
    this.customerName,
  }) : orders = orders ?? [];

  bool get isAvailable => status == TableStatus.available;
  bool get isOccupied => status == TableStatus.occupied;
  bool get isReserved => status == TableStatus.reserved;

  double get totalAmount {
    return orders.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  int get itemCount {
    return orders.fold(0, (sum, item) => sum + item.quantity);
  }

  void addOrder(CartItem item) {
    final existingIndex = orders.indexWhere((o) => o.product.name == item.product.name);
    if (existingIndex != -1) {
      orders[existingIndex].quantity += item.quantity;
    } else {
      orders.add(item);
    }
    if (status == TableStatus.available) {
      status = TableStatus.occupied;
      occupiedSince = DateTime.now();
    }
  }

  void clearOrders() {
    orders.clear();
    status = TableStatus.available;
    occupiedSince = null;
    customerName = null;
  }

  RestaurantTable copyWith({
    String? id,
    String? name,
    int? capacity,
    TableStatus? status,
    List<CartItem>? orders,
    DateTime? occupiedSince,
    String? customerName,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      orders: orders ?? List.from(this.orders),
      occupiedSince: occupiedSince ?? this.occupiedSince,
      customerName: customerName ?? this.customerName,
    );
  }
}
