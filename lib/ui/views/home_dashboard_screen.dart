import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/sensor_constants.dart';
import '../../data/services/usb_sensor_service.dart';
import '../viewmodels/soil_sensor_viewmodel.dart';
import '../widgets/agronomic_summary_sheet.dart';
import '../widgets/ai_model_details_sheet.dart';
import '../widgets/parameter_card.dart';
import '../widgets/status_header.dart';
import 'historical_data_screen.dart';
import 'settings_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SoilSensorViewModel>();
    final reading = vm.displayReading;
    final calResult = vm.calibrationResult;
    final isOffline = (vm.status == UsbConnectionStatus.disconnected ||
        vm.status == UsbConnectionStatus.error);

    // Format display string: if offline and not simulating show '***', if waiting for probe show '---'
    String fmtVal(num val, {int decimals = 1}) {
      if (isOffline && !vm.isSimulationMode) return '***';
      if (!vm.isSimulationMode && !vm.hasReceivedValidReading && val == 0) return '---';
      return val.toStringAsFixed(decimals);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // 1. Top Header with Gradient, Title, Badges, and Live Telemetry
            StatusHeader(
              status: vm.status,
              isAiCalibrated: vm.isAiCalibrationEnabled,
              baudRate: vm.baudRate,
              txCount: vm.txCount,
              rxByteCount: vm.rxByteCount,
              hasValidReading: vm.hasReceivedValidReading,
              onConnectTap: () => vm.connectUsb(),
              onSimulationTap: () => vm.toggleSimulation(),
              onSwitchBaudTap: () => vm.switchBaudRate(vm.baudRate == 4800 ? 9600 : 4800),
              onAiTap: () {
                AiModelDetailsSheet.show(
                  context,
                  calibrationResult: vm.calibrationResult,
                  isAiActive: vm.isAiCalibrationEnabled,
                  onToggleAi: (val) => vm.toggleAiCalibration(val),
                );
              },
              onSettingsTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),

            // 2. Responsive 8 Parameter Cards Grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final maxHeight = constraints.maxHeight;

                  // Adaptive Breakpoints:
                  // Compact/Portrait Phone: 2 columns
                  // Tablet / Foldable / Landscape: 4 columns
                  final int crossAxisCount = (maxWidth >= 600) ? 4 : 2;
                  final int rowCount = (crossAxisCount == 4) ? 2 : 4;

                  // Dynamic Aspect Ratio calculation to fit screen without scrolling if possible,
                  // with fallback scrollable physics for constrained heights.
                  final double calculatedRatio = (maxWidth / crossAxisCount) /
                      ((maxHeight - 12) / rowCount);
                  final double childAspectRatio = calculatedRatio.clamp(1.05, 2.6);

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
                        child: GridView.count(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3,
                          physics: (maxHeight < 380)
                              ? const AlwaysScrollableScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          children: [
                            // 1. Temperature (°C) - Green
                            ParameterCard(
                              title: SensorConstants.titleTemperature,
                              unit: SensorConstants.unitTemperature,
                              value: fmtVal(reading.temperature, decimals: 1),
                              backgroundColor: AppColors.temperature,
                              icon: Icons.thermostat_outlined,
                              isAiCalibrated: vm.isAiCalibrationEnabled && !isOffline,
                              aiDelta: '${calResult.temperatureDelta > 0 ? '+' : ''}${calResult.temperatureDelta}°C',
                              statusHint: isOffline ? null : 'ดินเขตร้อน',
                              onTap: () => AgronomicSummarySheet.show(context, vm.assessment),
                            ),

                            // 2. Moisture (%) - Blue
                            ParameterCard(
                              title: SensorConstants.titleMoisture,
                              unit: SensorConstants.unitMoisture,
                              value: fmtVal(reading.moisture, decimals: 1),
                              backgroundColor: AppColors.moisture,
                              icon: Icons.water_drop_outlined,
                              isAiCalibrated: vm.isAiCalibrationEnabled && !isOffline,
                              aiDelta: '${calResult.moistureDelta > 0 ? '+' : ''}${calResult.moistureDelta}%',
                              statusHint: isOffline ? null : vm.assessment.moistureStatus.name,
                              onTap: () => AgronomicSummarySheet.show(context, vm.assessment),
                            ),

                            // 3. Conductivity(EC) us/cm - Purple
                            ParameterCard(
                              title: SensorConstants.titleConductivity,
                              unit: SensorConstants.unitConductivity,
                              value: isOffline && !vm.isSimulationMode
                                  ? '***'
                                  : reading.conductivity.toString(),
                              backgroundColor: AppColors.conductivity,
                              icon: Icons.electric_bolt_outlined,
                              isAiCalibrated: vm.isAiCalibrationEnabled && !isOffline,
                              aiDelta: '${calResult.ecDelta > 0 ? '+' : ''}${calResult.ecDelta}µS',
                              statusHint: isOffline ? null : vm.assessment.salinityStatus.name,
                              onTap: () => AgronomicSummarySheet.show(context, vm.assessment),
                            ),

                            // 4. pH - Orange
                            ParameterCard(
                              title: SensorConstants.titlePh,
                              unit: SensorConstants.unitPh,
                              value: fmtVal(reading.ph, decimals: 2),
                              backgroundColor: AppColors.ph,
                              icon: Icons.science_outlined,
                              isAiCalibrated: vm.isAiCalibrationEnabled && !isOffline,
                              aiDelta: '${calResult.phDelta > 0 ? '+' : ''}${calResult.phDelta}',
                              statusHint: isOffline ? null : vm.assessment.phStatus.name,
                              onTap: () => AgronomicSummarySheet.show(context, vm.assessment),
                            ),

                            // 5. (N) Nitrogen - Magenta / Pink
                            ParameterCard(
                              title: SensorConstants.titleNitrogen,
                              unit: SensorConstants.unitNitrogen,
                              value: isOffline && !vm.isSimulationMode
                                  ? '***'
                                  : reading.nitrogen.toString(),
                              backgroundColor: AppColors.nitrogen,
                              icon: Icons.grass_outlined,
                              statusHint: isOffline ? null : 'Available N',
                              onTap: () => AgronomicSummarySheet.show(context, vm.assessment),
                            ),

                            // 6. (P) Phosphorus - Cyan / Light Blue
                            ParameterCard(
                              title: SensorConstants.titlePhosphorus,
                              unit: SensorConstants.unitPhosphorus,
                              value: isOffline && !vm.isSimulationMode
                                  ? '***'
                                  : reading.phosphorus.toString(),
                              backgroundColor: AppColors.phosphorus,
                              icon: Icons.filter_vintage_outlined,
                              statusHint: isOffline ? null : 'Available P',
                              onTap: () => AgronomicSummarySheet.show(context, vm.assessment),
                            ),

                            // 7. (K) Potassium - Teal
                            ParameterCard(
                              title: SensorConstants.titlePotassium,
                              unit: SensorConstants.unitPotassium,
                              value: isOffline && !vm.isSimulationMode
                                  ? '***'
                                  : reading.potassium.toString(),
                              backgroundColor: AppColors.potassium,
                              icon: Icons.grain_outlined,
                              statusHint: isOffline ? null : 'Available K',
                              onTap: () => AgronomicSummarySheet.show(context, vm.assessment),
                            ),

                            // 8. Fertility - Coral / Salmon
                            ParameterCard(
                              title: SensorConstants.titleFertility,
                              unit: SensorConstants.unitFertility,
                              value: isOffline && !vm.isSimulationMode
                                  ? '***'
                                  : reading.fertility.toString(),
                              backgroundColor: AppColors.fertility,
                              icon: Icons.shield_outlined,
                              statusHint: isOffline ? null : 'Index Score',
                              onTap: () => AgronomicSummarySheet.show(context, vm.assessment),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. Bottom Action Bar: [Save to *.xls] and [Data]
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCCCCCC),
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final res = await vm.exportToSpreadsheet();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res.message),
                                    action: SnackBarAction(
                                      label: 'Share',
                                      onPressed: () => vm.shareExport(),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: vm.isExporting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    'Save to *.xls',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCCCCCC),
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HistoricalDataScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Data',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Footer info text
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 6),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'The data is stored in root directory.(${SensorConstants.defaultCsvFileName})',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${SensorConstants.appVersion} | AI PINN',
                        style: TextStyle(
                          color: Colors.cyanAccent.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
