/// Model representing an offline recipient imported from an Excel sheet.
class Contact {
  /// Standardized phone number (e.g., 03033497913)
  final String phoneNumber;

  /// Extracted name or default value
  final String displayName;

  /// Dynamic mapping of headers to cell values for templating (e.g. {"Amount": "1500"})
  final Map<String, String> dynamicFields;

  Contact({
    required this.phoneNumber,
    required this.displayName,
    required this.dynamicFields,
  });

  @override
  String toString() => 'Contact(phone: $phoneNumber, name: $displayName, fields: $dynamicFields)';
}
