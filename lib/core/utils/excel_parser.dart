import 'package:excel/excel.dart';
import '../../features/sms_sender/domain/models/contact_model.dart';
import 'phone_number_formatter.dart';

/// Service to parse contacts and custom fields from local Excel (.xlsx) files.
class ExcelParser {
  /// Parses Excel file bytes and returns a list of [Contact] objects.
  static List<Contact> parse(List<int> bytes) {
    final List<Contact> contacts = [];
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) return [];

    // Use the first sheet in the Excel file
    final sheetName = excel.tables.keys.first;
    final table = excel.tables[sheetName];
    if (table == null || table.rows.isEmpty) return [];

    final rows = table.rows;
    if (rows.isEmpty) return [];

    // 1. Parse headers from the first row
    final headerRow = rows.first;
    final List<String> headers = [];
    for (int colIndex = 0; colIndex < headerRow.length; colIndex++) {
      final cell = headerRow[colIndex];
      final val = _getStringValue(cell);
      headers.add(val.isNotEmpty ? val.trim() : 'Column_${colIndex + 1}');
    }

    // 2. Identify the phone number column (default to index 0 / Column A)
    int phoneColIndex = 0;
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase();
      if (h.contains('phone') ||
          h.contains('number') ||
          h.contains('mobile') ||
          h.contains('contact') ||
          h.contains('cell') ||
          h.contains('num')) {
        phoneColIndex = i;
        break;
      }
    }

    // 3. Parse data rows
    for (int rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.isEmpty) continue;

      // Extract raw phone number
      final rawPhoneCell = phoneColIndex < row.length ? row[phoneColIndex] : null;
      final rawPhone = _getStringValue(rawPhoneCell);
      if (rawPhone.isEmpty) continue;

      // Clean and validate Pakistani number format
      final formattedPhone = PhoneNumberFormatter.format(rawPhone);
      if (formattedPhone.isEmpty) continue;

      // Build mapping of other columns (dynamic placeholders)
      final Map<String, String> dynamicFields = {};
      String displayName = 'Valued Customer';

      for (int colIndex = 0; colIndex < row.length; colIndex++) {
        if (colIndex == phoneColIndex) continue; // Skip phone column in dynamic fields

        final cell = row[colIndex];
        final cellValue = _getStringValue(cell);
        final headerName = colIndex < headers.length ? headers[colIndex] : 'Column_${colIndex + 1}';

        dynamicFields[headerName] = cellValue;

        // Try to identify a name field to use as display name
        final lowerHeader = headerName.toLowerCase();
        if (lowerHeader == 'name' || lowerHeader.contains('customer') || lowerHeader.contains('recipient')) {
          displayName = cellValue;
        }
      }

      contacts.add(Contact(
        phoneNumber: formattedPhone,
        displayName: displayName,
        dynamicFields: dynamicFields,
      ));
    }

    return contacts;
  }

  /// Helper to extract string content safely from excel library's Data? type.
  static String _getStringValue(dynamic cell) {
    if (cell == null) return '';
    
    // In newer excel versions, cells are wrapped in a Data class
    // we fetch its value property.
    dynamic val;
    try {
      val = cell.value;
    } catch (_) {
      val = cell;
    }

    if (val == null) return '';
    return val.toString();
  }
}
