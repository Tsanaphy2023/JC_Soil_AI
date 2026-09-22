import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ph_colors.dart';
import '../../data/services/usb_ph_service.dart';
import '../viewmodels/ph_monitor_viewmodel.dart';
import '../widgets/ht_compensation_card.dart';
import '../widgets/ph_circular_gauge.dart';
import '../widgets/status_app_bar.dart';
import 'field_validation_screen.dart';
import 'ph_analytics_screen.dart';
import 'ph_history_screen.dart';
import 'ph_settings_screen.dart';
import 'soil_camera_screen.dart';
import 'soil_dataset_gallery_screen.dart';

class PhDashboardScreen extends StatelessWidget {
  const PhDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PhMonitorViewModel>();
    final result = vm.calibratedResult;
    final alert = vm.toxicityAlert;
    final location = vm.currentLocation;

    return Scaffold(
      backgroundColor: PhColors.background,
      appBar: StatusAppBar(
        usbStatus: vm.usbStatus,
        isSimulation: vm.isSimulationMode,
        isAiActive: vm.isAiEnabled,
        onToggleAi: vm.toggleAi,
        onToggleSimulation: vm.toggleSimulation,
        onOpenSettings: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhSettingsScreen()),
          );
        },
        onOpenCamera: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SoilCameraScreen()),
          );
        },
        onOpenGallery: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SoilDatasetGalleryScreen()),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toxicity Warning Alert Banner (if applicable)
            if (alert != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PhColors.neonRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PhColors.neonRed, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: PhColors.neonRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // USB-C Connection Bar
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: vm.usbStatus == UsbStatus.connected
                    ? PhColors.neonGreen.withOpacity(0.12)
                    : vm.isSimulationMode
                        ? PhColors.neonAmber.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: vm.usbStatus == UsbStatus.connected
                      ? PhColors.neonGreen.withOpacity(0.4)
                      : vm.isSimulationMode
                          ? PhColors.neonAmber.withOpacity(0.4)
                          : Colors.orange.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    vm.usbStatus == UsbStatus.connected
                        ? Icons.cable
                        : vm.isSimulationMode
                            ? Icons.biotech
                            : Icons.usb,
                    size: 18,
                    color: vm.usbStatus == UsbStatus.connected
                        ? PhColors.neonGreen
                        : vm.isSimulationMode
                            ? PhColors.neonAmber
                            : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.usbStatus == UsbStatus.connected
                          ? 'ต่อสาย USB-C กับ Soil Parameter Tester เรียบร้อย (${vm.baudRate} bps)'
                          : vm.isSimulationMode
                              ? 'โหมดจำลองดินเสมือนจริง • เสียบสาย USB-C เพื่อเชื่อมต่อเซนเซอร์จริง'
                              : 'ยังไม่พบหัววัดดิน • เสียบสาย Type-C เข้ากับพอร์ต OTG',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: vm.usbStatus == UsbStatus.connected
                            ? PhColors.neonGreen
                            : Colors.white,
                      ),
                    ),
                  ),
                  if (vm.usbStatus != UsbStatus.connected) ...[
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: PhColors.neonCyan,
                      ),
                      onPressed: () => vm.connectUsb(),
                      child: const Text('เชื่อมต่อ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),

            // GPS Geolocation Info Bar
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: PhColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PhColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 15, color: PhColors.neonCyan),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'พิกัดแปลง ${location.summary}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Main Circular Dial Gauge
            PhCircularGauge(
              currentPh: vm.displayPh,
              rawPh: vm.rawReading.phRaw,
              isAiActive: vm.isAiEnabled,
              deltaPh: result.deltaPhTotal,
            ),

            const SizedBox(height: 10),

            // Calibration Mode Selector Chips (Objective 2: Ablation comparison)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: PhColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PhColors.cardBorder),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: PhCalibrationMode.values.map((mode) {
                    final isSelected = vm.calibrationMode == mode;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          mode == PhCalibrationMode.fullAiPinn
                              ? 'AI PINN (สมบูรณ์)'
                              : mode == PhCalibrationMode.conventionalAtc
                                  ? 'ATC (อุณหภูมิเดิม)'
                                  : 'Raw (ค่าดิบ)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.black : Colors.white70,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: PhColors.neonGreen,
                        backgroundColor: PhColors.background,
                        onSelected: (_) => vm.setCalibrationMode(mode),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Deep Learning HT Error Compensation Card
            HtCompensationCard(
              result: result,
              isAiActive: vm.isAiEnabled,
            ),

            const SizedBox(height: 14),

            // Objective 3 & 1: Field Validation & AI Training Dataset Prominent Button
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PhColors.neonCyan.withOpacity(0.15),
                  foregroundColor: PhColors.neonCyan,
                  side: const BorderSide(color: PhColors.neonCyan, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.verified_outlined, size: 20),
                label: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ทดสอบภาคสนาม (จันทบุรี/ตราด) & AI Dataset',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 13),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FieldValidationScreen()),
                  );
                },
              ),
            ),

            // Action Buttons Grid (Camera AI Vision, Analytics, History)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;

                Widget buildCameraButton() => ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PhColors.neonGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'ถ่ายภาพดิน AI',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SoilCameraScreen()),
                        );
                      },
                    );

                Widget buildAnalyticsButton() => OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: PhColors.neonCyan, width: 1.3),
                        foregroundColor: PhColors.neonCyan,
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'วิเคราะห์ดิน',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PhAnalyticsScreen()),
                        );
                      },
                    );

                Widget buildHistoryButton() => OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30, width: 1.3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.history, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'ประวัติ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PhHistoryScreen()),
                        );
                      },
                    );

                if (isNarrow) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: buildCameraButton()),
                          const SizedBox(width: 8),
                          Expanded(child: buildAnalyticsButton()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: buildHistoryButton(),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 5, child: buildCameraButton()),
                    const SizedBox(width: 8),
                    Expanded(flex: 5, child: buildAnalyticsButton()),
                    const SizedBox(width: 8),
                    Expanded(flex: 4, child: buildHistoryButton()),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
