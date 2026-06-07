class AppValidators {
  // 1. Email Validator
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(value.trim())) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  // 2. Egyptian Phone Number Validator
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    // Matches Egyptian numbers: exactly 11 digits starting with 010, 011, 012, or 015
    final phoneRegex = RegExp(r"^01[0125][0-9]{8}$"); 
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'رقم الهاتف غير صحيح (يجب أن يكون 11 رقماً ويبدأ بـ 01)';
    }
    return null;
  }

  // 3. Generic Required Field Validator
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    return null;
  }
}
