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
        left: 12,
        right: 12,
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
          Row(
            children: [
              // Combined Futuristic Brand Logo Lockup: JC AI + SOIL / AI ANALYZER
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _buildUnifiedBrandLogo(context),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // AI Vision Camera icon
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.camera_alt, color: Colors.cyanAccent, size: 21),
                tooltip: 'AI Camera / Record Data',
                onPressed: onCameraTap,
              ),

              // AI Dataset Gallery icon
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.photo_library_outlined, color: Colors.tealAccent, size: 21),
                tooltip: 'คลังภาพ & ข้อมูล AI',
                onPressed: onGalleryTap,
              ),

              const SizedBox(width: 2),

              // Flag Language Switcher (TH / EN / ZH)
              const LanguageSelectorButton(compact: true),

              const SizedBox(width: 2),

              // Settings icon
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.settings, color: Colors.white, size: 21),
                tooltip: 'Settings & Serial Config',
                onPressed: onSettingsTap,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Badges Row: USB Status + AI Calibration Status + GPS Geotag
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              // 1. USB Connection Badge
              InkWell(
                onTap: onConnectTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _statusColor.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _getStatusLabel(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. AI Deep Learning Calibration Badge
              Builder(
                builder: (ctx) {
                  final lang = ctx.watch<LanguageProvider>();
                  return InkWell(
                    onTap: onAiTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isAiCalibrated
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAiCalibrated ? Colors.cyanAccent : Colors.white24,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: isAiCalibrated ? Colors.cyanAccent : Colors.white54,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAiCalibrated ? lang.t('aiCalibrationOn') : lang.t('aiCalibrationOff'),
                            style: TextStyle(
                              color: isAiCalibrated ? Colors.cyanAccent : Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 3. GPS Geotag Badge (Lat, Lon, Alt)
              Builder(
                builder: (ctx) {
                  final lang = ctx.watch<LanguageProvider>();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.amberAccent, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          location?.summary ?? lang.t('gpsLocating'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // 3. Hardware Diagnostic Telemetry & Quick Baud Switch Bar (When Connected)
          if (isConnected) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasValidReading ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.amberAccent.withValues(alpha: 0.4),
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
                            color: Colors.cyanAccent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.cyanAccent, width: 0.7),
                          ),
                          child: Text(
                            'สลับเป็น $alternateBaud',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // RX / TX telemetry
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasValidReading ? Icons.check_circle : Icons.sync,
                        size: 12,
                        color: hasValidReading ? Colors.greenAccent : Colors.amberAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasValidReading
                            ? 'Rx: ${rxByteCount}B (ข้อมูลปกติ)'
                            : (rxByteCount > 0 ? 'Rx: ${rxByteCount}B...' : 'รอหัววัด (Tx: $txCount)'),
                        style: TextStyle(
                          color: hasValidReading ? Colors.greenAccent : Colors.amberAccent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
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

  Widget _buildUnifiedBrandLogo(BuildContext context) {
    final isSim = (status == UsbConnectionStatus.simulating);

    return Semantics(
      label: 'JC AI SOIL AI ANALYZER',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSimulationTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSim
                    ? Colors.amberAccent.withValues(alpha: 0.8)
                    : Colors.cyanAccent.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSim
                      ? Colors.amber.withValues(alpha: 0.25)
                      : Colors.cyanAccent.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: JC AI Emblem Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSim
                          ? const [Color(0xFFFF8F00), Color(0xFFFFD54F)]
                          : const [Color(0xFF0D47A1), Color(0xFF00B0FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: isSim
                            ? Colors.amber.withValues(alpha: 0.4)
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          shadows: isSim
                              ? null
                              : const [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                        ),
                      ),
                      const SizedBox(width: 3.5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSim
                              ? Colors.black87
                              : const Color(0xFF00E5FF).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSim ? Colors.transparent : Colors.cyanAccent,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'AI',
                          style: TextStyle(
                            color: isSim ? Colors.amberAccent : Colors.cyanAccent,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Luminous Vertical Divider
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 1.5,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        isSim ? Colors.amberAccent : Colors.cyanAccent,
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // Right Column: Two-line Typography (Top: SOIL, Bottom: AI ANALYZER)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1: SOIL
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'SOIL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00E676), // Neon nature emerald
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
                    const SizedBox(height: 1.5),
                    // Line 2: AI ANALYZER
                    Text(
                      'AI ANALYZER',
                      style: TextStyle(
                        color: isSim ? Colors.amberAccent : const Color(0xFF64FFDA),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: isSim
                                ? Colors.amber.withValues(alpha: 0.6)
                                : const Color(0xFF64FFDA).withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
