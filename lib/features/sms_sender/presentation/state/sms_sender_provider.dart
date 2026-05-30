import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:background_sms/background_sms.dart';
import 'package:hive/hive.dart';

import '../../../../core/utils/excel_parser.dart';
import '../../../../core/utils/phone_number_formatter.dart';
import '../../domain/models/contact_model.dart';
import '../../domain/models/sms_log_model.dart';

/// Manages the state of the bulk SMS sender, including file imports,
/// the async sending queue, logs, and SIM configurations.
class SmsSenderProvider extends ChangeNotifier {
  List<Contact> _contacts = [];
  List<String> _consoleLogs = [];
  List<SmsLog> _historyLogs = [];
  
  bool _isSending = false;
  int _currentIndex = 0;
  int _simSlot = 1; // 1 = SIM 1, 2 = SIM 2
  String _messageTemplate = "AoA [Name], your pending fee is Rs. [Amount].";
  String? _importedFileName;

  // Box to persist logs
  late Box _logBox;

  // Getters
  List<Contact> get contacts => _contacts;
  List<String> get consoleLogs => _consoleLogs;
  List<SmsLog> get historyLogs => _historyLogs;
  bool get isSending => _isSending;
  int get currentIndex => _currentIndex;
  int get simSlot => _simSlot;
  String get messageTemplate => _messageTemplate;
  String? get importedFileName => _importedFileName;

  SmsSenderProvider() {
    _initHive();
  }

  /// Initialize Hive box and load past logs
  Future<void> _initHive() async {
    _logBox = await Hive.openBox('sms_logs_box');
    _loadHistoryLogs();
    _addLog("[System] App started. Ready to load contacts.");
  }

  /// Load logs from local storage
  void _loadHistoryLogs() {
    final rawLogs = _logBox.values.toList();
    _historyLogs = rawLogs
        .map((e) => SmsLog.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
        .reversed
        .toList(); // Newest first
    notifyListeners();
  }

  /// Add log entry to screen console and Hive database
  void _addLog(String logText) {
    _consoleLogs.add(logText);
    // Limit console length to avoid memory leaks (keep last 500 lines)
    if (_consoleLogs.length > 500) {
      _consoleLogs.removeAt(0);
    }
    notifyListeners();
  }

  /// Update the active message template
  void updateTemplate(String val) {
    _messageTemplate = val;
    notifyListeners();
  }

  /// Update SIM selection
  void setSimSlot(int slot) {
    _simSlot = slot;
    _addLog("[SIM Changed] Selected SIM Slot: $_simSlot");
    notifyListeners();
  }

  /// Pick local Excel file, read and parse contacts offline
  Future<void> pickAndParseFile() async {
    if (_isSending) {
      _addLog("[Warning] Cannot import files while bulk sending is in progress.");
      return;
    }

    try {
      _addLog("[File Picker] Opening local files...");
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true, // Crucial for loading file bytes directly in memory
      );

      if (result == null || result.files.isEmpty) {
        _addLog("[File Picker] Cancelled by user.");
        return;
      }

      final file = result.files.first;
      _importedFileName = file.name;
      _addLog("[Parser] Reading '$_importedFileName'...");

      List<int> bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        final localFile = File(file.path!);
        bytes = await localFile.readAsBytes();
      } else {
        throw Exception("Could not read file data.");
      }

      // Run parser
      final parsed = ExcelParser.parse(bytes);
      if (parsed.isEmpty) {
        _addLog("[Error] No valid contact phone numbers found in '$_importedFileName'. Make sure phone numbers are in Column A or under a phone header.");
        return;
      }

      _contacts = parsed;
      _currentIndex = 0; // Reset progress
      _addLog("[Imported] ${_contacts.length} numbers ready for dispatch.");
      notifyListeners();
    } catch (e) {
      _addLog("[Error] Failed to parse file: $e");
    }
  }

  /// Clears the imported contacts queue
  void clearQueue() {
    if (_isSending) return;
    _contacts.clear();
    _currentIndex = 0;
    _importedFileName = null;
    _addLog("[System] Contact queue cleared.");
    notifyListeners();
  }

  /// Process templates by substituting placeholder tokens with contact specific details
  String compileTemplate(Contact contact) {
    String message = _messageTemplate;
    // Replace standard Name placeholder
    message = message.replaceAll('[Name]', contact.displayName);
    
    // Replace any custom headers mapped from secondary columns
    contact.dynamicFields.forEach((key, value) {
      message = message.replaceAll('[$key]', value);
    });

    return message;
  }

  /// Start the bulk SMS sending loop
  Future<void> startSending() async {
    if (_isSending) return;
    if (_contacts.isEmpty) {
      _addLog("[Warning] Import contacts before starting bulk dispatch.");
      return;
    }
    if (_currentIndex >= _contacts.length) {
      _addLog("[System] Queue already fully processed. Clear or import a new file.");
      return;
    }

    _isSending = true;
    _addLog("[Dispatch] Starting loop on SIM Slot $_simSlot...");
    notifyListeners();

    while (_isSending && _currentIndex < _contacts.length) {
      final contact = _contacts[_currentIndex];
      final messageText = compileTemplate(contact);
      final indexText = "${_currentIndex + 1}/${_contacts.length}";

      try {
        _addLog("[Sending] -> ${contact.phoneNumber} ($indexText)...");

        // Native hardware SIM dispatch using background_sms package
        final SmsStatus status = await BackgroundSms.sendMessage(
          phoneNumber: contact.phoneNumber,
          message: messageText,
          simSlot: _simSlot,
        );

        if (status == SmsStatus.sent) {
          _addLog("[Sent] -> ${contact.phoneNumber} ($indexText)");
          _saveLogToHistory(contact.phoneNumber, 'SUCCESS', messageText);
        } else {
          _addLog("[Failed] -> ${contact.phoneNumber} ($indexText) - Operator Refused");
          _saveLogToHistory(contact.phoneNumber, 'FAILED', messageText + " (Operator Refused)");
        }
      } catch (e) {
        _addLog("[Failed] -> ${contact.phoneNumber} ($indexText) - Native Error: $e");
        _saveLogToHistory(contact.phoneNumber, 'FAILED', messageText + " (Error: $e)");
      }

      _currentIndex++;
      notifyListeners();

      // Implement Anti-SIM Blocking Mechanism (Crucial for Zong/Jazz/Telenor/Ufone spam bots)
      if (_currentIndex < _contacts.length && _isSending) {
        _addLog("[Waiting 10s] Delaying next SMS to prevent SIM spam block...");
        
        // Wait in small increments so the user can pause instantaneously without waiting 10s
        for (int i = 0; i < 10; i++) {
          if (!_isSending) break;
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    if (_currentIndex >= _contacts.length) {
      _addLog("[Completed] Finished sending all bulk messages successfully!");
    } else {
      _addLog("[Paused] Bulk SMS loop paused at $_currentIndex/${_contacts.length}.");
    }

    _isSending = false;
    notifyListeners();
  }

  /// Pause the bulk sending loop
  void pauseSending() {
    if (!_isSending) return;
    _isSending = false;
    _addLog("[Action] Requesting pause...");
    notifyListeners();
  }

  /// Reset progress index to start from the beginning
  void resetProgress() {
    if (_isSending) return;
    _currentIndex = 0;
    _addLog("[System] Queue index reset to start.");
    notifyListeners();
  }

  /// Save logs inside local Hive storage database
  void _saveLogToHistory(String phone, String status, String msg) {
    final log = SmsLog(
      timestamp: DateTime.now(),
      phoneNumber: phone,
      status: status,
      message: msg,
      simSlot: _simSlot,
    );

    _logBox.add(log.toMap());
    _historyLogs.insert(0, log); // Prepend to history lists
    notifyListeners();
  }

  /// Clears the history logs database
  Future<void> clearHistoryLogs() async {
    await _logBox.clear();
    _historyLogs.clear();
    _addLog("[System] Local history logs database cleared.");
    notifyListeners();
  }
}
