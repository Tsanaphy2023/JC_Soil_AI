import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ph_colors.dart';
import '../../core/constants/sensor_constants.dart';
import '../../data/services/simulation_service.dart';
import '../../data/services/usb_ph_service.dart';
import '../../domain/ml/ph_deep_pinn_model.dart';
import '../viewmodels/ph_monitor_viewmodel.dart';

class PhSettingsScreen extends StatelessWidget {
  const PhSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PhMonitorViewModel>();

    return Scaffold(
      backgroundColor: PhColors.background,
      appBar: AppBar(
        title: const Text('การตั้งค่า & สเปกโมเดล AI'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Soil Simulation Scenario Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.biotech, color: PhColors.neonAmber),
                      const SizedBox(width: 8),
                      const Text(
                        'จำลองสถานการณ์สภาพดิน (Soil Simulation)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'จำลองสภาวะแวดล้อมจริงเพื่อทดสอบการตอบสนองของโมเดล Deep Learning',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('เปิดโหมดจำลอง (Simulation Active)'),
                    subtitle: const Text('ใช้ข้อมูลคำนวณแทนหัววัด USB จริง'),
                    value: vm.isSimulationMode,
                    activeColor: PhColors.neonAmber,
                    onChanged: (val) => vm.toggleSimulation(val),
                  ),
                  const SizedBox(height: 8),
                  if (vm.isSimulationMode) ...[
                    const Text(
                      'เลือกสภาพแปลงเกษตรตัวอย่าง:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...SoilScenario.values.map((sc) {
                      final isSelected = vm.currentScenario == sc;
                      return RadioListTile<SoilScenario>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          sc.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? PhColors.neonAmber : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          'T: ${sc.baseTemp}°C • H: ${sc.baseMoist}% • pH: ${sc.basePh} • EC: ${sc.baseEc}',
                          style: const TextStyle(fontSize: 11, color: Colors.white54),
                        ),
                        value: sc,
                        groupValue: vm.currentScenario,
                        activeColor: PhColors.neonAmber,
                        onChanged: (s) {
                          if (s != null) vm.setScenario(s);
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // USB Hardware Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.usb, color: PhColors.neonCyan),
                      const SizedBox(width: 8),
                      const Text(
                        'การเชื่อมต่อหัววัดฮาร์ดแวร์ (USB OTG)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('สถานะการเชื่อมต่อ:'),
                    trailing: Text(
                      vm.usbStatus == UsbStatus.connected
                          ? 'เชื่อมต่อแล้ว (Connected)'
                          : vm.usbStatus == UsbStatus.connecting
                              ? 'กำลังค้นหา...'
                              : 'ไม่ได้เชื่อมต่อ (Disconnected)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: vm.usbStatus == UsbStatus.connected
                            ? PhColors.neonGreen
                            : Colors.orange,
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Baud Rate มาตรฐาน:'),
                    subtitle: const Text('เซนเซอร์ดินจีน RS485 ส่วนใหญ่ใช้ 4800 bps'),
                    trailing: DropdownButton<int>(
                      value: vm.baudRate,
                      dropdownColor: PhColors.cardBg,
                      items: SensorConstants.supportedBaudRates.map((b) {
                        return DropdownMenuItem<int>(
                          value: b,
                          child: Text('$b bps'),
                        );
                      }).toList(),
                      onChanged: (b) {
                        if (b != null) {
                          vm.connectUsb(baudRate: b);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vm.usbStatus == UsbStatus.connected
                            ? PhColors.neonRed
                            : PhColors.neonCyan,
                        foregroundColor: Colors.black,
                      ),
                      icon: Icon(
                        vm.usbStatus == UsbStatus.connected
                            ? Icons.usb_off
                            : Icons.cable,
                        size: 18,
                      ),
                      label: Text(
                        vm.usbStatus == UsbStatus.connected
                            ? 'ตัดการเชื่อมต่อ USB'
                            : 'ค้นหาและเชื่อมต่อหัววัด USB',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        if (vm.usbStatus == UsbStatus.connected) {
                          vm.disconnectUsb();
                        } else {
                          vm.connectUsb();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Deep Learning PINN Architecture Specs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.memory, color: PhColors.neonGreen),
                      const SizedBox(width: 8),
                      const Text(
                        'ข้อมูลสถาปัตยกรรม Deep Learning (PINN)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _specRow('เวอร์ชันโมเดล', PhDeepPinnModel.modelVersion),
                  _specRow('สถาปัตยกรรม', 'Physics-Informed Neural Network (PINN) 3-Layer MLP'),
                  _specRow('ฟังก์ชันกระตุ้น (Activation)', 'Swish / GELU / LeakyReLU'),
                  _specRow('สมการฟิสิกส์กำกับ (Physics Loss)', 'Nernst Slope (T) + Liquid Junction Impedance (H)'),
                  _specRow('ค่าอ้างอิงมาตรฐาน', '25.0°C, 50.0% VWC, 600 µS/cm EC'),
                  _specRow('สภาพการทำงาน', 'On-Device Edge AI 100% Offline (Zero Latency)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
