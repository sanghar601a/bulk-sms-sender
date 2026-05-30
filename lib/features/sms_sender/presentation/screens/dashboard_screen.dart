import 'dart:ui';
import 'package:flutter/material.dart';
import '../state/sms_sender_provider.dart';

/// Premium Glassmorphic Dashboard UI for Bulk SMS Sender.
class DashboardScreen extends StatefulWidget {
  final SmsSenderProvider provider;

  const DashboardScreen({Key? key, required this.provider}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _templateController = TextEditingController();
  final ScrollController _terminalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _templateController.text = widget.provider.messageTemplate;
    _templateController.addListener(() {
      widget.provider.updateTemplate(_templateController.text);
    });

    // Auto-scroll terminal when new logs are added
    widget.provider.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _templateController.dispose();
    widget.provider.removeListener(_scrollToBottom);
    _terminalScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_terminalScrollController.hasClients) {
      _terminalScrollController.animateTo(
        _terminalScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.provider,
      builder: (context, _) {
        final prov = widget.provider;
        final theme = Theme.of(context);

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0C1B), // Very deep indigo/black
                  Color(0xFF15102A), // Dark purple-tinted black
                  Color(0xFF0D0B14),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 16),

                    // Main scrollable settings pane
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Dropzone Excel Picker
                          _buildDropzone(prov),
                          const SizedBox(height: 16),

                          // SIM Selection and Status Indicators
                          _buildConfigRow(prov),
                          const SizedBox(height: 16),

                          // Template Message Editor Box
                          _buildTemplateEditor(prov),
                          const SizedBox(height: 20),

                          // Primary Start/Pause controls
                          _buildDispatchButton(prov),
                          const SizedBox(height: 20),

                          // Monospace logs terminal header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Live Dispatch Output",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (prov.consoleLogs.isNotEmpty)
                                TextButton(
                                  onPressed: () => prov.clearHistoryLogs(),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    "Clear DB Logs",
                                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                                  ),
                                )
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Monospace terminal widget
                          _buildTerminal(prov),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Bulk SMS Sender",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Pakistani Mobile Network Gateway • 100% Offline",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircleAvatar(
                radius: 4,
                backgroundColor: Colors.greenAccent,
              ),
              SizedBox(width: 6),
              Text(
                "SIM Hardware Link Active",
                style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropzone(SmsSenderProvider prov) {
    final hasFile = prov.importedFileName != null;

    return GestureDetector(
      onTap: prov.pickAndParseFile,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: hasFile ? Colors.cyanAccent.withOpacity(0.6) : Colors.white24,
          strokeWidth: 1.5,
          gap: 6,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasFile ? Icons.file_present_rounded : Icons.upload_file_rounded,
                size: 40,
                color: hasFile ? Colors.cyanAccent : Colors.white38,
              ),
              const SizedBox(height: 12),
              Text(
                hasFile ? prov.importedFileName! : "Import Contacts File (.xlsx)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: hasFile ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasFile
                    ? "${prov.contacts.length} Contacts loaded successfully"
                    : "Tap to pick Excel spreadsheet from your local storage",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: hasFile ? Colors.cyanAccent.withOpacity(0.8) : Colors.white30,
                  fontSize: 11,
                ),
              ),
              if (hasFile) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: prov.clearQueue,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text("Clear Queue", style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.2),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigRow(SmsSenderProvider prov) {
    return Row(
      children: [
        // SIM Picker Cards
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "SIM Slot:",
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                DropdownButton<int>(
                  value: prov.simSlot,
                  dropdownColor: const Color(0xFF15102A),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.cyanAccent),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("Slot 1 (Jazz/Zong)")),
                    DropdownMenuItem(value: 2, child: Text("Slot 2 (Telenor/Ufone)")),
                  ],
                  onChanged: prov.isSending ? null : (val) => prov.setSimSlot(val ?? 1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Progress Indicator Card
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Processed",
                  style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  "${prov.currentIndex}/${prov.contacts.length}",
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateEditor(SmsSenderProvider prov) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "SMS Message Template",
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                "Supports [Name], [Amount], [ColumnHeader]",
                style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _templateController,
            maxLines: 3,
            enabled: !prov.isSending,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            decoration: InputDecoration(
              hintText: "Enter message template...",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.cyanAccent, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Preview Card
          if (prov.contacts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dynamic Preview (Row 1):",
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prov.compileTemplate(prov.contacts.first),
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDispatchButton(SmsSenderProvider prov) {
    final isQueueEmpty = prov.contacts.isEmpty;
    final isFinished = prov.currentIndex >= prov.contacts.length && prov.contacts.isNotEmpty;

    if (isFinished) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: prov.resetProgress,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text(
            "Restart Dispatch Loop",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isQueueEmpty
              ? [Colors.grey.shade800, Colors.grey.shade900]
              : prov.isSending
                  ? [Colors.orange.shade700, Colors.deepOrange.shade600]
                  : [Colors.cyan.shade600, Colors.teal.shade500],
        ),
        boxShadow: [
          if (!isQueueEmpty)
            BoxShadow(
              color: prov.isSending ? Colors.orange.withOpacity(0.3) : Colors.cyan.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: ElevatedButton(
        onPressed: isQueueEmpty
            ? null
            : prov.isSending
                ? prov.pauseSending
                : prov.startSending,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              prov.isSending ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: isQueueEmpty ? Colors.white24 : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              prov.isSending ? "Pause Bulk SMS Campaign" : "Start Bulk Dispatch",
              style: TextStyle(
                color: isQueueEmpty ? Colors.white24 : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminal(SmsSenderProvider prov) {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: prov.consoleLogs.isEmpty
          ? const Center(
              child: Text(
                "Terminal ready. Awaiting inputs...",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            )
          : Scrollbar(
              controller: _terminalScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _terminalScrollController,
                itemCount: prov.consoleLogs.length,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  final log = prov.consoleLogs[index];
                  // Extract colors or highlight error tags in terminal
                  Color logColor = Colors.greenAccent;
                  if (log.contains('[Error]') || log.contains('[Failed]')) {
                    logColor = Colors.redAccent;
                  } else if (log.contains('[Warning]')) {
                    logColor = Colors.amberAccent;
                  } else if (log.contains('[Sent]')) {
                    logColor = Colors.cyanAccent;
                  } else if (log.contains('[System]')) {
                    logColor = Colors.white54;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: logColor,
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// Custom painter to paint a dashed border around containers.
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    ));

    final Path dashPath = Path();
    double distance = 0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
