# คู่มือการติดตั้งและใช้งาน Local Large Language Models (LLMs)
### (Llama, Gemma, Qwen, DeepSeek) ด้วย Ollama

---

## 📌 สารบัญ (Table of Contents)
1. [บทนำและข้อดีของการใช้งาน Local LLM](#1-บทนำและข้อดีของการใช้งาน-local-llm)
2. [ข้อกำหนดฮาร์ดแวร์และการคำนวณสเปก (Hardware Requirements)](#2-ข้อกำหนดฮาร์ดแวร์และการคำนวณสเปก-hardware-requirements)
3. [ภาพรวมเครื่องมือสำหรับรัน Local LLM](#3-ภาพรวมเครื่องมือสำหรับรัน-local-llm)
4. [ขั้นตอนการติดตั้ง Ollama](#4-ขั้นตอนการติดตั้ง-ollama)
5. [การดาวน์โหลดและรันโมเดลแต่ละค่าย](#5-การดาวน์โหลดและรันโมเดลแต่ละค่าย)
6. [คำสั่ง Ollama CLI ที่ใช้บ่อย](#6-คำสั่ง-ollama-cli-ที่ใช้บ่อย)
7. [การสร้างและปรับแต่งโมเดลด้วย Modelfile](#7-การสร้างและปรับแต่งโมเดลด้วย-modelfile)
8. [การเชื่อมต่อใช้งานผ่าน API และโค้ดโปรแกรมมิ่ง](#8-การเชื่อมต่อใช้งานผ่าน-api-และโค้ดโปรแกรมมิ่ง)
9. [การติดตั้ง Web UI สไตล์ ChatGPT (Open WebUI)](#9-การติดตั้ง-web-ui-สไตล์-chatgpt-open-webui)
10. [ตารางเปรียบเทียบและการเลือกโมเดลให้เหมาะกับงาน](#10-ตารางเปรียบเทียบและการเลือกโมเดลให้เหมาะกับงาน)

---

## 1. บทนำและข้อดีของการใช้งาน Local LLM

**Local LLM** คือการดาวน์โหลดโมเดลปัญญาประดิษฐ์ (Open-weight Models) มาติดตั้งและประมวลผล (Inference) บนเครื่องคอมพิวเตอร์ของเราเอง โดยไม่ต้องส่งข้อมูลออกไปยังเซิร์ฟเวอร์ภายนอก

### ข้อดีหลัก:
- 🔒 **ความเป็นส่วนตัว 100% (Data Privacy):** ข้อมูลลับ เอกสารภายใน โค้ดโปรเจกต์ ไม่รั่วไหลออกนอกองค์กร
- 💸 **ฟรี ไม่มีค่าบริการรายเดือน/โทเค็น:** ไม่ต้องจ่ายค่า API Token หรือ Subscription รายเดือน
- 🌐 **ทำงานได้แบบ Offline:** ใช้งานได้แม้ไม่มีการเชื่อมต่ออินเทอร์เน็ต
- ⚙️ **ปรับแต่งได้เต็มที่ (Full Control):** ปรับจูน Parameter, System Prompt, Context Window หรือทำ Fine-tuning / RAG ได้อย่างอิสระ

---

## 2. ข้อกำหนดฮาร์ดแวร์และการคำนวณสเปก (Hardware Requirements)

โมเดล LLM ใช้ **RAM** (กรณีใช้ CPU/Apple Silicon) หรือ **VRAM** (กรณีใช้การ์ดจอแยก NVIDIA) เป็นทรัพยากรหลัก โดยโมเดลมักถูกบีบอัดในรูปแบบ **4-bit Quantization (GGUF Q4_K_M)** เพื่อให้ทำงานได้รวดเร็วและกินแรมน้อยลง

### ตารางสเปกที่แนะนำตามขนาดโมเดล:

| ขนาดโมเดล (Parameters) | RAM / VRAM ขั้นต่ำ | ตัวอย่างโมเดล | เหมาะกับอุปกรณ์ |
| :--- | :--- | :--- | :--- |
| **1B – 3B** | 4 – 8 GB | `qwen2.5:3b`, `gemma2:2b`, `llama3.2:3b` | แล็ปท็อปทั่วไป, เครื่องคอมพิวเตอร์ทั่วไป |
| **7B – 9B** *(มาตรฐาน)* | 8 – 16 GB | `qwen2.5:7b`, `deepseek-r1:8b`, `llama3.1:8b`, `gemma2:9b` | PC มีการ์ดจอ RTX 3060/4060 หรือ Mac M1/M2/M3/M4 (RAM 16GB+) |
| **14B – 32B** *(ฉลาดสูง)* | 16 – 32 GB | `qwen2.5:14b`, `qwen2.5:32b`, `deepseek-r1:14b`, `deepseek-r1:32b` | Mac RAM 24GB–36GB+ หรือ PC มี VRAM 16–24GB |
| **70B+** *(เทียบเท่ารุ่นเรือธง)* | 48 – 64 GB+ | `llama3.3:70b`, `qwen2.5:72b`, `deepseek-r1:70b` | Mac Studio/MacBook Pro RAM 64GB–128GB หรือการ์ดจอคู่ |

> [!TIP]
> - **Apple Silicon (Mac M-Series):** ได้เปรียบมากเพราะสถาปัตยกรรม **Unified Memory** ทำให้ชิป GPU เรียกใช้แรมทั้งระบบได้โดยตรง
> - **Windows / Linux PC:** หากต้องการความเร็วสูงสุด ควรมีการ์ดจอ **NVIDIA** ที่มี VRAM เพียงพอกับขนาดโมเดล

---

## 3. ภาพรวมเครื่องมือสำหรับรัน Local LLM

| เครื่องมือ | รูปแบบ | เหมาะสำหรับ | จุดเด่น |
| :--- | :--- | :--- | :--- |
| **Ollama** | CLI + Background API | แนะนำสำหรับทุกคน & นักพัฒนา | จัดการโมเดลง่าย มี REST API เข้ากันได้กับ OpenAI มาตรฐาน |
| **LM Studio** | Desktop GUI App | ผู้ใช้งานทั่วไปที่ต้องการหน้าต่างสวยๆ | ค้นหา ดาวน์โหลด และแชตได้ในหน้าต่างเดียว ไม่ต้องพิมพ์คำสั่ง |
| **Jan.ai** | Desktop GUI App | ผู้ใช้ทั่วไป (Open Source) | ใช้งานง่าย คล้าย ChatGPT ทำงานออฟไลน์สมบูรณ์แบบ |
| **vLLM / llama.cpp** | Engine ระดับลึก | สาย Production / High Performance | รองรับ Throughput สูง และปรับแต่งพารามิเตอร์ระดับแกนได้ลึก |

---

## 4. ขั้นตอนการติดตั้ง Ollama

### สำหรับ macOS:
1. ดาวน์โหลดไฟล์ `.zip` หรือ `.dmg` จาก [ollama.com/download/mac](https://ollama.com/download/mac)
2. ลาก Ollama เข้าโฟลเดอร์ `Applications` แล้วเปิดโปรแกรม
3. หรือติดตั้งผ่าน Homebrew:
   ```bash
   brew install ollama
   ```

### สำหรับ Windows:
1. ดาวน์โหลดตัวติดตั้ง `OllamaSetup.exe` จาก [ollama.com/download/windows](https://ollama.com/download/windows)
2. ดับเบิลคลิกติดตั้งตามขั้นตอน

### สำหรับ Linux:
รันคำสั่งบรรทัดเดียวใน Terminal:
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

---

## 5. การดาวน์โหลดและรันโมเดลแต่ละค่าย

เมื่อติดตั้ง Ollama แล้ว สามารถเปิด **Terminal** (Mac/Linux) หรือ **PowerShell/CMD** (Windows) แล้วสั่งรันโมเดลได้ทันที:

### 1) Qwen 2.5 (Alibaba Cloud)
> **จุดเด่น:** เข้าใจภาษาไทยได้ดีเยี่ยม ลำดับเหตุผลเก่ง เขียนโค้ดแม่นยำสูง

```bash
# รุ่น 7B (แนะนำสำหรับสเปกทั่วไป RAM 16GB)
ollama run qwen2.5:7b

# รุ่น 3B (สำหรับสเปกจำกัด RAM 8GB)
ollama run qwen2.5:3b

# รุ่น 14B / 32B (สำหรับงานซับซ้อน RAM 24GB-36GB ขึ้นไป)
ollama run qwen2.5:14b
```

### 2) DeepSeek-R1 (DeepSeek)
> **จุดเด่น:** โมเดลตรรกะและเหตุผล (Reasoning Model) แสดงขั้นตอนการคิด `<think>...</think>` คล้าย OpenAI o1

```bash
# รุ่น 8B (Distilled จาก Llama)
ollama run deepseek-r1:8b

# รุ่น 14B (Distilled จาก Qwen)
ollama run deepseek-r1:14b

# รุ่น 32B (Distilled จาก Qwen ความฉลาดสูงมาก)
ollama run deepseek-r1:32b
```

### 3) Llama 3.1 / 3.2 / 3.3 (Meta)
> **จุดเด่น:** มาตรฐานของ Open LLM เครื่องมือและเฟรมเวิร์กรองรับมากที่สุด

```bash
# Llama 3.1 รุ่น 8B
ollama run llama3.1:8b

# Llama 3.2 รุ่นเล็กพิเศษสำหรับอุปกรณ์พกพา
ollama run llama3.2:3b

# Llama 3.3 รุ่นใหญ่ 70B (ต้องการ RAM 48-64GB+)
ollama run llama3.3:70b
```

### 4) Gemma 2 (Google)
> **จุดเด่น:** ประสิทธิภาพต่อขนาดสูง สถาปัตยกรรมปลอดภัย เสถียร

```bash
# Gemma 2 รุ่น 2B (เบามาก)
ollama run gemma2:2b

# Gemma 2 รุ่น 9B
ollama run gemma2:9b
```

---

## 6. คำสั่ง Ollama CLI ที่ใช้บ่อย

| คำสั่ง | ความหมาย |
| :--- | :--- |
| `ollama run <model>` | ดาวน์โหลด (ถ้ายังไม่มี) และเปิดหน้าแชตทันที |
| `ollama pull <model>` | ดาวน์โหลดโมเดลมาเก็บไว้ในเครื่องล่วงหน้า |
| `ollama list` | ดูรายการโมเดลทั้งหมดที่ดาวน์โหลดไว้ในเครื่อง |
| `ollama ps` | ดูโมเดลที่กำลังโหลดอยู่ในหน่วยความจำขณะนี้ |
| `ollama rm <model>` | ลบโมเดลออกจากเครื่องเพื่อคืนพื้นที่ฮาร์ดดิสก์ |
| `ollama stop <model>` | ปิดโมเดลออกจาก RAM/VRAM |
| `/bye` | พิมพ์คำสั่งนี้ในหน้าแชตเพื่อออกจากโปรแกรม |

---

## 7. การสร้างและปรับแต่งโมเดลด้วย Modelfile

คุณสามารถปรับแต่งพฤติกรรม กำหนด System Prompt หรือตั้งค่าอุณหภูมิ (Temperature) ประจำตัวของโมเดลได้ผ่านไฟล์ `Modelfile`

ตัวอย่างสร้างผู้ช่วยนักวิจัยเกษตรและดินดิจิทัล:

1. สร้างไฟล์ชื่อ `Modelfile`:
```dockerfile
FROM qwen2.5:7b

# ตั้งค่าอุณหภูมิ (0.0 = แม่นยำ/ไม่มั่ว, 1.0 = มีความคิดสร้างสรรค์)
PARAMETER temperature 0.3
PARAMETER top_p 0.9

# กำหนด System Prompt
SYSTEM """
คุณคือผู้เชี่ยวชาญด้านปัญญาประดิษฐ์และการวิจัยฟิสิกส์เกษตรดิจิทัล (Digital Agriphysics & Soil Science) 
ให้ตอบคำถามด้วยภาษาไทยที่สุภาพ เป็นวิชาการ มีโครงสร้างชัดเจน และอ้างอิงหลักการทางวิทยาศาสตร์เสมอ
"""
```

2. สั่งสร้างโมเดลใหม่ใน Ollama:
```bash
ollama create soil-expert -f ./Modelfile
```

3. ใช้งานโมเดลที่ปรับแต่งแล้ว:
```bash
ollama run soil-expert
```

---

## 8. การเชื่อมต่อใช้งานผ่าน API และโค้ดโปรแกรมมิ่ง

Ollama จะเปิด Background Service อัตโนมัติที่ `http://localhost:11434`

### 1) การเรียกผ่าน Python (Official Library)
ติดตั้งไลบรารี:
```bash
pip install ollama
```

เขียนสคริปต์ทดสอบ:
```python
import ollama

response = ollama.chat(
    model='qwen2.5:7b',
    messages=[
        {
            'role': 'system',
            'content': 'คุณเป็นผู้ช่วยผู้เชี่ยวชาญด้านวิทยาศาสตร์'
        },
        {
            'role': 'user',
            'content': 'กรุณาอธิบายค่า N-P-K ในดิน และผลกระทบต่อพืชผล'
        }
    ]
)

print(response['message']['content'])
```

### 2) การเรียกผ่าน OpenAI-Compatible API
Ollama รองรับ Endpoint `/v1` เสมือน OpenAI API ทำให้สลับใช้กับโค้ดเดิมได้ทันที:

```python
from openai import OpenAI

client = OpenAI(
    base_url='http://localhost:11434/v1',
    api_key='ollama'  # ใส่สตริงใดก็ได้ ระบบไม่บังคับ
)

completion = client.chat.completions.create(
    model="deepseek-r1:8b",
    messages=[
        {"role": "user", "content": "วิเคราะห์ข้อดีข้อเสียของเซนเซอร์วัดความชื้นในดินแบบ Capacitive"}
    ]
)

print(completion.choices[0].message.content)
```

### 3) การเรียกผ่าน cURL (REST API)
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "qwen2.5:7b",
  "prompt": "ทำไมท้องฟ้าถึงเป็นสีฟ้า สรุปสั้นๆ 3 บรรทัด",
  "stream": false
}'
```

---

## 9. การติดตั้ง Web UI สไตล์ ChatGPT (Open WebUI)

หากต้องการอินเทอร์เฟซเว็บเหมือน ChatGPT ที่รองรับการสนทนา, แนบไฟล์ PDF/ภาพ, และระบบคลังความรู้ (RAG) สามารถใช้ **Open WebUI** รันผ่าน Docker:

```bash
docker run -d -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

เปิดเบราว์เซอร์แล้วเข้าสู่: `http://localhost:3000`  
ระบบจะเชื่อมต่อไปยัง Ollama บนเครื่องของคุณโดยอัตโนมัติ

---

## 10. ตารางเปรียบเทียบและการเลือกโมเดลให้เหมาะกับงาน

| งานที่ต้องการทำ (Use Case) | โมเดลที่แนะนำอันดับ 1 | ตัวเลือกสำรอง | เหตุผล |
| :--- | :--- | :--- | :--- |
| **ภาษาไทยทั่วไป + สรุปรายงาน** | `qwen2.5:7b` หรือ `14b` | `llama3.1:8b` | Qwen มีความเชี่ยวชาญคำศัพท์และไวยากรณ์ภาษาไทยสูงที่สุด |
| **วิเคราะห์ตรรกะ / คำนวณ / แก้ปัญหาซับซ้อน** | `deepseek-r1:8b` หรือ `14b` | `qwen2.5:14b` | มีกระบวนการคิดแบบ Chain-of-Thought ตรวจสอบเหตุผลตัวเองได้ |
| **เขียนโค้ด / Debugging** | `qwen2.5:7b` หรือ `14b` | `deepseek-r1:8b` | รองรับภาษาโปรแกรมหลากหลายและเข้าใจ Context โค้ดยาวได้ดี |
| **เครื่องสเปกต่ำ (RAM 4-8 GB)** | `qwen2.5:3b` | `gemma2:2b` | ใช้ทรัพยากรน้อยมาก แต่ยังคงความสามารถพื้นฐานได้ดี |
| **งานเอกสารวิชาการ / ระบบสืบค้น RAG** | `qwen2.5:14b` | `llama3.3:70b` | รองรับ Context Window ขนาดยาว (ถึง 128k tokens) |

---

## 11. คู่มือต่อเนื่อง: การสร้างภาพนิ่งและวิดีโอในเครื่อง (Local Image & Video Generation)

สำหรับผู้ที่ต้องการใช้งาน AI สร้างภาพ (Text-to-Image) เช่น **FLUX.1 [schnell]**, **SDXL** และโมเดลสร้างวิดีโอ (Text-to-Video) เช่น **Wan 2.1 (1.3B)**, **Stable Video Diffusion (SVD)** แบบฟรี 100% ออฟไลน์:
- 📖 อ่านคู่มือฉบับเต็มได้ที่: [คู่มือการติดตั้งและใช้งาน Local Image & Video Generation](file:///Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/local_image_video_guide.md)

---
*จัดทำขึ้นสำหรับการศึกษา ค้นคว้า และพัฒนานวัตกรรมปัญญาประดิษฐ์ออฟไลน์*
