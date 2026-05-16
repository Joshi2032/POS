import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String changeValue;
  final IconData icon;
  final bool isPositive;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.changeValue,
    required this.icon,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    // Leemos los colores del tema actual del contexto
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = Theme.of(context).cardTheme.color ?? 
        (isDark ? const Color(0xFF231F1F) : Colors.white);
    
    // El color de acento según la tendencia
    final trendColor = isPositive 
        ? Colors.green 
        : Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                ),
              ),
              Icon(
                icon, 
                color: Theme.of(context).primaryColor, 
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: trendColor,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                changeValue,
                style: TextStyle(
                  color: trendColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'vs periodo anterior',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}