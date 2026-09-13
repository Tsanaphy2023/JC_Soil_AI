import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../data/models/geo_location_data.dart';
import '../../data/services/usb_sensor_service.dart';
import 'language_selector_button.dart';

class StatusHeader extends StatelessWidget {
  final UsbConnectionStatus status;
  final bool isAiCalibrated;
  final int baudRate;
  final int txCount;
  final int rxByteCount;
  final bool hasValidReading;
  final GeoLocationData? location;
  final VoidCallback? onConnectTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onSimulationTap;
  final VoidCallback? onAiTap;
  final VoidCallback? onSwitchBaudTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;

  const StatusHeader({
    super.key,
    required this.status,
    this.isAiCalibrated = true,
    this.baudRate = 4800,
    this.txCount = 0,
    this.rxByteCount = 0,
    this.hasValidReading = false,
    this.location,
    this.onConnectTap,
    this.onSettingsTap,
    this.onSimulationTap,
    this.onAiTap,
    this.onSwitchBaudTap,
    this.onCameraTap,
    this.onGalleryTap,
  });

  String _getStatusLabel(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    switch (status) {
      case UsbConnectionStatus.connected:
        return lang.t('connected');
      case UsbConnectionStatus.connecting:
        return lang.t('connecting');
      case UsbConnectionStatus.simulating:
        return 'DEMO SIMULATION';
      case UsbConnectionStatus.error:
        return 'USB ERROR';
      case UsbConnectionStatus.disconnected:
        return lang.t('disconnected');
    }
  }

  Color get _statusColor {
    switch (status) {
      case UsbConnectionStatus.connected:
        return AppColors.connected;
      case UsbConnectionStatus.connecting:
        return Colors.orangeAccent;
      case UsbConnectionStatus.simulating:
        return AppColors.simulating;
      case UsbConnectionStatus.error:
        return AppColors.disconnected;
      case UsbConnectionStatus.disconnected:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isConnected = (status == UsbConnectionStatus.connected);
    final int alternateBaud = (baudRate == 4800) ? 9600 : 4800;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 8,
        left: 10,
        right: 10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.headerGradientStart,
            AppColors.headerGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Main Two-Column Layout based on user's architectural wireframe
          // Left: Tall Prominent LOGO Card (Green Border)
          // Right: 3 Rows ([Camera, Gallery, Language, Settings] / [Connection, AI Calibration] / [GPS Lat Lon Alt])
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Column: Tall LOGO Card
                _buildTallLogoCard(context),

                const SizedBox(width: 8),

                // Right Column: 3 Rows
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Row 1: [กล้อง] [ภาพ] [ภาษา] [Settings Circle]
                      _buildTopActionsRow(context),

                      const SizedBox(height: 5),

                      // Row 2: [การเชื่อมต่อ] [การสอบเทียบ AI]
                      _buildStatusBadgesRow(context),

                      const SizedBox(height: 5),

                      // Row 3: [Lat. Log Alt]
                      _buildLocationRow(context),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hardware Diagnostic Telemetry & Quick Baud Switch Bar (When Connected)
          if (isConnected) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasValidReading
                      ? Colors.greenAccent.withValues(alpha: 0.5)
                      : Colors.amberAccent.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Baud rate and quick switch
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$baudRate bps',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onSwitchBaudTap,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.cyan.shade900.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 0.8),
                          ),
                          child: Text(
                            'สลับเป็น $alternateBaud',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Packets counter
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TX: $txCount',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RX: $rxByteCount B',
                        style: TextStyle(
                          color: hasValidReading ? Colors.greenAccent : Colors.amberAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Helpful troubleshooting tip when connected but no bytes arrive after a few attempts
            if (!hasValidReading && txCount >= 3 && rxByteCount == 0) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 12, color: Colors.amberAccent),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'หากค่าไม่ขึ้น: กด [สลับเป็น $alternateBaud] หรือเปิด OTG ในการตั้งค่ามือถือ',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Left Column: Tall LOGO Card with Green Border as drawn in user's diagram
  Widget _buildTallLogoCard(BuildContext context) {
    final isSim = (status == UsbConnectionStatus.simulating);
    const borderColor = Color(0xFF00E676); // Signature vibrant green border from user diagram

    return Semantics(
      label: 'JC AI SOIL AI ANALYZER LOGO',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSimulationTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 114,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSim ? Colors.amberAccent.withValues(alpha: 0.85) : borderColor,
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSim ? Colors.amber : borderColor).withValues(alpha: 0.22),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. JC AI Emblem Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSim
                            ? const [Color(0xFFFF8F00), Color(0xFFFFD54F)]
                            : const [Color(0xFF0D47A1), Color(0xFF00B0FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: isSim
                              ? Colors.amber.withValues(alpha: 0.35)
                              : Colors.blueAccent.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'JC',
                          style: TextStyle(
                            color: isSim ? Colors.black87 : Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSim
                                ? Colors.black87
                                : const Color(0xFF00E5FF).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: isSim ? Colors.transparent : Colors.cyanAccent,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'AI',
                            style: TextStyle(
                              color: isSim ? Colors.amberAccent : Colors.cyanAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Horizontal Glowing Divider
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    width: 60,
                    height: 1.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          isSim ? Colors.amberAccent : borderColor,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // 3. SOIL Typography with Emerald Dot
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SOIL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 3.5),
                      Container(
                        width: 4.5,
                        height: 4.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00E676),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // 4. AI ANALYZER Subtitle
                  Text(
                    'AI ANALYZER',
                    style: TextStyle(
                      color: isSim ? Colors.amberAccent : const Color(0xFF64FFDA),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Right Column - Row 1: [กล้อง] [ภาพ] [ภาษา] [Settings Circle]
  Widget _buildTopActionsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Camera Action Box
        _buildActionBox(
          icon: Icons.camera_alt,
          iconColor: Colors.cyanAccent,
          tooltip: 'AI Camera / Record Data',
          onTap: onCameraTap,
        ),

        const SizedBox(width: 4),

        // 2. Gallery Action Box
        _buildActionBox(
          icon: Icons.photo_library_outlined,
          iconColor: Colors.tealAccent,
          tooltip: 'คลังภาพ & ข้อมูล AI',
          onTap: onGalleryTap,
        ),

        const SizedBox(width: 4),

        // 3. Flag Language Switcher (TH / EN / ZH)
        const LanguageSelectorButton(compact: true),

        const SizedBox(width: 4),

        // 4. Settings Circular Button (Dark Teal Circle from User Diagram)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSettingsTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0B556A), // Dark teal/blue circle matching user diagram
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B556A).withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Rectangular Action Box with clean glass border
  Widget _buildActionBox({
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 0.9,
            ),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
      ),
    );
  }

  /// Right Column - Row 2: [การเชื่อมต่อ] [การสอบเทียบ AI]
  Widget _buildStatusBadgesRow(BuildContext context) {
    return Row(
      children: [
        // 1. USB Connection Badge
        Expanded(
          child: InkWell(
            onTap: onConnectTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusColor.withValues(alpha: 0.6),
                  width: 0.9,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusLabel(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 5),

        // 2. AI Deep Learning Calibration Badge
        Expanded(
          child: Builder(
            builder: (ctx) {
              final lang = ctx.watch<LanguageProvider>();
              return InkWell(
                onTap: onAiTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAiCalibrated
                        ? Colors.cyan.shade900.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAiCalibrated
                          ? Colors.cyanAccent.withValues(alpha: 0.7)
                          : Colors.white24,
                      width: 0.9,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: isAiCalibrated ? Colors.cyanAccent : Colors.white54,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAiCalibrated ? lang.t('aiCalibrationOn') : lang.t('aiCalibrationOff'),
                          style: TextStyle(
                            color: isAiCalibrated ? Colors.cyanAccent : Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Right Column - Row 3: [Lat. Log Alt]
  Widget _buildLocationRow(BuildContext context) {
    return Builder(
      builder: (ctx) {
        final lang = ctx.watch<LanguageProvider>();
        return Container(
          height: 26,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.amberAccent.withValues(alpha: 0.55),
              width: 0.9,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.amberAccent, size: 11),
              const SizedBox(width: 3.5),
              Expanded(
                child: Text(
                  location?.summary ?? lang.t('gpsLocating'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Retained for backward compatibility
  Widget _buildUnifiedBrandLogo(BuildContext context) {
    return _buildTallLogoCard(context);
  }
}
