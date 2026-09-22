import 'package:flutter/material.dart';
import '../../core/constants/ph_colors.dart';
import '../../data/services/usb_ph_service.dart';

class StatusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UsbStatus usbStatus;
  final bool isSimulation;
  final bool isAiActive;
  final VoidCallback onToggleAi;
  final VoidCallback onToggleSimulation;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenCamera;
  final VoidCallback onOpenGallery;

  const StatusAppBar({
    super.key,
    required this.usbStatus,
    required this.isSimulation,
    required this.isAiActive,
    required this.onToggleAi,
    required this.onToggleSimulation,
    required this.onOpenSettings,
    required this.onOpenCamera,
    required this.onOpenGallery,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: PhColors.surface,
      titleSpacing: 8,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cyber Brand Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF00B0FF)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: PhColors.neonCyan.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.science, color: Colors.white, size: 15),
                  SizedBox(width: 4),
                  Text(
                    'SoilpH-HT',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            // Simulation / Live Mode Indicator
            InkWell(
              onTap: onToggleSimulation,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isSimulation
                      ? PhColors.neonAmber.withOpacity(0.15)
                      : (usbStatus == UsbStatus.connected
                          ? PhColors.neonGreen.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSimulation
                        ? PhColors.neonAmber
                        : (usbStatus == UsbStatus.connected
                            ? PhColors.neonGreen
                            : Colors.orangeAccent),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSimulation ? Icons.biotech : Icons.usb,
                      size: 11,
                      color: isSimulation
                          ? PhColors.neonAmber
                          : (usbStatus == UsbStatus.connected
                              ? PhColors.neonGreen
                              : Colors.orangeAccent),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isSimulation ? 'SIM' : (usbStatus == UsbStatus.connected ? 'USB OK' : 'NO USB'),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isSimulation
                            ? PhColors.neonAmber
                            : (usbStatus == UsbStatus.connected
                                ? PhColors.neonGreen
                                : Colors.orangeAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Camera Button
        IconButton(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.camera_alt_outlined, size: 20, color: PhColors.neonCyan),
          tooltip: 'กล้อง AI Vision',
          onPressed: onOpenCamera,
        ),
        // Gallery Button
        IconButton(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.photo_library_outlined, size: 20, color: Colors.white70),
          tooltip: 'คลังภาพถ่ายดิน',
          onPressed: onOpenGallery,
        ),
        // AI PINN Toggle Chip
        InkWell(
          onTap: onToggleAi,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isAiActive
                  ? PhColors.neonGreen.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAiActive ? PhColors.neonGreen : Colors.grey,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 11,
                  color: isAiActive ? PhColors.neonGreen : Colors.grey,
                ),
                const SizedBox(width: 3),
                Text(
                  isAiActive ? 'PINN' : 'RAW',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isAiActive ? PhColors.neonGreen : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Settings Button
        IconButton(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.tune, size: 20, color: Colors.white70),
          tooltip: 'ตั้งค่า & จำลองสภาพดิน',
          onPressed: onOpenSettings,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
