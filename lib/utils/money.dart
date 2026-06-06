/// Formats a dollar amount with two decimals, e.g. 1234.5 -> "$1234.50".
/// Kept in one place so every screen formats money the same way.
String formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

