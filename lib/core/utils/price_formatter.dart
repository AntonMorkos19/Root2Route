class PriceFormatter {
  static String format(dynamic rawPrice) {
    if (rawPrice == null) return '0';
    double price = double.tryParse(rawPrice.toString()) ?? 0.0;
    
    // 1. Determine if it's a whole number
    bool isWhole = price == price.truncateToDouble();
    
    // 2. Convert to string (remove decimals if whole)
    String priceString = isWhole ? price.toInt().toString() : price.toString();
    
    // 3. Split into integer and decimal parts
    List<String> parts = priceString.split('.');
    String integerPart = parts[0];
    
    // 4. Add commas to the integer part using RegExp
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formattedInteger = integerPart.replaceAllMapped(reg, (Match match) => '${match[1]},');
    
    // 5. Rejoin and return
    if (parts.length > 1) {
      return '$formattedInteger.${parts[1]}';
    } else {
      return formattedInteger;
    }
  }
}
