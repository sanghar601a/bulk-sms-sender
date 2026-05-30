/// Model representing a logged SMS dispatch transaction.
/// Stored as a raw Map in Hive to bypass code-generation requirements.
class SmsLog {
  final DateTime timestamp;
  final String phoneNumber;
  final String status; // 'SUCCESS' or 'FAILED'
  final String message;
  final int simSlot; // 1 or 2

  SmsLog({
    required this.timestamp,
    required this.phoneNumber,
    required this.status,
    required this.message,
    required this.simSlot,
  });

  /// Convert object to JSON-compatible Map for Hive storage.
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'phoneNumber': phoneNumber,
      'status': status,
      'message': message,
      'simSlot': simSlot,
    };
  }

  /// Create object from JSON-compatible Map.
  factory SmsLog.fromMap(Map<dynamic, dynamic> map) {
    return SmsLog(
      timestamp: DateTime.parse(map['timestamp'] as String),
      phoneNumber: map['phoneNumber'] as String,
      status: map['status'] as String,
      message: map['message'] as String,
      simSlot: map['simSlot'] as int? ?? 1,
    );
  }
}
