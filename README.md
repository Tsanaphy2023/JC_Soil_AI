# 🌱 Soil Parameter Detector (แอปพลิเคชันตรวจวัดคุณภาพดิน 8 พารามิเตอร์)

แอปพลิเคชันมือถือพัฒนาด้วย **Flutter** ออกแบบและพัฒนาเพื่อเชื่อมต่อกับหัววัด **Soil Parameter Tester (USB Type-C OTG / RS485 Modbus RTU)** เพื่อตรวจวัดคุณภาพดินในเขตรากพืช แสดงผลแบบ Real-time และบันทึกข้อมูลลงไฟล์ตารางคำนวณ (Excel/CSV) สำหรับงานวิจัยฟิสิกส์เกษตรดิจิทัลและการเกษตรแม่นยำสูง

---

## 📸 การออกแบบหน้าจอ (UI Design)

อ้างอิงและยกระดับจากหน้าจอต้นแบบ (**Soil Parameter Detector**):
- **ตาราง 8 การ์ดพารามิเตอร์ (2 Columns × 4 Rows Grid)** สีสันสดใส ชัดเจน และอ่านค่าง่ายกลางแจ้ง:
  1. 🟢 **Temperature (°C)**: อุณหภูมิดิน (เขียว `#388E3C`)
  2. 🔵 **Moisture (%)**: ความชื้นดินเชิงปริมาตร VWC (น้ำเงิน `#1976D2`)
  3. 🟣 **Conductivity(EC) (µS/cm)**: การนำไฟฟ้าและระดับความเค็ม (ม่วงเข้ม `#6A1B9A`)
  4. 🟠 **pH**: ความเป็นกรด-ด่างของดิน (ส้ม `#E65100`)
  5. 🔴 **(N) Nitrogen (mg/kg)**: ไนโตรเจนที่เป็นประโยชน์ (ชมพูเข้ม `#C2185B`)
  6. 💠 **(P) Phosphorus (mg/kg)**: ฟอสฟอรัสที่เป็นประโยชน์ (ฟ้า `#0288D1`)
  7. 🟢 **(K) Potassium (mg/kg)**: โพแทสเซียมที่เป็นประโยชน์ (เขียวอมฟ้า `#00897B`)
  8. 🍑 **Fertility (mg/kg)**: ดัชนีความอุดมสมบูรณ์ของดิน (พีช `#E64A19`)
- **Action Buttons ด้านล่าง:**
  - `[ Save to *.xls ]`: บันทึกข้อมูลลงไฟล์ตารางคำนวณในเครื่อง พร้อมเมนูแชร์ไฟล์ (LINE, Drive, Gmail)
  - `[ Data ]`: เปิดดูประวัติตารางบันทึกข้อมูลย้อนหลัง และค่าเฉลี่ยสถิติ
  - `[ Gallery ]`: คลังภาพถ่ายและวิดีโออัจฉริยะ (Soil AI Media & Dataset Explorer) พร้อมระบบซูมเนื้อดิน (Pinch-to-zoom) และปุ่มแชร์ด่วน
- **Status Header:** แสดงสถานะการเชื่อมต่อ USB OTG พร้อมพิกัด GPS สด, ปุ่ม AI Vision & GPS, ปุ่มเปิดคลังภาพ, และปุ่มเปิด/ปิด **Demo Simulation Mode** สำหรับทดสอบได้ทันที
- **Floating Action Button:** `[ AI Vision & GPS ]` สำหรับเปิดกล้องส่องแปลงดิน ถ่ายภาพและบันทึกวิดีโอพร้อมข้อมูล Telemetry ลอยบนจอแบบเรียลไทม์

---

## 📷 คลังภาพ วิดีโอ และการระบุพิกัดดาวเทียม (AI Vision, GPS & Media Gallery)

1. **Automated GPS Geotagging:** ดึงพิกัดจากชิปดาวเทียมในสมาร์ตโฟน (Latitude, Longitude, Altitude MSL) บันทึกลงในทุกภาพถ่าย วิดีโอ และตาราง CSV อัตโนมัติ
2. **AI Vision & Live Telemetry HUD:** กล้องถ่ายภาพและบันทึกวิดีโอแปลงดิน พร้อมแสดงผลพารามิเตอร์ดิน 8 ค่าและพิกัด GPS ซ้อนทับบนภาพสดแบบเรียลไทม์
3. **Soil AI Media Gallery:** หน้าต่างรวบรวมภาพถ่ายและวิดีโอทั้งหมดในเครื่อง พร้อมตัวกรองประเภทสื่อและสถิติขนาดพื้นที่หน่วยความจำ
4. **Pinch-to-zoom & Telemetry HUD:** แตะเปิดดูภาพขนาดใหญ่ ซูมดูรายละเอียดเนื้อดินได้ 4 เท่า พร้อมแผงข้อมูลการตรวจวัด 8-in-1 และค่าสอบเทียบ AI PINN
5. **Smart Sharing:** กดแชร์ภาพถ่ายหรือวิดีโอพร้อมข้อความสรุปค่าวิเคราะห์ดินทั้งหมดไปยัง LINE, Facebook, Google Drive, Gmail, WhatsApp ได้ใน 1 คลิก
6. **AI Training Dataset:** ข้อมูลถูกบันทึกลง `/Android/data/com.agriphysics.soil_app/files/soil_dataset/` พร้อมไฟล์ `dataset_manifest.json` สำหรับนำไปเทรนโมเดล Multimodal AI ในคอมพิวเตอร์ต่อยอดทันที

---

## 🔌 ข้อกำหนดฮาร์ดแวร์และการสื่อสาร (Hardware Interface & Protocol)

### 1. การเชื่อมต่อ USB Type-C OTG
- หัวโพรบ **Soil Parameter Tester** เชื่อมต่อโดยตรงเข้ากับพอร์ต Type-C ของสมาร์ตโฟน/แท็บเล็ต Android ในโหมด **USB Host (OTG)**
- ภายในมีชิป USB-to-UART/RS485 บริดจ์ เช่น **CH340, CP2102, FTDI หรือ PL2303**
- แอปพลิเคชันมี `device_filter.xml` และระบบขออนุญาตสิทธิ์การเข้าถึง USB อัตโนมัติ

### 2. โปรโตคอล Modbus RTU Framing
- **Baud rate:** `4800 bps` (ค่าเริ่มต้นมาตรฐานของหัววัดดินจีน) หรือ `9600 bps`
- **Data frame:** `8-N-1` (8 Data bits, No parity, 1 Stop bit)
- **Slave ID:** `0x01`
- **คำสั่งอ่านข้อมูล 8 พารามิเตอร์ (Function 0x03):**
  ```hex
  01 03 00 00 00 08 44 0C
  ```
- **โครงสร้างข้อมูลตอบกลับ (Response Frame 21 Bytes):**
  ```
  [01] [03] [10] [Moisture 2B] [Temp 2B] [EC 2B] [pH 2B] [N 2B] [P 2B] [K 2B] [Fertility 2B] [CRC_L] [CRC_H]
  ```

| Register Offset | Parameter | Scale Factor | Range | Unit |
| :---: | :--- | :---: | :---: | :---: |
| `0x0000` | Soil Moisture | `/ 10.0` | 0.0 - 100.0 | `%` |
| `0x0001` | Soil Temperature | `/ 10.0` (Signed) | -40.0 - 80.0 | `°C` |
| `0x0002` | Electrical Conductivity (EC) | `1.0` | 0 - 20,000 | `µS/cm` |
| `0x0003` | Soil pH | `/ 10.0` หรือ `/ 100.0` | 3.00 - 10.00 | `pH` |
| `0x0004` | Nitrogen (N) | `1.0` | 0 - 1,999 | `mg/kg` |
| `0x0005` | Phosphorus (P) | `1.0` | 0 - 1,999 | `mg/kg` |
| `0x0006` | Potassium (K) | `1.0` | 0 - 1,999 | `mg/kg` |
| `0x0007` | Soil Fertility Index | `1.0` | 0 - 1,999 | `mg/kg` |

---

## 🏗️ โครงสร้างโค้ดตาม Clean Architecture (MVVM)

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # รหัสสี 8 พารามิเตอร์
│   │   └── sensor_constants.dart   # ค่าคงที่ Modbus, ค่าเริ่มต้น
│   └── theme/
│       └── app_theme.dart          # ธีม Material 3 คอนทราสต์สูง
├── data/
│   ├── models/
│   │   ├── soil_reading.dart       # โมเดลข้อมูลและแปลง CSV
│   │   └── modbus_parser.dart      # ตัวถอดรหัส Modbus RTU & CRC-16
│   ├── services/
│   │   ├── usb_sensor_service.dart # ติดต่อฮาร์ดแวร์ USB Serial & Simulator
│   │   └── export_service.dart     # จัดการบันทึกและแชร์ไฟล์
│   └── repositories/
│       └── soil_sensor_repository.dart # บัฟเฟอร์ประวัติข้อมูล 1,000 จุด
├── domain/
│   └── models/
│       └── agronomic_assessment.dart # เครื่องมือวิเคราะห์ปฐพีวิทยา
└── ui/
    ├── viewmodels/
    │   └── soil_sensor_viewmodel.dart # ChangeNotifier จัดการ State
    ├── views/
    │   ├── home_dashboard_screen.dart # หน้าหลัก 8 การ์ดพารามิเตอร์
    │   ├── historical_data_screen.dart# หน้ารายการบันทึกข้อมูลย้อนหลัง
    │   └── settings_screen.dart     # หน้าตั้งค่า Baud rate และฮาร์ดแวร์
    └── widgets/
        ├── parameter_card.dart       # วิดเจ็ตการ์ดพารามิเตอร์
        ├── status_header.dart        # แถบ Header แสดงสถานะ USB
        └── agronomic_summary_sheet.dart # แผ่นป๊อปอัปคำแนะนำการใส่ปุ๋ย
```

---

## 🚀 วิธีการทดสอบและใช้งาน

### 1. ทดสอบโหมดจำลอง (Interactive Demo Simulation)
- เมื่อเปิดแอปพลิเคชัน สามารถกดที่ไอคอน **ขวดทดลอง/สัญลักษณ์วิทยาศาสตร์** ที่มุมซ้ายบนของ Header เพื่อเปิด **Simulation Mode**
- แอปจะจำลองสตรีมข้อมูลที่มีการเคลื่อนไหวตามธรรมชาติของดินจริงแบบไดนามิก เพื่อทดสอบการเรนเดอร์ UI และฟังก์ชันบันทึกข้อมูลได้ทันทีโดยไม่ต้องต่อฮาร์ดแวร์

### 2. รันบนเครื่องจริง Android (USB OTG)
```bash
# ติดตั้ง dependencies
flutter pub get

# รันแอปไปยังอุปกรณ์ Android ที่ต่อผ่าน USB Debugging
flutter run -d <android-device-id>

# หรือบิลด์เป็นไฟล์ APK สำหรับนำไปติดตั้งในสมาร์ตโฟน
flutter build apk --release
```
*ไฟล์ APK จะถูกสร้างขึ้นที่ `build/app/outputs/flutter-apk/app-release.apk`*

---

## 🌾 ฟังก์ชันการประเมินทางปฐพีวิทยา (Agronomic Assessment)
เมื่อแตะที่การ์ดพารามิเตอร์ใดๆ ระบบจะแสดง **Agronomic Summary Sheet**:
- **ประเมินความชื้น:** แจ้งเตือนดินแห้ง (ขาดน้ำ) หรือดินแฉะ (เสี่ยงรากเน่า)
- **ประเมินความเค็ม:** เตือนอันตรายจากเกลือปุ๋ยสะสมเกินมาตรฐาน
- **ประเมินกรด-ด่าง:** คำแนะนำการใส่โดโลไมต์ปรับปรุงดินกรด หรือยิปซัมปรับปรุงดินด่าง
- **สัดส่วน N-P-K:** สรุปปริมาณธาตุอาหารหลัก 3 ตัวเพื่อวางแผนการใส่ปุ๋ยแม่นยำ
