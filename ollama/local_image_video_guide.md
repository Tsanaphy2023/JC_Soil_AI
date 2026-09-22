# คู่มือการติดตั้งและใช้งาน AI สร้างภาพและวิดีโอในเครื่อง (Local Image & Video Generation Guide)
### สำหรับ macOS Apple Silicon (Unified Memory 24 GB) — ฟรี 100% ปลอดภัย ไม่ต้องต่อเน็ต ไม่จำกัดจำนวนครั้ง

---

## สารบัญ (Table of Contents)
1. [ความพร้อมและศักยภาพของฮาร์ดแวร์ (Hardware Capability)](#1-ความพร้อมและศักยภาพของฮาร์ดแวร์-hardware-capability)
2. [สรุปโมเดลฟรีที่ดีที่สุดสำหรับใช้งาน Local](#2-สรุปโมเดลฟรีที่ดีที่สุดสำหรับใช้งาน-local)
3. [ขั้นตอนการติดตั้งและเลือกโปรแกรม (Step-by-Step Installation)](#3-ขั้นตอนการติดตั้งและเลือกโปรแกรม-step-by-step-installation)
   - [แบบที่ 1: DiffusionBee (ติดตั้งอัตโนมัติ 1-Click GUI ง่ายที่สุด)](#แบบที่-1-diffusionbee-ติดตั้งอัตโนมัติ-1-click-gui-ง่ายที่สุด)
   - [แบบที่ 2: Draw Things (แอป Native Mac ฟรีจาก App Store รองรับ FLUX & SVD)](#แบบที่-2-draw-things-แอป-native-mac-ฟรีจาก-app-store-รองรับ-flux--svd)
   - [แบบที่ 3: ComfyUI (สำหรับผู้ใช้ขั้นสูงและโมเดลวิดีโอ Wan 2.1)](#แบบที่-3-comfyui-สำหรับผู้ใช้ขั้นสูงและโมเดลวิดีโอ-wan-21)
4. [คำศัพท์และพารามิเตอร์พื้นฐานที่ผู้เริ่มต้นต้องรู้](#4-คำศัพท์และพารามิเตอร์พื้นฐานที่ผู้เริ่มต้นต้องรู้)
5. [คลังตัวอย่างพร้อมพ์พร้อมใช้งาน (Curated Prompt Library)](#5-คลังตัวอย่างพร้อมพ์พร้อมใช้งาน-curated-prompt-library)
   - [หมวดที่ 1: การเกษตรแม่นยำและการวิเคราะห์ดิน (Smart Agriculture & Soil AI)](#หมวดที่-1-การเกษตรแม่นยำและการวิเคราะห์ดิน-smart-agriculture--soil-ai)
   - [หมวดที่ 2: งานสำนักงาน พรีเซนเทชัน และ WFH (Professional, Tech & Presentation)](#หมวดที่-2-งานสำนักงาน-พรีเซนเทชัน-และ-wfh-professional-tech--presentation)
   - [หมวดที่ 3: ภาพถ่ายบุคคลและธรรมชาติระดับสตูดิโอ (Cinematic & Photorealistic Portraits)](#หมวดที่-3-ภาพถ่ายบุคคลและธรรมชาติระดับสตูดิโอ-cinematic--photorealistic-portraits)
   - [หมวดที่ 4: พร้อมพ์สำหรับสร้างภาพเคลื่อนไหว/วิดีโอ (AI Video Generation Prompts)](#หมวดที่-4-พร้อมพ์สำหรับสร้างภาพเคลื่อนไหววิดีโอ-ai-video-generation-prompts)
6. [สูตรการเขียน Prompt ให้สวยสมบูรณ์แบบ (Pro Prompt Formula)](#6-สูตรการเขียน-prompt-ให้สวยสมบูรณ์แบบ-pro-prompt-formula)
7. [การทำงานร่วมกับ Ollama (ให้ Ollama เป็น Prompt Generator)](#7-การทำงานร่วมกับ-ollama-ให้-ollama-เป็น-prompt-generator)
8. [ระบบสร้างวิดีโออัตโนมัติ: Ollama Video Director + Local Video Engine](#8-ระบบสร้างวิดีโออัตโนมัติ-ollama-video-director--local-video-engine)

---

## 1. ความพร้อมและศักยภาพของฮาร์ดแวร์ (Hardware Capability)

จากผลการตรวจสอบสเปกเครื่อง Mac ของท่าน:
- **ชิปประมวลผล:** Apple Silicon (arm64 - สถาปัตยกรรม Metal GPU & Apple Neural Engine)
- **หน่วยความจำ (Unified Memory):** **24 GB RAM**
- **ระบบปฏิบัติการ:** macOS

> [!TIP]
> **แรม 24 GB Unified Memory ถือเป็นระดับ "Sweet Spot" สำหรับ Local AI!**
> ท่านสามารถโหลดโมเดล Image Generation ระดับเรือธงอย่าง **FLUX.1 [schnell]** หรือ **SDXL** และโมเดล Video Generation อย่าง **Wan 2.1 (1.3B)** หรือ **Stable Video Diffusion (SVD)** รันบนชิป Metal ได้อย่างราบรื่นโดยไม่ต้องพึ่งพาคลาวด์ภายนอก

---

## 2. สรุปโมเดลฟรีที่ดีที่สุดสำหรับใช้งาน Local

| ประเภท | ชื่อโมเดล | ความต้องการแรม | จุดเด่น | ลิขสิทธิ์ |
| :--- | :--- | :--- | :--- | :--- |
| **ภาพนิ่ง (Image)** | **FLUX.1 [schnell]** | ~12 - 16 GB | ลายเส้นคมชัด จัดการมือและข้อความภาษาอังกฤษได้สมบูรณ์แบบที่สุด ใช้เพียง 4-8 steps | Apache 2.0 (ฟรีเชิงพาณิชย์) |
| **ภาพนิ่ง (Image)** | **SDXL (RealVisXL / Juggernaut)** | ~8 - 12 GB | ภาพถ่ายเสมือนจริง รายละเอียดสกินโทนธรรมชาติ มีคอมมูนิตี้ LoRA ปรับแต่งหลากหลาย | Open Rail-M (ฟรี) |
| **วิดีโอ (Video)** | **Wan 2.1 (1.3B)** | ~8 - 12 GB | โมเดลวิดีโอ open-source รุ่นใหม่ล่าสุด การเคลื่อนไหวสมจริง ฟิสิกส์ธรรมชาติ ความคมชัดสูง | Apache 2.0 (ฟรี) |
| **วิดีโอ (Video)** | **Stable Video Diffusion (SVD)** | ~8 - 10 GB | แปลงภาพนิ่งเป็นคลิปวิดีโอสั้น (Image-to-Video) 2-4 วินาทีได้รวดเร็ว | Open Research (ฟรี) |

---

## 3. ขั้นตอนการติดตั้งและเลือกโปรแกรม (Step-by-Step Installation)

เรามี 3 ทางเลือกหลักที่ปรับแต่งให้เหมาะสมกับผู้ใช้ Mac ดังนี้:

### แบบที่ 1: DiffusionBee (ติดตั้งอัตโนมัติ 1-Click GUI ง่ายที่สุด)

**DiffusionBee** เป็นแอปพลิเคชัน GUI สำหรับ macOS โดยเฉพาะ พัฒนาขึ้นด้วย Metal/CoreML สำหรับ Apple Silicon โดยไม่ต้องเปิด Terminal เลยหลังจากติดตั้ง

#### วิธีการติดตั้ง:
ระบบสามารถติดตั้งผ่าน Homebrew Cask ในเครื่องของท่านได้ทันที:
```bash
brew install --cask diffusionbee
```
หรือดาวน์โหลดไฟล์ `.dmg` โดยตรงจาก: [https://diffusionbee.com](https://diffusionbee.com)

#### การเริ่มต้นใช้งาน:
1. เปิดแอปพลิเคชัน **DiffusionBee** จากโฟลเดอร์ Applications หรือผ่าน Spotlight Search (`Cmd + Space` พิมพ์ `DiffusionBee`)
2. เมื่อเปิดครั้งแรก โปรแกรมจะดาวน์โหลด Base Model เริ่มต้นให้อัตโนมัติ
3. หน้าจอหลักมีโหมดให้เลือก:
   - **Text to Image:** พิมพ์ข้อความแล้วสร้างภาพทันที
   - **Image to Image:** นำภาพร่างหรือภาพต้นแบบมาแปลงเป็นงานศิลปะใหม่
   - **Inpainting:** ลบหรือระบายทับบางส่วนของภาพเพื่อเปลี่ยนเฉพาะจุด
   - **Upscaling:** ขยายความละเอียดของภาพให้คมชัด 2x / 4x

---

### แบบที่ 2: Draw Things (แอป Native Mac ฟรีจาก App Store รองรับ FLUX & SVD)

**Draw Things** ถือเป็นแอป AI Studio ท้องถิ่นที่ดีที่สุดบน Apple Silicon ได้รับการปรับแต่งการประมวลผล 16-bit Neural Engine และ Metal Pipeline อย่างสมบูรณ์แบบ

#### วิธีการติดตั้ง:
1. เปิด **App Store** บนเครื่อง Mac
2. ค้นหาคำว่า **"Draw Things: AI Generation"** (หรือเปิดลิงก์: [Draw Things on Mac App Store](https://apps.apple.com/app/draw-things-ai-generation/id6444050820))
3. คลิก **"Get" (รับ)** หรือ **"Install"** ฟรี 100% ไม่มี in-app purchases แอบแฝง

#### การดาวน์โหลดโมเดล FLUX.1 [schnell] และ Video ใน Draw Things:
1. เปิดแอป Draw Things
2. ในแถบด้านซ้าย ช่อง **Model**:
   - คลิกที่ชื่อโมเดล แล้วเลือก **Manage...**
   - ค้นหา **FLUX.1 [schnell]** หรือ **RealVisXL v4.0** แล้วกดปุ่มดาวน์โหลด (ดาวน์โหลดเสร็จพร้อมใช้งานทันที)
3. หากต้องการสร้างวิดีโอ:
   - เลือกโมเดล **Stable Video Diffusion (SVD)** จากรายการ Manage
   - นำภาพที่สร้างไว้มาใส่ในช่อง Reference แล้วกด Generate Video

---

### แบบที่ 3: ComfyUI (สำหรับผู้ใช้ขั้นสูงและโมเดลวิดีโอ Wan 2.1)

หากท่านต้องการใช้โมเดลวิดีโอ **Wan 2.1 (1.3B)** ซึ่งให้คุณภาพวิดีโอเทียบเท่า Sora / Runway:

#### การติดตั้ง ComfyUI เบื้องต้น:
```bash
# 1. โคลนคลัง ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

# 2. สร้าง Python Virtual Environment และติดตั้ง Dependencies
python3 -m venv venv
source venv/bin/activate
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cpu
pip install -r requirements.txt

# 3. รันเซิร์ฟเวอร์ ComfyUI บน Mac (พร้อมเร่งความเร็วด้วย MPS/Metal)
python main.py --force-fp16
```
เปิดเบราว์เซอร์ไปที่ `http://127.0.0.1:8188` เพื่อลากวางโหนดการสร้างภาพและวิดีโอ

---

## 4. คำศัพท์และพารามิเตอร์พื้นฐานที่ผู้เริ่มต้นต้องรู้

| ค่าพารามิเตอร์ | ความหมาย | ค่าที่แนะนำสำหรับมือใหม่ |
| :--- | :--- | :--- |
| **Prompt (Positive)** | ข้อความบรรยายภาพที่ต้องการให้ AI สร้าง | ยิ่งระบุรายละเอียด สไตล์ แสง และมุมกล้องชัด ภาพยิ่งสวย |
| **Negative Prompt** | สิ่งที่**ไม่ต้องการ**ให้มีในภาพ | `ugly, blurry, low resolution, extra fingers, distorted, watermark` |
| **Steps** | จำนวนรอบที่ AI ขจัดสัญญาณรบกวน (Denoising) | **SDXL:** 25 - 35 steps<br>**FLUX.1 schnell:** 4 - 8 steps |
| **CFG Scale / Guidance** | ระดับความเคร่งครัดในการทำตาม Prompt | **SDXL:** 6.0 - 7.5<br>**FLUX.1:** 3.5 |
| **Resolution** | ขนาดกว้าง x สูงของรูปภาพ | จัตุรัส: `1024x1024`<br>แนวนอน: `1344x768` (16:9)<br>แนวตั้ง: `768x1344` (สำหรับมือถือ) |
| **Seed** | ตัวเลขสุ่มสร้างภาพ | ใส่ `-1` เพื่อสุ่มใหม่ทุกครั้ง หรือจดเลขเดิมไว้หากต้องการสร้างภาพเดิมซ้ำ |

---

## 5. คลังตัวอย่างพร้อมพ์พร้อมใช้งาน (Curated Prompt Library)

สามารถคัดลอกพรอมพ์ภาษาอังกฤษด้านล่างนี้ไปวางในช่อง **Prompt** ของ DiffusionBee หรือ Draw Things ได้ทันที:

### หมวดที่ 1: การเกษตรแม่นยำและการวิเคราะห์ดิน (Smart Agriculture & Soil AI)

#### ตัวอย่าง 1.1: เซนเซอร์วัดค่าดินอัจฉริยะในสวนทุเรียน (IoT Smart Soil Probe)
> **Prompt:**
> ```text
> High-tech stainless steel smart soil sensor probe inserted into rich dark organic agricultural soil in a lush durian orchard, digital OLED screen on top displaying glowing cyan soil telemetry data (Moisture 68%, pH 6.5, NPK levels), sunrise morning golden hour sunlight streaming through durian tree foliage, hyper-realistic, 8k resolution, macro photography, depth of field, clean technological aesthetic, cinematic lighting.
> ```
> **Negative Prompt:**
> ```text
> cartoon, anime, 3d render, blurry, distorted text, low quality, rusted metal, messy wiring, overexposed.
> ```

#### ตัวอย่าง 1.2: ผิวดินและเม็ดดินความละเอียดระดับจุลภาค (Macro Soil Minerals & Texture)
> **Prompt:**
> ```text
> Extreme macro close-up photography of fertile tropical loam soil, showing rich dark brown organic matter, subtle mineral crystal glints, microscopic moist water droplets reflecting warm ambient light, fine healthy root hairs gently weaving through soil crumbs, photorealistic, sharp focus, f/2.8 lens, professional science magazine quality.
> ```
> **Negative Prompt:**
> ```text
> artificial, plastic, blurry, dry cracked barren ground, oversaturated colors, out of focus.
> ```

#### ตัวอย่าง 1.3: แดชบอร์ดฟาร์มอัจฉริยะมุมมองสามมิติ (Isometric Smart Farm Telemetry)
> **Prompt:**
> ```text
> Isometric 3D rendering of a smart precision agriculture plot, miniature tropical fruit orchard with automated irrigation misting, small autonomous agricultural drone hovering above, transparent holographic data graphs floating in air showing moisture and nutrient heatmaps, clean minimalist tech style, soft studio lighting, Octane render, 8k.
> ```
> **Negative Prompt:**
> ```text
> flat, 2d, sketch, messy, dark, low quality, noisy background.
> ```

---

### หมวดที่ 2: งานสำนักงาน พรีเซนเทชัน และ WFH (Professional, Tech & Presentation)

#### ตัวอย่าง 2.1: โต๊ะทำงานสไตล์ Modern Minimalist WFH Studio
> **Prompt:**
> ```text
> Modern minimalist work from home desk setup in a bright Scandinavian-style room, sleek Apple MacBook Pro and aluminum external display showing clean analytics dashboard, mechanical keyboard, small ceramic succulent plant, warm oak wood desk, soft natural window light with sheer white curtains, cozy coffee mug with gentle steam, architectural digest aesthetic, photorealistic, 8k.
> ```
> **Negative Prompt:**
> ```text
> messy cables, cluttered, dark room, grainy, oversaturated, deformed furniture.
> ```

#### ตัวอย่าง 2.2: ไอคอน 3D Glassmorphic สำหรับ UI/UX แอปพลิเคชัน
> **Prompt:**
> ```text
> Set of floating 3D mobile app icons: a glowing glassmorphic leaf representing organic nature, an AI neural chip, and a sleek water drop. Translucent frosted glass material with smooth pastel green and blue gradients, soft studio rim lighting, subtle drop shadows, clean white neutral background, trending on Dribbble, C4D render, 8k.
> ```
> **Negative Prompt:**
> ```text
> rough edges, low resolution, dirty glass, flat vector, dark background.
> ```

#### ตัวอย่าง 2.3: บรรยากาศห้องแล็บวิจัยเทคโนโลยี AI และ Data Science
> **Prompt:**
> ```text
> Contemporary university AI research laboratory, warm ambient lighting, glass whiteboards filled with neural network equations and clean mathematical graphs, modern clean workstations, dual monitor displays, peaceful academic atmosphere, cinematic framing, photorealistic, shot on 35mm lens, high quality.
> ```
> **Negative Prompt:**
> ```text
> dystopian, messy, cluttered trash, cartoon, dark dungeon, blurry.
> ```

---

### หมวดที่ 3: ภาพถ่ายบุคคลและธรรมชาติระดับสตูดิโอ (Cinematic & Photorealistic Portraits)

#### ตัวอย่าง 3.1: ภาพถ่ายเกษตรกรยุคใหม่กับแท็บเล็ตในสวนผลไม้
> **Prompt:**
> ```text
> Portrait of an inspiring Asian female agricultural researcher in her early 30s standing proudly in a vibrant green tropical orchard, holding a rugged digital tablet displaying plant health charts, wearing a comfortable linen field shirt and wide-brim sun hat, genuine warm smile, authentic skin pores and fine texture, natural rim lighting from late afternoon sun, beautiful bokeh background, National Geographic photography style.
> ```
> **Negative Prompt:**
> ```text
> plastic skin, doll, oversmoothed face, extra fingers, deformed eyes, heavy makeup, artificial rendering.
> ```

#### ตัวอย่าง 3.2: หยดน้ำค้างบนใบไม้ยามเช้า (Golden Hour Dew Drop)
> **Prompt:**
> ```text
> Single crystal clear dewdrop resting on the tip of a vibrant green tropical leaf, morning sunlight refracting inside the water droplet showing tiny inverted reflection of the orchard, ultra-sharp macro details of leaf veins, golden hour lighting, cinematic atmosphere, 8k resolution, Hasselblad medium format camera.
> ```
> **Negative Prompt:**
> ```text
> blurry, hazy, noisy, digital artifact, painting, low contrast.
> ```

---

### หมวดที่ 4: พร้อมพ์สำหรับสร้างภาพเคลื่อนไหว/วิดีโอ (AI Video Generation Prompts)

สำหรับใช้งานใน **Draw Things (SVD)** หรือ **ComfyUI (Wan 2.1)**:

#### ตัวอย่าง 4.1: โดรนบินสำรวจแปลงเกษตร (Cinematic FPV Drone Flyover)
> **Video Prompt:**
> ```text
> Cinematic slow forward drone flight over lush green tropical fruit trees in morning mist, golden morning sunlight breaking through soft clouds, leaves gently swaying in fresh breeze, smooth camera motion, photorealistic 4k, 60fps feel.
> ```
> **Camera Motion Parameters (ถ้ามี):**
> - Motion Bucket: `127`
> - Pan / Zoom: `Slow Zoom In + Gentle Tilt Down`

#### ตัวอย่าง 4.2: หยดน้ำซึมลงสู่ผิวดินแบบสโลว์โมชัน (Fluid & Soil Absorption)
> **Video Prompt:**
> ```text
> Ultra slow-motion close up of fresh clear water droplets falling onto dark porous fertile soil, water gently absorbing into soil particles creating a rich moist texture, macro perspective, soft studio lighting, high speed camera 240fps slow motion effect.
> ```

#### ตัวอย่าง 4.3: ควันและไอระเหยกาแฟลอยละมุนในห้องทำงาน (Gentle Ambient Loop)
> **Video Prompt:**
> ```text
> Static camera cinematic shot of a warm ceramic coffee mug on an oak desk, delicate wisps of steam gently rising and swirling into the soft sunlight beam, cozy peaceful mood, smooth seamless motion.
> ```

---

## 6. สูตรการเขียน Prompt ให้สวยสมบูรณ์แบบ (Pro Prompt Formula)

โครงสร้างพรอมพ์ที่ดีที่สุดประกอบด้วย 5 องค์ประกอบหลัก:

$$\text{Prompt} = \mathbf{[Subject]} + \mathbf{[Details]} + \mathbf{[Environment]} + \mathbf{[Lighting]} + \mathbf{[Style / Camera]}$$

```text
[ประธานของภาพ] + [รายละเอียดเฉพาะจุด] + [สภาพแวดล้อม/ฉากหลัง] + [ทิศทางแสงและบรรยากาศ] + [สไตล์กล้อง/เลนส์]
```

### คำคุณศัพท์เพิ่มพลังความคมชัด (Quality Boosters):
- **สไตล์ภาพถ่ายเสมือนจริง:** `photorealistic, shot on 35mm f/1.8 lens, natural skin texture, depth of field, 8k resolution`
- **สไตล์แสงสวยงาม:** `golden hour lighting, soft studio rim lighting, cinematic volumetric haze, soft ambient glow`
- **สไตล์งาน 3D หรือ Tech:** `minimalist 3D render, Octane render, Raytracing, clean materials, Dribbble trend`

---

## 7. การทำงานร่วมกับ Ollama (ให้ Ollama เป็น Prompt Generator)

ท่านสามารถให้โมเดลภาษาในเครื่อง เช่น `llama3.2` หรือ `deepseek-r1` ใน Ollama ช่วยแต่งพรอมพ์ภาษาอังกฤษที่สวยงามให้ได้ทันที โดยพิมพ์คำสั่งนี้ใน Terminal:

```bash
ollama run llama3.2 "Act as an expert Stable Diffusion and FLUX prompt engineer. Write a detailed, photorealistic prompt for: 'A high-tech soil sensor deployed in a durian plantation in Thailand'. Include camera, lighting, and environment details. Output only the positive prompt."
```

หรือสร้างเป็น Alias สั้นๆ ใน `.zshrc`:
```bash
# เพิ่มฟังก์ชัน ai-prompt ใน ~/.zshrc
ai-prompt() {
  ollama run llama3.2 "You are an expert AI prompt engineer. Create an ultra-detailed Stable Diffusion prompt for: $1. Output only the prompt in English."
}
```
จากนั้นพิมพ์เรียกใช้งานได้ทันที เช่น:
```bash
ai-prompt "ภาพสวนทุเรียนอัจฉริยะมีโดรนบิน"
```

---

## 8. ระบบสร้างวิดีโออัตโนมัติ: Ollama Video Director + Local Video Engine

ระบบได้รับการติดตั้งเครื่องมืออัตโนมัติสำหรับประสานงานระหว่าง Ollama กับ Local Video Pipeline ไว้ในเครื่องของคุณแล้ว:

- **ที่ตั้งโฟลเดอร์เครื่องมือ:** [`/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/`](file:///Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/)
- **โมเดลผู้กำกับใน Ollama:** `video-director:latest` (ปรับแต่งพิเศษให้เข้าใจงานกำกับภาพยนตร์และมุมกล้อง)
- **เครื่องมือรันคลิป:** [`run_video.sh`](file:///Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/run_video.sh)

### คำสั่งสั่งสร้างวิดีโอด่วน:
```bash
# 1. ปรึกษาผู้กำกับ Ollama แบบ Interactive
ollama run video-director

# 2. สั่งสร้างวิดีโอจากไอเดียภาษาไทย (Text-to-Video)
/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/run_video.sh -p "โดรนบินสำรวจสวนทุเรียนและเซนเซอร์วัดดินยามเช้า"

# 3. สั่งแปลงภาพนิ่งเป็นวิดีโอเคลื่อนไหว (Image-to-Video ด้วย SVD)
/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/run_video.sh -i "/path/to/my_photo.png"
```

---

*จัดทำโดย Antigravity AI เพื่อเป็นคู่มือสนับสนุนการวิจัยและประยุกต์ใช้งาน Local AI ออฟไลน์อย่างสมบูรณ์แบบ*
