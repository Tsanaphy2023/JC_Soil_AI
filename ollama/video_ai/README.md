# ระบบสร้างวิดีโอ AI ออฟไลน์ด้วย Ollama + Local Video Engine
### (Ollama AI Director & Metal MPS Video Pipeline สำหรับ macOS Apple Silicon)

คู่มือการใช้งานเครื่องมือสร้างวิดีโอ AI ในเครื่อง (Local Video Generation) แบบฟรี 100% ไม่ต้องต่ออินเทอร์เน็ต และเชื่อมต่อกับ Ollama โดยตรง

---

## 🌟 สถาปัตยกรรมการทำงาน (Architecture)

```
+-------------------------------------------------------------------+
|               1. ผู้ใช้ใส่ไอเดีย (ภาษาไทยหรืออังกฤษ)               |
|      เช่น "โดรนบินตรวจสวนทุเรียนที่มีเซนเซอร์วัดดินตอนเช้า"       |
+---------------------------------+---------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|              2. Ollama Custom Model: video-director               |
|  - ทำหน้าที่เป็น "AI Director / ผู้กำกับภาพยนตร์"                |
|  - ออกแบบ Text-to-Video Visual Prompt ภาษาอังกฤษระดับ Cinematic  |
|  - กำหนดทิศทางการเคลื่อนกล้อง (Camera Motion: Pan, Zoom, Orbit)   |
|  - คำนวณเฟรมเรตและกำหนด Negative Prompt เพื่อภาพที่นิ่ง ไม่กระพริบ  |
+---------------------------------+---------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|              3. Local Video Diffusion Engine (PyTorch MPS)        |
|  - ขับเคลื่อนด้วย Apple Silicon Metal GPU (24GB Unified Memory)   |
|  - Text-to-Video: ali-vilab/text-to-video-ms-1.7b                 |
|  - Image-to-Video: stabilityai/stable-video-diffusion-img2vid-xt  |
|  - เรนเดอร์ไฟล์ .mp4 ความละเอียดสูงลงโฟลเดอร์ output_videos/      |
+-------------------------------------------------------------------+
```

---

## 🛠️ สิ่งที่ติดตั้งและพร้อมใช้งานแล้วในเครื่อง

1. **โมเดลผู้กำกับใน Ollama (`video-director:latest`):**
   - ติดตั้งอยู่ใน Ollama เรียบร้อยแล้ว
   - สามารถเรียกคุยสดเพื่อขอไอเดียหรือบทกำกับได้ทันทีผ่านคำสั่ง:
     ```bash
     ollama run video-director
     ```

2. **สภาพแวดล้อม Python Video AI (`~/ai_video_env`):**
   - ติดตั้ง PyTorch 2.14.0 พร้อมเปิดใช้งาน **Metal Performance Shaders (MPS: True)**
   - ติดตั้ง Diffusers, Transformers, Accelerate, ImageIO และ FFmpeg

3. **สคริปต์รันอัตโนมัติ (CLI Tool):**
   - [`ollama_video_generator.py`](file:///Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/ollama_video_generator.py)
   - [`run_video.sh`](file:///Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/run_video.sh) (ไฟล์เรียกใช้งานแบบบรรทัดเดียว)

---

## 🚀 วิธีการใช้งาน (How to Use)

### 1. สั่งสร้างวิดีโอจากไอเดียภาษาไทย (Text-to-Video ผ่าน Ollama Director)
เปิด Terminal แล้วเข้าไปที่โฟลเดอร์ หรือพิมพ์คำสั่ง:
```bash
/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/run_video.sh -p "โดรนบินตรวจสวนทุเรียนตอนเช้า แสงแดดสีทอง"
```
*ระบบจะเรียก Ollama แปลงเป็น Cinematic Prompt -> ขยายมุมกล้อง -> ส่งเข้าโมเดล Video AI -> บันทึกไฟล์ `.mp4` อัตโนมัติ*

### 2. สั่งสร้างวิดีโอจากรูปภาพนิ่ง (Image-to-Video ด้วย SVD)
หากมีภาพนิ่งที่สร้างจาก DiffusionBee หรือภาพถ่ายแปลงเกษตร:
```bash
/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/run_video.sh -i "/path/to/soil_photo.png"
```

### 3. สลับใช้โมเดล Ollama อื่นๆ เป็นผู้กำกับ
สามารถระบุโมเดลที่มีในเครื่อง เช่น `deepseek-r1:latest` หรือ `qwen2.5-coder:32b`:
```bash
/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/run_video.sh -p "หยดน้ำค้างซึมลงดิน" -m deepseek-r1:latest
```

### 4. ปรับจำนวนเฟรมและเฟรมเรต (Frames & FPS)
```bash
/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/run_video.sh -p "ใบไม้ไหวตามสายลม" --frames 24 --fps 12
```

---

## 📂 ระบบจัดเก็บไฟล์โปรเจกต์อย่างเป็นระบบ (Project Architecture)

ทุกครั้งที่มีการสร้างวิดีโอ ระบบจะสร้างโฟลเดอร์โปรเจกต์เฉพาะ พร้อมแยกเก็บไฟล์อย่างเป็นระบบดังนี้:

```text
output_videos/
├── INDEX.md                     # สารบัญ Master Catalog รวมทุกโปรเจกต์
└── projects/
    └── [รหัสโปรเจกต์]/
        ├── video.mp4            # ไฟล์วิดีโอตัวเต็ม (.mp4)
        ├── metadata.json        # ข้อมูล Prompt, Model, FPS, Resolution, Timestamp
        ├── README.md            # บันทึกรายละเอียดโปรเจกต์
        ├── audio/               # แทร็กเสียงดนตรีบรรเลง (.wav / .aac)
        └── thumbnails/          # ภาพนิ่งพรีวิวแต่ละฉาก (.png)
```

- 📖 **ดูสารบัญโปรเจกต์ทั้งหมดได้ที่:** [INDEX.md (Master Catalog)](file:///Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/INDEX.md)
- 📁 **โฟลเดอร์รวมโปรเจกต์:** [`output_videos/projects/`](file:///Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/projects/)

