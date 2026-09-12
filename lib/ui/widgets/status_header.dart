import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/usb_sensor_service.dart';

class StatusHeader extends StatelessWidget {
  final UsbConnectionStatus status;
  final bool isAiCalibrated;
  final int baudRate;
  final int txCount;
  final int rxByteCount;
  final bool hasValidReading;
  final VoidCallback? onConnectTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onSimulationTap;
  final VoidCallback? onAiTap;
  final VoidCallback? onSwitchBaudTap;

  const StatusHeader({
    super.key,
    required this.status,
    this.isAiCalibrated = true,
    this.baudRate = 4800,
    this.txCount = 0,
    this.rxByteCount = 0,
    this.hasValidReading = false,
    this.onConnectTap,
    this.onSettingsTap,
    this.onSimulationTap,
    this.onAiTap,
    this.onSwitchBaudTap,
  });

  String get _statusLabel {
    switch (status) {
      case UsbConnectionStatus.connected:
        return 'USB CONNECTED';
      case UsbConnectionStatus.connecting:
        return 'CONNECTING...';
      case UsbConnectionStatus.simulating:
        return 'SIMULATION (DEMO)';
      case UsbConnectionStatus.error:
        return 'USB ERROR';
      case UsbConnectionStatus.disconnected:
        return 'DISCONNECTED';
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
              // Simulation quick switch
              IconButton(
                icon: Icon(
                  status == UsbConnectionStatus.simulating
                      ? Icons.play_circle_filled
                      : Icons.science_outlined,
                  color: Colors.white,
                ),
                tooltip: 'Toggle Demo Simulation',
                onPressed: onSimulationTap,
              ),

              // Title JC AI Detector with custom icon
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 26,
                            height: 26,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'JC AI Detector',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Settings icon
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Settings & Serial Config',
                onPressed: onSettingsTap,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Badges Row: USB Status + AI Calibration Status
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
                        _statusLabel,
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
              InkWell(
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
                        isAiCalibrated ? 'AI CALIBRATION: ON' : 'AI CALIBRATION: OFF',
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
}
