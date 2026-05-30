/// Utility class to format and clean phone numbers for Pakistani networks (Jazz, Zong, Telenor, Ufone).
class PhoneNumberFormatter {
  /// Clean and format a phone number into the standard local Pakistani format (e.g., 03033497913).
  ///
  /// Handles:
  /// - "+92 303 3497913" -> "03033497913"
  /// - "923033497913" -> "03033497913"
  /// - "00923033497913" -> "03033497913"
  /// - "3033497913" -> "03033497913"
  /// - "0303-3497913" -> "03033497913"
  static String format(String input) {
    // 1. Remove all non-digit characters
    String digits = input.replaceAll(RegExp(r'\D'), '');

    // 2. If it starts with 0092, replace 0092 with 0 (e.g. 00923033497913 -> 03033497913)
    if (digits.startsWith('0092')) {
      digits = '0' + digits.substring(4);
    }
    // 3. If it starts with 92 and is 12 digits long (e.g., 923033497913), replace 92 with 0
    else if (digits.startsWith('92') && digits.length == 12) {
      digits = '0' + digits.substring(2);
    }
    // 4. If it starts with 3 and is 10 digits long (e.g., 3033497913), prepend 0
    else if (digits.startsWith('3') && digits.length == 10) {
      digits = '0' + digits;
    }

    // 5. Check if it fits the standard 11-digit mobile number format starting with 03
    if (digits.length == 11 && digits.startsWith('03')) {
      return digits;
    }

    // If it doesn't match standard patterns, return the cleaned digits or original input
    return digits.isNotEmpty ? digits : input.trim();
  }

  /// Validation check to see if a phone number is a valid Pakistani mobile number.
  static bool isValidPakistaniNumber(String number) {
    final formatted = format(number);
    final regExp = RegExp(r'^03[0-9]{9}$');
    return regExp.hasMatch(formatted);
  }
}
