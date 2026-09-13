enum AppLanguage {
  thai('th', 'ไทย', '🇹🇭'),
  english('en', 'English', '🇬🇧'),
  chinese('zh', '中文', '🇨🇳');

  final String code;
  final String label;
  final String flag;

  const AppLanguage(this.code, this.label, this.flag);

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'en':
        return AppLanguage.english;
      case 'zh':
        return AppLanguage.chinese;
      case 'th':
      default:
        return AppLanguage.thai;
    }
  }
}

class AppLocalizations {
  final AppLanguage language;

  const AppLocalizations(this.language);

  static const Map<String, Map<AppLanguage, String>> _strings = {
    // App Bar & Title
    'appName': {
      AppLanguage.thai: 'SOIL AI ANALYZER',
      AppLanguage.english: 'SOIL AI ANALYZER',
      AppLanguage.chinese: 'SOIL AI ANALYZER',
    },
    'appSubtitle': {
      AppLanguage.thai: 'ตัววิเคราะห์ดินอัจฉริยะ',
      AppLanguage.english: 'Digital Soil AI Analyzer',
      AppLanguage.chinese: '土壤智能分析仪',
    },

    // 8 Sensor Parameters
    'moisture': {
      AppLanguage.thai: 'ความชื้น',
      AppLanguage.english: 'Moisture',
      AppLanguage.chinese: '土壤水分',
    },
    'temperature': {
      AppLanguage.thai: 'อุณหภูมิ',
      AppLanguage.english: 'Temperature',
      AppLanguage.chinese: '土壤温度',
    },
    'conductivity': {
      AppLanguage.thai: 'สภาพนำไฟฟ้า(EC)',
      AppLanguage.english: 'Conductivity(EC)',
      AppLanguage.chinese: '电导率(EC)',
    },
    'ph': {
      AppLanguage.thai: 'กรด-ด่าง (pH)',
      AppLanguage.english: 'pH',
      AppLanguage.chinese: '酸碱度 (pH)',
    },
    'nitrogen': {
      AppLanguage.thai: 'ไนโตรเจน (N)',
      AppLanguage.english: 'Nitrogen (N)',
      AppLanguage.chinese: '氮 (N)',
    },
    'phosphorus': {
      AppLanguage.thai: 'ฟอสฟอรัส (P)',
      AppLanguage.english: 'Phosphorus (P)',
      AppLanguage.chinese: '磷 (P)',
    },
    'potassium': {
      AppLanguage.thai: 'โพแทสเซียม (K)',
      AppLanguage.english: 'Potassium (K)',
      AppLanguage.chinese: '钾 (K)',
    },
    'fertility': {
      AppLanguage.thai: 'ความอุดมสมบูรณ์',
      AppLanguage.english: 'Fertility',
      AppLanguage.chinese: '土壤肥力',
    },

    // Connection & Status Header
    'connected': {
      AppLanguage.thai: 'เชื่อมต่อแล้ว',
      AppLanguage.english: 'CONNECTED',
      AppLanguage.chinese: '已连接',
    },
    'disconnected': {
      AppLanguage.thai: 'ไม่ได้เชื่อมต่อ',
      AppLanguage.english: 'DISCONNECTED',
      AppLanguage.chinese: '未连接',
    },
    'connecting': {
      AppLanguage.thai: 'กำลังเชื่อมต่อ...',
      AppLanguage.english: 'CONNECTING...',
      AppLanguage.chinese: '正在连接...',
    },
    'aiCalibrationOn': {
      AppLanguage.thai: 'การสอบเทียบ AI: เปิด',
      AppLanguage.english: 'AI CALIBRATION: ON',
      AppLanguage.chinese: 'AI校准: 开启',
    },
    'aiCalibrationOff': {
      AppLanguage.thai: 'การสอบเทียบ AI: ปิด',
      AppLanguage.english: 'AI CALIBRATION: OFF',
      AppLanguage.chinese: 'AI校准: 关闭',
    },
    'gpsLocating': {
      AppLanguage.thai: 'GPS กำลังระบุพิกัด...',
      AppLanguage.english: 'Acquiring GPS...',
      AppLanguage.chinese: '正在获取GPS定位...',
    },
    'altitude': {
      AppLanguage.thai: 'ระดับน้ำทะเล',
      AppLanguage.english: 'Alt',
      AppLanguage.chinese: '海拔',
    },
    'probeLive': {
      AppLanguage.thai: 'หัววัดทำงานสด',
      AppLanguage.english: 'PROBE LIVE',
      AppLanguage.chinese: '探头在线',
    },
    'demoOffline': {
      AppLanguage.thai: 'โหมดสาธิต/ออฟไลน์',
      AppLanguage.english: 'DEMO/OFFLINE',
      AppLanguage.chinese: '演示/离线',
    },

    // Dashboard Buttons
    'saveTo': {
      AppLanguage.thai: 'บันทึกข้อมูล',
      AppLanguage.english: 'Save to',
      AppLanguage.chinese: '保存数据',
    },
    'aiVisionGps': {
      AppLanguage.thai: 'AI Vision & GPS',
      AppLanguage.english: 'AI Vision & GPS',
      AppLanguage.chinese: 'AI视觉与GPS',
    },
    'historicalData': {
      AppLanguage.thai: 'ประวัติการวัด',
      AppLanguage.english: 'Historical Data',
      AppLanguage.chinese: '历史数据',
    },
    'settings': {
      AppLanguage.thai: 'ตั้งค่าระบบ',
      AppLanguage.english: 'Settings',
      AppLanguage.chinese: '系统设置',
    },
    'gallery': {
      AppLanguage.thai: 'คลังภาพ & ข้อมูล',
      AppLanguage.english: 'Dataset Gallery',
      AppLanguage.chinese: '数据库相册',
    },
    'storageNotice': {
      AppLanguage.thai: 'ข้อมูลถูกจัดเก็บในหน่วยความจำเครื่อง (Soil_parameters.csv)',
      AppLanguage.english: 'Data stored in root storage (Soil_parameters.csv)',
      AppLanguage.chinese: '数据已保存在本地存储目录中 (Soil_parameters.csv)',
    },

    // Camera & Video
    'soilTargetZone': {
      AppLanguage.thai: 'เป้าหมายวัดเนื้อดิน',
      AppLanguage.english: 'SOIL TARGET ZONE',
      AppLanguage.chinese: '土壤目标检测区',
    },
    'photoMode': {
      AppLanguage.thai: 'PHOTO (ภาพถ่าย)',
      AppLanguage.english: 'PHOTO',
      AppLanguage.chinese: 'PHOTO (拍照)',
    },
    'videoMode': {
      AppLanguage.thai: 'VIDEO (วิดีโอ LIVE)',
      AppLanguage.english: 'VIDEO LIVE',
      AppLanguage.chinese: 'VIDEO (实时视频)',
    },
    'micOn': {
      AppLanguage.thai: 'เสียงเปิด',
      AppLanguage.english: 'MIC ON',
      AppLanguage.chinese: '声音开启',
    },
    'micOff': {
      AppLanguage.thai: 'ตัดเสียง',
      AppLanguage.english: 'NOISE CUT',
      AppLanguage.chinese: '消除噪音',
    },
    'micOnDesc': {
      AppLanguage.thai: 'เปิดไมโครโฟน: บันทึกวิดีโอพร้อมเสียงบรรยายและเสียงรอบข้าง',
      AppLanguage.english: 'Mic Enabled: Recording video with ambient sound & voice',
      AppLanguage.chinese: '已开启麦克风：录制包含环境声音与语音解说的视频',
    },
    'micOffDesc': {
      AppLanguage.thai: 'ปิดไมโครโฟน: ตัดเสียงรบกวนภายนอก 100% (Silent Video)',
      AppLanguage.english: 'Mic Muted: 100% External Noise Cancellation (Silent Video)',
      AppLanguage.chinese: '已关闭麦克风：100%消除外界噪音(静音视频)',
    },
    'photoSavedNotice': {
      AppLanguage.thai: 'บันทึกภาพและพิกัด GPS สำหรับเทรนโมเดลสำเร็จ',
      AppLanguage.english: 'Photo with Live Telemetry & GPS saved successfully',
      AppLanguage.chinese: '已成功保存包含遥测数据与GPS的土壤图像',
    },
    'videoSavedNotice': {
      AppLanguage.thai: 'บันทึกวิดีโอเรียบร้อย',
      AppLanguage.english: 'Video recorded successfully',
      AppLanguage.chinese: '视频录制完成并已保存',
    },
    'viewGallery': {
      AppLanguage.thai: 'ดูคลังภาพ',
      AppLanguage.english: 'View Gallery',
      AppLanguage.chinese: '查看相册',
    },
    'itemsCount': {
      AppLanguage.thai: 'รายการ',
      AppLanguage.english: 'items',
      AppLanguage.chinese: '条记录',
    },

    // Gallery Screen
    'galleryTitle': {
      AppLanguage.thai: 'คลังภาพ & ชุดข้อมูลวิจัยดิน',
      AppLanguage.english: 'Soil AI Media & Dataset Explorer',
      AppLanguage.chinese: '土壤AI多模态数据相册',
    },
    'gallerySubtitle': {
      AppLanguage.thai: 'ภาพถ่าย วิดีโอ และข้อมูลเซนเซอร์สำหรับเทรน AI',
      AppLanguage.english: 'Photos, Videos, and Sensor Data for AI Training',
      AppLanguage.chinese: '用于AI训练的照片、视频与多维传感器数据',
    },
    'photosCount': {
      AppLanguage.thai: 'ภาพถ่าย',
      AppLanguage.english: 'Photos',
      AppLanguage.chinese: '照片',
    },
    'videosCount': {
      AppLanguage.thai: 'วิดีโอ',
      AppLanguage.english: 'Videos',
      AppLanguage.chinese: '视频',
    },
    'geotaggedCount': {
      AppLanguage.thai: 'ระบุพิกัด GPS',
      AppLanguage.english: 'Geotagged',
      AppLanguage.chinese: 'GPS定位',
    },
    'storageSize': {
      AppLanguage.thai: 'พื้นที่จัดเก็บ',
      AppLanguage.english: 'Storage',
      AppLanguage.chinese: '占用空间',
    },
    'dataCount': {
      AppLanguage.thai: 'ข้อมูล CSV',
      AppLanguage.english: 'Data Files',
      AppLanguage.chinese: '数据文件',
    },
    'filterAll': {
      AppLanguage.thai: 'ทั้งหมด',
      AppLanguage.english: 'All',
      AppLanguage.chinese: '全部',
    },
    'filterPhotos': {
      AppLanguage.thai: 'ภาพถ่าย',
      AppLanguage.english: 'Photos',
      AppLanguage.chinese: '照片',
    },
    'filterVideos': {
      AppLanguage.thai: 'วิดีโอ',
      AppLanguage.english: 'Videos',
      AppLanguage.chinese: '视频',
    },
    'filterCsv': {
      AppLanguage.thai: 'ข้อมูล CSV & ตาราง',
      AppLanguage.english: 'CSV & Data',
      AppLanguage.chinese: 'CSV与数据',
    },
    'selectFiles': {
      AppLanguage.thai: 'เลือกไฟล์',
      AppLanguage.english: 'Select',
      AppLanguage.chinese: '选择',
    },
    'selectedCount': {
      AppLanguage.thai: 'เลือกแล้ว',
      AppLanguage.english: 'Selected',
      AppLanguage.chinese: '已选择',
    },
    'selectAll': {
      AppLanguage.thai: 'เลือกทั้งหมด',
      AppLanguage.english: 'Select All',
      AppLanguage.chinese: '全选',
    },
    'deselectAll': {
      AppLanguage.thai: 'ล้างการเลือก',
      AppLanguage.english: 'Deselect All',
      AppLanguage.chinese: '取消全选',
    },
    'shareSelected': {
      AppLanguage.thai: 'แชร์ที่เลือก',
      AppLanguage.english: 'Share Selected',
      AppLanguage.chinese: '分享已选',
    },
    'deleteSelected': {
      AppLanguage.thai: 'ลบที่เลือก',
      AppLanguage.english: 'Delete Selected',
      AppLanguage.chinese: '删除已选',
    },
    'deleteConfirmTitle': {
      AppLanguage.thai: 'ยืนยันการลบไฟล์',
      AppLanguage.english: 'Confirm Deletion',
      AppLanguage.chinese: '确认删除',
    },
    'deleteConfirmBatch': {
      AppLanguage.thai: 'คุณต้องการลบไฟล์ที่เลือกทั้งหมดออกจากหน่วยความจำอย่างถาวรหรือไม่?',
      AppLanguage.english: 'Permanently delete all selected files from device?',
      AppLanguage.chinese: '确定永久删除所有已选文件吗？',
    },
    'deleteSingleConfirm': {
      AppLanguage.thai: 'คุณต้องการลบไฟล์นี้ออกจากหน่วยความจำอย่างถาวรหรือไม่?',
      AppLanguage.english: 'Permanently delete this file?',
      AppLanguage.chinese: '确定永久删除此文件吗？',
    },
    'deletedSuccess': {
      AppLanguage.thai: 'ลบข้อมูลเรียบร้อยแล้ว',
      AppLanguage.english: 'Deleted successfully',
      AppLanguage.chinese: '删除成功',
    },
    'subfoldersOrganized': {
      AppLanguage.thai: 'แยกจัดเก็บตามโฟลเดอร์ย่อย: images/, videos/, data/',
      AppLanguage.english: 'Organized subfolders: images/, videos/, data/',
      AppLanguage.chinese: '系统化子文件夹存储: images/, videos/, data/',
    },
    'share': {
      AppLanguage.thai: 'แชร์',
      AppLanguage.english: 'Share',
      AppLanguage.chinese: '分享',
    },
    'shareDataset': {
      AppLanguage.thai: 'ส่งออกชุดข้อมูลวิจัย',
      AppLanguage.english: 'Export Dataset Package',
      AppLanguage.chinese: '导出研究数据集',
    },
    'viewGoogleMaps': {
      AppLanguage.thai: 'ดูตำแหน่งบน Google Maps',
      AppLanguage.english: 'View on Google Maps',
      AppLanguage.chinese: '在谷歌地图上查看',
    },
    'sensorGroundTruth': {
      AppLanguage.thai: 'ผลการตรวจวัดดินจริง (Ground-Truth)',
      AppLanguage.english: 'Sensor Ground-Truth Values',
      AppLanguage.chinese: '土壤传感器实测真值 (Ground-Truth)',
    },
    'aiConfidence': {
      AppLanguage.thai: 'ความเชื่อมั่นโมเดล AI',
      AppLanguage.english: 'AI Model Confidence',
      AppLanguage.chinese: 'AI模型置信度',
    },

    // Language Selector Dialog
    'selectLanguage': {
      AppLanguage.thai: 'เลือกภาษา (Select Language)',
      AppLanguage.english: 'Select Language',
      AppLanguage.chinese: '选择语言 (Select Language)',
    },
    'languageChanged': {
      AppLanguage.thai: 'เปลี่ยนภาษาเป็น ภาษาไทย เรียบร้อย',
      AppLanguage.english: 'Language changed to English',
      AppLanguage.chinese: '语言已切换为 中文',
    },

    // GIS Spatial Map & Certificate Extensions
    'gisMapTitle': {
      AppLanguage.thai: 'แผนที่แปลงดิน GIS & Heatmap',
      AppLanguage.english: 'GIS Soil Spatial Map & Heatmap',
      AppLanguage.chinese: 'GIS土壤空间分布与热力图',
    },
    'generateCertificate': {
      AppLanguage.thai: 'พิมพ์ใบรายงานผลตรวจดิน A4',
      AppLanguage.english: 'Generate Soil Certificate (A4)',
      AppLanguage.chinese: '生成土壤诊断报告书 (A4)',
    },
    'generatingCertificate': {
      AppLanguage.thai: 'กำลังสร้างใบรับรองคุณภาพดิน A4...',
      AppLanguage.english: 'Generating Soil Certificate A4...',
      AppLanguage.chinese: '正在生成A4土壤品质认证报告...',
    },
    'certificateGenerated': {
      AppLanguage.thai: 'สร้างใบรับรองผลตรวจดิน A4 สำเร็จ',
      AppLanguage.english: 'Soil Certificate A4 Generated Successfully',
      AppLanguage.chinese: '已成功生成A4土壤诊断证书',
    },
    'exportGeoJson': {
      AppLanguage.thai: 'ส่งออก GeoJSON (QGIS/GIS)',
      AppLanguage.english: 'Export GeoJSON (QGIS/GIS)',
      AppLanguage.chinese: '导出 GeoJSON (QGIS/GIS)',
    },
    'exportKml': {
      AppLanguage.thai: 'ส่งออก KML (Google Earth)',
      AppLanguage.english: 'Export KML (Google Earth)',
      AppLanguage.chinese: '导出 KML (Google Earth)',
    },
    'layerHealthScore': {
      AppLanguage.thai: '🟢 สุขภาพดินรวม (Health Score)',
      AppLanguage.english: '🟢 Soil Health Score',
      AppLanguage.chinese: '🟢 土壤综合健康度',
    },
    'layerPh': {
      AppLanguage.thai: '🧪 กรด-ด่าง (pH)',
      AppLanguage.english: '🧪 Soil pH',
      AppLanguage.chinese: '🧪 酸碱度 (pH)',
    },
    'layerMoisture': {
      AppLanguage.thai: '💧 ความชื้นในดิน (%)',
      AppLanguage.english: '💧 Moisture (%)',
      AppLanguage.chinese: '💧 土壤水分 (%)',
    },
    'layerEc': {
      AppLanguage.thai: '⚡ สภาพนำไฟฟ้า EC',
      AppLanguage.english: '⚡ Conductivity (EC)',
      AppLanguage.chinese: '⚡ 电导率 (EC)',
    },
    'layerNpk': {
      AppLanguage.thai: '🌿 ธาตุอาหาร N-P-K',
      AppLanguage.english: '🌿 N-P-K Nutrients',
      AppLanguage.chinese: '🌿 氮磷钾养分',
    },
    'openInGoogleMaps': {
      AppLanguage.thai: 'เปิดนำทางด้วย Google Maps',
      AppLanguage.english: 'Navigate via Google Maps',
      AppLanguage.chinese: '使用谷歌地图导航',
    },
    'totalSamplePoints': {
      AppLanguage.thai: 'จำนวนจุดสำรวจดิน',
      AppLanguage.english: 'Survey Sample Points',
      AppLanguage.chinese: '土壤采样测点总数',
    },
    'noGpsData': {
      AppLanguage.thai: 'ไม่พบพิกัด GPS ในตัวอย่างดินที่เลือก',
      AppLanguage.english: 'No GPS coordinates found in dataset',
      AppLanguage.chinese: '当前数据集中未检测到有效GPS坐标',
    },
    'selectPinToView': {
      AppLanguage.thai: 'แตะที่หมุดพิกัดเพื่อดูรายงานและค่าที่วัดได้',
      AppLanguage.english: 'Tap any coordinate pin to view sample telemetry',
      AppLanguage.chinese: '点击图钉查看该采样点遥测参数',
    },
    'basemapSatellite': {
      AppLanguage.thai: '🛰️ ภาพดาวเทียมจริง',
      AppLanguage.english: '🛰️ Satellite Imagery',
      AppLanguage.chinese: '🛰️ 真实卫星影像',
    },
    'basemapStreet': {
      AppLanguage.thai: '🗺️ แผนที่ถนน (OSM)',
      AppLanguage.english: '🗺️ Street Map (OSM)',
      AppLanguage.chinese: '🗺️ 街道地图 (OSM)',
    },
    'basemapOffline': {
      AppLanguage.thai: '⬛ ผังออฟไลน์ (Grid)',
      AppLanguage.english: '⬛ Offline Grid',
      AppLanguage.chinese: '⬛ 离线网格',
    },
    'toggleContour': {
      AppLanguage.thai: 'เส้นชั้น Contour',
      AppLanguage.english: 'Contour Isolines',
      AppLanguage.chinese: '等值线 (Contour)',
    },
    'toggleHeatmap': {
      AppLanguage.thai: 'พื้นผิว Heatmap',
      AppLanguage.english: 'Surface Heatmap',
      AppLanguage.chinese: '热力图图层',
    },
    'basemap': {
      AppLanguage.thai: 'แผนที่ฐาน',
      AppLanguage.english: 'Basemap',
      AppLanguage.chinese: '底图',
    },
  };

  String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[language] ?? entry[AppLanguage.thai] ?? key;
  }
}
