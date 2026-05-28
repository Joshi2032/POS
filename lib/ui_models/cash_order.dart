// lib/models/cash_order.dart
import 'cash_item.dart';

class CashOrder {
  final String id;
  final String label;
  final String time;
  final String status;
  final int itemsCount;
  final List<CashItem> items;
  final double total;

  CashOrder({
    required this.id, 
    required this.label, 
    required this.time, 
    required this.status, 
    required this.itemsCount, 
    required this.items, 
    required this.total,
  });
}