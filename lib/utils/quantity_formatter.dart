class QuantityFormatter {
static String format(double? qty, String? unit) {
    if (qty == null) return '';
    final String lower = (unit ?? '').trim().toLowerCase();

    // ضفنا هنا 'كجم' و 'كيلوجرام'
    bool isKg =
        lower == 'kilogram' ||
        lower == 'kg' ||
        lower == 'كجم' ||
        lower == 'كيلوجرام';

    // Convert kg to ton
    if (isKg && qty >= 1000) {
      final double tons = qty / 1000;
      final String tonsDisplay =
          tons % 1 == 0 ? tons.toInt().toString() : tons.toStringAsFixed(1);
      return '$tonsDisplay طن';
    }

    // ضفنا هنا 'جم' و 'جرام'
    bool isGram =
        lower == 'gram' || lower == 'g' || lower == 'جم' || lower == 'جرام';

    // Convert gram to kg
    if (isGram && qty >= 1000) {
      final double kg = qty / 1000;
      final String kgDisplay =
          kg % 1 == 0 ? kg.toInt().toString() : kg.toStringAsFixed(1);
      return '$kgDisplay كيلوجرام';
    }

    // Default formatting
    final String qtyDisplay =
        qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return '$qtyDisplay ${_toArabicUnit(unit)}'.trim();
  }



static String _toArabicUnit(String? unit) {
    if (unit == null) return '';
    final String lower = unit.trim().toLowerCase();
    switch (lower) {
      case 'kg':
      case 'kilogram':
        return 'كيلوجرام';
      case 'ton':
        return 'طن';
      case 'g':
      case 'gram':
        return 'جرام';
      case 'l':
      case 'liter':
        return 'لتر';
      case 'meter':
      case 'm':
        return 'متر';
      case 'mm':
        return 'مليمتر';
      case 'cm':
        return 'سنتيمتر';
      case 'inch':
        return 'إنش';
      case 'piece':
      case 'pcs':
      case 'pc':
        return 'قطعة';
      case 'pack':
      case 'pacs':
      case 'package':
        return 'عبوة';
      case 'lot':
        return 'بلوك';
      default:
        return unit;
    }
  }
}
