# 🧪 SoilpH-HT (Deep Learning Soil pH & HT Error Compensation System)
## แอปพลิเคชันตรวจวัดและวิเคราะห์ค่ากรด-ด่างของดิน ชดเชยความคลาดเคลื่อนจากอุณหภูมิและความชื้นด้วยโครงข่ายประสาทเทียมเชิงฟิสิกส์ (PINN)

<p align="center">
  <img src="assets/icons/app_icon.jpg" alt="SoilpH-HT App Icon" width="300" />
</p>

แอปพลิเคชันระบบปฏิบัติการ Android พัฒนาด้วย Flutter เพื่อใช้สำหรับงานวิจัยและการเกษตรแม่นยำขั้นสูง ออกแบบมาเพื่อตรวจวัดและวินิจฉัยค่าความเป็นกรด-ด่างของดิน (Soil pH) ที่เชื่อมต่อกับหัววัดเซนเซอร์ผ่านพอร์ต USB Type-C OTG (RS485 Modbus RTU) หรือทดสอบผ่านระบบจำลองสถานการณ์ดินเสมือนจริง โดยมีหัวใจหลักคือระบบชดเชยค่าความคลาดเคลื่อนจากอุณหภูมิ (Temperature - T) และความชื้นสัมพัทธ์ในดิน (Humidity/Moisture - H) แบบ Real-Time ด้วยแบบจำลองโครงข่ายประสาทเทียมเชิงฟิสิกส์ (Physics-Informed Neural Network - PINN) ทำงานแบบ Edge AI ภายในอุปกรณ์ 100% (Offline On-Device Inference)

---

## 🔬 ทฤษฎีและสมการฟิสิกส์การชดเชยค่า pH (Physics Formulation)

ในการวัดค่า pH ในดินจริงด้วยหัววัดเคมีไฟฟ้า (Electrochemical Glass/Metal-Oxide Electrode) หรือเซนเซอร์ ISFET ค่าศักย์ไฟฟ้าที่วัดได้จะมีความสัมพันธ์โดยตรงกับอุณหภูมิและความชื้นในสารละลายดิน ดังนี้

### 1. ความคลาดเคลื่อนจากอุณหภูมิตามสมการเนิร์นสต์ (Nernst Temperature Slope)
ตามสมการเนิร์นสต์ (Nernst Equation)
$$E = E_0 - \frac{2.303 R T}{F} \text{pH}$$

โดยมีตัวแปรอ้างอิงประกอบด้วย
- $R = 8.314462 \, \text{J}\cdot\text{mol}^{-1}\cdot\text{K}^{-1}$ (Gas Constant)
- $F = 96485.332 \, \text{C}\cdot\text{mol}^{-1}$ (Faraday Constant)
- $T_K = 273.15 + T$ (Absolute Temperature ในหน่วย Kelvin)

ความชันเนิร์นสต์ (Nernstian Slope) จะแปรผันตามอุณหภูมิ ได้แก่
- ที่ $0^\circ\text{C}$ ได้ค่าความชัน $S = 54.20 \, \text{mV/pH}$
- ที่ $25^\circ\text{C}$ (มาตรฐานอ้างอิง) ได้ค่าความชัน $S_{25} = 59.16 \, \text{mV/pH}$
- ที่ $45^\circ\text{C}$ ได้ค่าความชัน $S = 63.12 \, \text{mV/pH}$

หากเซนเซอร์ไม่ได้ชดเชยอุณหภูมิตามเวลาจริง ค่า pH ที่อ่านได้จะคลาดเคลื่อนจากจุด Isopotential ($pH_{\text{iso}} \approx 7.00$) ตามสมการ
$$\Delta pH_{T,\text{Nernst}} = (pH_{\text{raw}} - 7.00) \times \left(1.0 - \frac{298.15}{273.15 + T}\right)$$

นอกจากนี้ การแตกตัวของน้ำและกรดในสารละลายดิน ($pK_w(T)$) จะเลื่อนตามอุณหภูมิ จึงมีพจน์ชดเชยการแตกตัวของสารละลายตามสมการ
$$\Delta pH_{T,\text{dissoc}} = -0.0065 \times (T - 25.0)$$

### 2. ความคลาดเคลื่อนจากความชื้นดิน (Moisture Impedance & Dilution)
- **สภาวะดินแห้งแล้ง ($M < 30\%$ VWC)** ฟิล์มน้ำรอบอนุภาคดินขาดความต่อเนื่อง ทำให้เกิดความต้านทานรอยต่ออิเล็กโทรด (Liquid-Junction Contact Impedance) สูงมาก ส่งผลให้ศักย์ไฟฟ้ารอยต่อคลาดเคลื่อน (Positive Drift) สูงเกินจริง
  $$\Delta pH_{M,\text{dry}} = -0.015 \times (30.0 - M)^{1.15} \quad (\text{เมื่อ } M < 30\%)$$
- **สภาวะดินน้ำขัง ($M > 65\%$ VWC)** ปริมาณน้ำอิสระเจือจางความเข้มข้นของไฮโดรเจนไอออนในดินกรด ทำให้ค่า pH ลอยสูงขึ้นเข้าหา 7.0
  $$\Delta pH_{M,\text{dilution}} = -0.007 \times (M - 65.0) \quad (\text{สำหรับดินกรด})$$

### 3. แบบจำลองโครงข่ายประสาทเทียม PINN (High-Order Cross-Coupling)
เพื่อจับปฏิสัมพันธ์ที่ไม่เป็นเชิงเส้น (Nonlinear Dielectric & Electrolyte Interactions) โมเดล Deep Learning โครงสร้าง MLP 3 ชั้น ประกอบด้วย
- **คุณลักษณะนำเข้า (5 Input Features)**
  1. $norm(T) = (T - 25.0) / 12.0$
  2. $norm(M) = (M - 50.0) / 25.0$
  3. $norm(EC) = (EC - 600.0) / 500.0$
  4. $norm(pH_{\text{raw}}) = (pH_{\text{raw}} - 6.5) / 1.5$
  5. $norm(HT) = norm(T) \times \ln(M / 50.0)$
- **โครงสร้างชั้นซ่อนเร้นที่ 1 (Hidden Layer 1)** แปลงจาก 5 เซลล์ประสาทไปสู่ 10 เซลล์ประสาท ร่วมกับฟังก์ชันกระตุ้น Swish
- **โครงสร้างชั้นซ่อนเร้นที่ 2 (Hidden Layer 2)** แปลงจาก 10 เซลล์ประสาทไปสู่ 6 เซลล์ประสาท ร่วมกับฟังก์ชันกระตุ้น GELU
- **โครงสร้างชั้นซ่อนเร้นที่ 3 (Hidden Layer 3)** แปลงจาก 6 เซลล์ประสาทไปสู่ 3 เซลล์ประสาท ร่วมกับฟังก์ชันกระตุ้น LeakyReLU
- **ผลลัพธ์เวกเตอร์พยากรณ์** ได้แก่ $[\Delta pH_{\text{PINN}}, \sigma_{\text{uncertainty}}, \text{ContactQuality}]$
- **สมการประเมินค่า pH สุทธิ**
  $$pH_{\text{calibrated}} = \text{clamp}(pH_{\text{raw}} + \Delta pH_{T} + \Delta pH_{M} + \Delta pH_{\text{PINN}}, 3.00, 10.00)$$

---

## 🌟 จุดเด่นและคุณสมบัติของแอปพลิเคชัน

1. **หน้าปัดเกจวัด pH ทรงกลมความแม่นยำสูง (Circular pH Dial Gauge)**
   - เรนเดอร์ด้วย Custom Painter พร้อมแสงนีออนเรืองรอง (Neon Glow)
   - แถบสีแบ่งระดับตามมาตรฐาน FAO และกรมพัฒนาที่ดิน (LDD) รวม 10 ระดับ
   - ป้ายระบุส่วนต่างการชดเชยแบบเรียลไทม์ ($\Delta pH$)
2. **การ์ดวิเคราะห์ความคลาดเคลื่อน HT และระบบอธิบายผล AI (XAI Card)**
   - แสดงเวกเตอร์อุณหภูมิ (Nernst Factor) และเวกเตอร์ความชื้น (Impedance Factor)
   - คะแนนความเชื่อมั่นของโมเดล AI (Confidence Score %)
   - คำอธิบายปรากฏการณ์ทางกายภาพแบบเข้าใจง่าย
3. **การประเมินการปลดปล่อยธาตุอาหารพืช 10 ชนิด (Nutrient Bioavailability Chart)**
   - คำนวณความพร้อมใช้ของธาตุอาหารหลัก ธาตุอาหารรอง และจุลธาตุ (N, P, K, Ca, Mg, S, Fe, Mn, Zn, Cu, B, Mo) ที่ระดับ pH ปัจจุบัน
   - แตะที่ธาตุอาหารเพื่อดูผลกระทบและกลไกทางเคมีปฐพีวิทยา
4. **ใบสั่งสูตรปูนและสารปรับปรุงดินเฉพาะแปลง (Lime & Soil Amendment Prescription)**
   - เลือกลักษณะเนื้อดิน ได้แก่ ดินทราย (Sandy) ดินร่วน (Loam) ดินเหนียว (Clay) ตามความจุบัฟเฟอร์
   - คำนวณปริมาณปูนโดโลไมต์ ($CaMg(CO_3)_2$) ปูนขาว ($CaCO_3$) หรือยิปซัมเกษตร ($CaSO_4$) ในหน่วย กิโลกรัมต่อไร่
   - แนวทางปฏิบัติการใส่ปูนอย่างถูกวิธีเพื่อป้องกันอันตรายต่อพืช
5. **ระบบเตือนภัยความเป็นพิษของดิน (Toxicity Alert)**
   - ตรวจจับและแจ้งเตือนอันตรายจากพิษไอออนอะลูมิเนียม ($Al^{3+}$) และแมงกานีส ($Mn^{2+}$) เมื่อดินเป็นกรดรุนแรง ($pH < 5.0$)
6. **ระบบจำลองสภาพดิน 5 สถานการณ์ (Interactive Dynamic Soil Simulation)**
   - แปลงดินแล้งแดดจัด ($38.5^\circ\text{C}, 14.5\%$ VWC)
   - แปลงที่ลุ่มน้ำขังดินเปรี้ยว ($27.5^\circ\text{C}, 82.0\%$ VWC)
   - แปลงที่สูงอากาศหนาว ($14.2^\circ\text{C}, 54.0\%$ VWC)
   - แปลงเรือนกระจกมาตรฐาน ($25.0^\circ\text{C}, 50.0\%$ VWC)
   - ดินเค็มด่างชายทะเล ($33.0^\circ\text{C}, 28.0\%$ VWC, EC $4800 \, \mu\text{S/cm}$)
7. **การเชื่อมต่อหัววัดจริงผ่าน USB OTG (RS485 Modbus RTU)**
   - รองรับชิปบริดจ์ USB ยอดนิยม ได้แก่ CH340, CP2102, FTDI, PL2303, CDC ACM
   - สลับ Baud Rate ได้ ได้แก่ 4800, 9600, 19200, 115200 bps
8. **บันทึกประวัติและส่งออกข้อมูล (History & CSV Export)**
   - บันทึกการตรวจวัดย้อนหลัง 500 จุด
   - ส่งออกเป็นไฟล์ CSV พร้อมค่าชดเชยรายมิติผ่าน Android Native Share Sheet

---

## 🏗️ สถาปัตยกรรมซอฟต์แวร์ (Clean Architecture & MVVM)

```
SoilpH_HT/
├── android/                             # การตั้งค่า Native Android, USB Permissions & Filters
│   └── app/src/main/
│       ├── AndroidManifest.xml          # สิทธิ์ USB Host, Storage, Location
│       └── res/xml/device_filter.xml    # รายการ USB Vendor IDs สำหรับหัววัด RS485
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── ph_colors.dart           # รหัสสี pH 10 ช่วงตามเกณฑ์ LDD/FAO
│   │   │   └── sensor_constants.dart   # คำสั่ง Modbus RTU และค่าคงที่มาตรฐาน
│   │   ├── theme/
│   │   │   └── app_theme.dart          # ธีม Cyber-Agri Dark UI
│   │   └── utils/
│   │       └── crc16.dart               # อัลกอริทึมคำนวณ Modbus RTU CRC-16
│   ├── data/
│   │   ├── models/
│   │   │   └── ph_sensor_reading.dart   # โมเดลข้อมูล SoilPhReading & CalibratedPhResult
│   │   ├── services/
│   │   │   ├── usb_ph_service.dart      # ไดรเวอร์สื่อสาร USB OTG RS485
│   │   │   ├── simulation_service.dart  # เอนจินจำลองฟิสิกส์ดิน 5 สถานการณ์
│   │   │   └── export_service.dart      # ส่งออกผลตรวจเป็นไฟล์ CSV
│   │   └── repositories/
│   │       └── ph_repository.dart       # ศูนย์กลางจัดการสตรีมข้อมูลเซนเซอร์
│   ├── domain/
│   │   ├── ml/
│   │   │   └── ph_deep_pinn_model.dart  # แบบจำลองโครงข่ายประสาทเทียม PINN ชดเชย HT
│   │   └── models/
│   │       ├── agronomic_rules.dart     # ตารางการดูดซึมธาตุอาหาร 10 ชนิดและพิษโลหะ
│   │       └── lime_prescription.dart   # การคำนวณอัตราปูนโดโลไมต์ตามเนื้อดิน
│   ├── ui/
│   │   ├── viewmodels/
│   │   │   └── ph_monitor_viewmodel.dart# การจัดการสถานะด้วย ChangeNotifier
│   │   ├── views/
│   │   │   ├── splash_screen.dart       # แอนิเมชันเปิดแอป Cyber Neon Ring
│   │   │   ├── ph_dashboard_screen.dart # หน้าหลัก Live Dial, HT Card, Action Buttons
│   │   │   ├── ph_analytics_screen.dart # หน้าเจาะลึกธาตุอาหารและใบสั่งปูน
│   │   │   ├── ph_history_screen.dart   # หน้าประวัติการตรวจวัดและส่งออก
│   │   │   └── ph_settings_screen.dart  # หน้าตั้งค่า Baud Rate และสลับโหมดจำลองดิน
│   │   └── widgets/
│   │       ├── ph_circular_gauge.dart   # วิดเจ็ตหน้าปัดเกจวัด pH เรืองแสง
│   │       ├── ht_compensation_card.dart# วิดเจ็ตแจกแจงเวกเตอร์ความคลาดเคลื่อน HT
│   │       ├── nutrient_availability_chart.dart # วิดเจ็ตกราฟแท่งธาตุอาหาร 10 ชนิด
│   │       └── status_app_bar.dart      # แถบ Header แสดงสถานะ USB และ AI PINN
│   └── main.dart                        # Entry Point พร้อม MultiProvider
├── test/
│   └── ph_deep_pinn_model_test.dart     # Unit Tests ทดสอบโมเดล PINN และกฎปฐพีวิทยา
└── pubspec.yaml                         # รายการไลบรารีที่จำเป็น
```

---

## 🚀 วิธีการทดสอบและใช้งาน (Quick Start)

### 1. ทดสอบผ่านโหมดจำลอง (Interactive Simulation)
1. เปิดแอปพลิเคชัน ระบบจะเริ่มต้นใน **โหมดจำลอง (Simulation Mode)** อัตโนมัติ เพื่อให้สามารถดูผลลัพธ์ กราฟหน้าปัด และการชดเชยค่าความคลาดเคลื่อนได้ทันทีโดยไม่ต้องต่อสายเซนเซอร์
2. สามารถแตะที่ปุ่ม **SIM** หรือเข้าไปที่เมนูการตั้งค่า (รูปฟันเฟืองและปรับจูน) เพื่อเลือกสลับสถานการณ์ดิน เช่น ดินแล้งแดดจัด ดินน้ำขัง ดินหนาวบนดอย หรือดินเค็มชายทะเล
3. แตะที่ปุ่มสลับ **PINN ON / RAW** บนแถบ Header เพื่อเปรียบเทียบค่า pH จริงจากเซนเซอร์กับค่าที่ผ่านการชดเชยด้วย Deep Learning

### 2. รันแอปพลิเคชันบนสมาร์ตโฟน Android (USB OTG)
```bash
# นำทางไปยังโฟลเดอร์โครงการ
cd SoilpH_HT

# ติดตั้ง Dependencies
flutter pub get

# ตรวจสอบความสมบูรณ์ของโค้ดและการทดสอบ
flutter test
flutter analyze

# รันแอปไปยังอุปกรณ์ Android ที่เชื่อมต่อ USB Debugging
flutter run -d <android-device-id>

# หรือบิลด์เป็นไฟล์ APK สำหรับนำไปแจกจ่ายและติดตั้ง
flutter build apk --release
```
*ไฟล์ APK จะถูกสร้างขึ้นที่ `SoilpH_HT/build/app/outputs/flutter-apk/app-release.apk`*
