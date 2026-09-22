
# คู่มือการใช้งาน Ollama ร่วมกับ Google Antigravity (AGY)

### (Hybrid Agentic Architecture: Cloud Orchestrator + Local Inference)

---

## 📌 สารบัญ

1. [สถาปัตยกรรมภาพรวม (Architecture Overview)](#1-สถาปัตยกรรมภาพรวม-architecture-overview)
2. [สถานะและโมเดลที่มีในเครื่องปัจจุบัน](#2-สถานะและโมเดลที่มีในเครื่องปัจจุบัน)
3. [วิธีที่ 1: การเรียกใช้ผ่าน Antigravity Ollama MCP Tools](#3-วิธีที่-1-การเรียกใช้ผ่าน-antigravity-ollama-mcp-tools)
4. [วิธีที่ 2: การตั้งค่าคอนฟิก MCP Server (`mcp_config.json`)](#4-วิธีที่-2-การตั้งค่าคอนฟิก-mcp-server-mcp_configjson)
5. [วิธีที่ 3: การเขียนโค้ดเชื่อมต่อผ่าน Antigravity Python SDK](#5-วิธีที่-3-การเขียนโค้ดเชื่อมต่อผ่าน-antigravity-python-sdk)
6. [สูตรคำสั่ง Prompt ตัวอย่างสำหรับการทำงานร่วมกัน](#6-สูตรคำสั่ง-prompt-ตัวอย่างสำหรับการทำงานร่วมกัน)
7. [การแบ่งหน้าที่ (Work Distribution Matrix)](#7-การแบ่งหน้าที่-work-distribution-matrix)

---

## 1. สถาปัตยกรรมภาพรวม (Architecture Overview)

การทำงานร่วมกันระหว่าง **Google Antigravity** และ **Ollama** เป็นการผสานพลังระหว่าง:

- **Cloud Orchestrator (Google Antigravity / Gemini):** ทำหน้าที่บริหารจัดการกระบวนการพัฒนา, วางแผนงาน (Planning), สำรวจโครงสร้างโปรเจกต์ขนาดใหญ่, อ่าน/เขียนไฟล์, และรันคำสั่ง Terminal
- **Local Engine (Ollama):** ทำหน้าที่รันโมเดล Open-weight (DeepSeek, Qwen, Llama, AgriLlama) บนชิปประมวลผลของเครื่องตัวเอง ปลอดภัย ออฟไลน์ ไม่เสียค่า API Token

```
+-------------------------------------------------------------+
|                     User (ผู้ใช้งาน)                        |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|             Google Antigravity (Super Agent)                |
|  - File Edit / Read / Write                                 |
|  - Terminal & Build Automation (Flutter, Python, Git)       |
|  - Subagents & Task Orchestration                           |
+-------------------------------------------------------------+
                              |
                     (Ollama MCP Protocol)
                              |
                              v
+-------------------------------------------------------------+
|             Ollama Local Server (127.0.0.1:11434)           |
|  - deepseek-r1:latest / 14b (Reasoning & Math)              |
|  - qwen2.5-coder:32b (Local Code Refactoring)               |
|  - sike_aditya/AgriLlama (Agriculture Specialized)          |
|  - llama3.2-vision (Multimodal / Image Inspection)          |
+-------------------------------------------------------------+
```

---

## 2. สถานะและโมเดลที่มีในเครื่องปัจจุบัน

ระบบ Antigravity ได้ตรวจพบโมเดลพร้อมใช้งานในเครื่องของคุณผ่าน Ollama MCP Server ดังนี้:

| ชื่อโมเดล (Model Tag) | ขนาดพารามิเตอร์ | ความสามารถหลัก                                                             |
| :----------------------------- | :----------------------------- | :--------------------------------------------------------------------------------------- |
| `deepseek-r1:latest`         | 8.2B (Q4_K_M)                  | คิดวิเคราะห์ตรรกะ, ให้เหตุผลแบบ`<think>...</think>`       |
| `deepseek-r1:14b`            | 14.8B (Q4_K_M)                 | วิเคราะห์ตรรกะขั้นสูงและงานคณิตศาสตร์ซับซ้อน |
| `qwen2.5-coder:32b`          | 32.8B (Q4_K_M)                 | เขียนโค้ด, ตรวจบั๊ก, Refactor ภาษาไทยและอังกฤษ          |
| `llama3.2:latest`            | 3.2B (Q4_K_M)                  | โมเดลขนาดกะทัดรัด ทำงานรวดเร็ว ตอบงานทั่วไป     |
| `llama3.2-vision:latest`     | 10.7B (Q4_K_M)                 | วิเคราะห์รูปภาพ (Computer Vision / Sensor UI)                             |
| `sike_aditya/AgriLlama`      | 1.2B                           | โมเดลเฉพาะทางด้านการเกษตรและดิน                           |
| `gemma4:latest` / `26b`    | 8.0B / 25.2B                   | โมเดลมาตรฐานประสิทธิภาพสูงจาก Google                        |

---

## 3. วิธีที่ 1: การเรียกใช้ผ่าน Antigravity Ollama MCP Tools

Antigravity สามารถส่งคำสั่ง (Tool Calls) ไปยัง Ollama ได้โดยตรงผ่านฟังก์ชัน:

### 1) คำสั่งตรวจดูรายการโมเดล (`list`)

```json
{
  "ServerName": "ollama",
  "ToolName": "list",
  "Arguments": {}
}
```

### 2) คำสั่งสั่งรันคำถาม (`run`)

```json
{
  "ServerName": "ollama",
  "ToolName": "run",
  "Arguments": {
    "name": "deepseek-r1:latest",
    "prompt": "อธิบายหลักการวัดไนโตรเจน (N) ในดินด้วยวิธี Colorimetric"
  }
}
```

### 3) คำสั่งสนทนาแบบละเอียด (`chat_completion`)

```json
{
  "ServerName": "ollama",
  "ToolName": "chat_completion",
  "Arguments": {
    "model": "qwen2.5-coder:32b",
    "messages": [
      {"role": "system", "content": "คุณเป็นผู้เชี่ยวชาญภาษา Dart และ Flutter"},
      {"role": "user", "content": "เขียน Unit Test สำหรับทดสอบการแปลงค่า RGB เป็น NPK"}
    ],
    "temperature": 0.2
  }
}
```

---

## 4. วิธีที่ 2: การตั้งค่าคอนฟิก MCP Server (`mcp_config.json`)

Antigravity โหลดคอนฟิก MCP จาก:
📁 `~/.gemini/config/mcp_config.json`

โครงสร้างการเชื่อมต่อกับ Ollama:

```json
{
  "mcpServers": {
    "ollama": {
      "command": "ollama-mcp-server",
      "args": [],
      "env": {
        "OLLAMA_HOST": "http://127.0.0.1:11434"
      }
    }
  }
}
```

---

## 5. วิธีที่ 3: การเขียนโค้ดเชื่อมต่อผ่าน Antigravity Python SDK

คุณสามารถใช้ `google-antigravity` เพื่อเขียนโปรแกรมอัตโนมัติ ให้ Antigravity และ Ollama ทำงานร่วมกัน:

```python
import asyncio
import ollama
from google.antigravity import Agent, LocalAgentConfig, CapabilitiesConfig

async def run_hybrid_agent():
    # ขั้นตอนที่ 1: ให้โมเดลการเกษตรในเครื่อง (AgriLlama / Qwen) ให้ความรู้เฉพาะทาง
    print("[1] Querying Local Ollama AgriLlama...")
    res = ollama.chat(
        model='sike_aditya/AgriLlama:latest',
        messages=[{'role': 'user', 'content': 'What is the optimal soil pH for durian planting?'}]
    )
    soil_knowledge = res['message']['content']
    print(f"-> Knowledge extracted: {soil_knowledge[:100]}...\n")

    # ขั้นตอนที่ 2: ให้ Antigravity Agent นำผลลัพธ์ไปสร้างไฟล์โค้ดหรือเอกสารในโปรเจกต์
    print("[2] Spawning Antigravity Agent to update project...")
    config = LocalAgentConfig(
        system_instructions="You are an Agri-tech developer. Write clean Dart models based on agricultural inputs.",
        capabilities=CapabilitiesConfig() # ให้สิทธิ์อ่านเขียนไฟล์
    )
  
    async with Agent(config) as agent:
        prompt = f"Create a Dart data model class in `lib/models/durian_soil.dart` based on this:\n{soil_knowledge}"
        response = await agent.chat(prompt)
        async for token in response:
            print(token, end="", flush=True)

if __name__ == "__main__":
    asyncio.run(run_hybrid_agent())
```

---

## 6. สูตรคำสั่ง Prompt ตัวอย่างสำหรับการทำงานร่วมกัน

คุณสามารถสั่ง Antigravity ในหน้าต่างแชตได้ทันที โดยไม่ต้องพิมพ์คำสั่งซับซ้อน:

1. **โจทย์ตรวจสอบตรรกะแบบไม่ต้องส่งข้อมูลออกเน็ต:**

   > *"ให้ Antigravity นำฟังก์ชันคำนวณในไฟล์ `soil_detector.dart` ส่งไปให้ `deepseek-r1:latest` ใน Ollama ช่วยหาจุดบกพร่องและวิเคราะห์ edge cases"*
   >
2. **โจทย์เขียนโค้ดเฉพาะทางด้านเกษตร:**

   > *"ลองถาม `sike_aditya/AgriLlama:latest` ในเครื่องเกี่ยวกับเกณฑ์การประเมินธาตุฟอสฟอรัส แล้วให้ Antigravity นำเกณฑ์นั้นมาเขียนฟังก์ชันตรวจสอบในโปรเจกต์"*
   >
3. **โจทย์การสร้าง Unit Test ด้วยโมเดลขนาดใหญ่:**

   > *"สั่ง `qwen2.5-coder:32b` ใน Ollama เขียน Test cases ให้ครอบคลุมทุก Method ในโฟลเดอร์ `lib/services/` แล้วให้ Antigravity บันทึกลงโฟลเดอร์ `test/`"*
   >

---

## 7. การแบ่งหน้าที่ (Work Distribution Matrix)

| หน้าที่และบริบทงาน                                               | ผู้รับผิดชอบที่เหมาะสม | ข้อดี                                                                   |
| :--------------------------------------------------------------------------------- | :------------------------------------------- | :--------------------------------------------------------------------------- |
| **อ่านไฟล์โครงสร้างโปรเจกต์หลายสิบไฟล์** | Google Antigravity (Gemini)                  | Context window ใหญ่ มองเห็นภาพรวมทั้ง Repo ได้ครบ |
| **เขียน / แก้ไขไฟล์จริงใน Workspace**                    | Google Antigravity                           | มี Tools`replace_file_content` / `write_to_file` ในตัว            |
| **งานด้านความรู้ดินและการเกษตรเฉพาะทาง** | Ollama (`AgriLlama`)                       | มีโมเดล Domain-Specific พร้อมในเครื่อง                  |

---

## 8. กรณีศึกษาจริง (Real-World Case Study): การตรวจสอบ PINN ด้วย DeepSeek-R1

ในโปรเจกต์ `soil_app` นี้ ได้มีการนำสถาปัตยกรรมลูกผสม (Hybrid Intelligence) มาใช้งานจริง:

### ขั้นตอนที่ดำเนินการจริง:

1. **Antigravity ดึงโค้ดแกนกลาง:** คัดแยกตรรกะคณิตศาสตร์และโครงข่ายประสาทเทียม PINN จาก [`deep_learning_calibrator.dart`](file:///Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/lib/domain/models/deep_learning_calibrator.dart)
2. **ส่งให้ DeepSeek-R1 วิเคราะห์ออฟไลน์:** ส่งผ่าน Ollama API (`deepseek-r1:latest`) ตรวจจับข้อผิดพลาดทางตัวเลขและ Edge cases
3. **ผลการตรวจพบของ DeepSeek-R1:**
   - ตรวจพบจุดเสี่ยงในฟังก์ชัน `tanh(double x)` เมื่อ $x > 40$ ค่า `exp(2x)` จะเกิด Overflow กลายเป็น `double.infinity` และทำให้สมการคืนค่า `NaN`
   - ตรวจพบเงื่อนไขการตรวจจับสายเซนเซอร์หลุดที่ยังไม่ครอบคลุมช่วงกายภาพจริง
   - ตรวจพบจุดเสี่ยงการหารด้วยศูนย์ในสมการชดเชยอุณหภูมิค่าความนำไฟฟ้า (EC)
4. **Antigravity นำผลลัพธ์มาปรับปรุงโค้ดทันที:**
   - เพิ่ม Numerical Clamp ใน `tanh` และ `_gelu` ป้องกัน `NaN` ถาวร
   - เพิ่มระบบตรวจสอบ Physical Boundaries และ Sensor Anomaly
   - ป้องกันการหารด้วยศูนย์ในสมการ EC
   - สร้างหน้าจอ **Animated Splash Screen** แสดงโลโก้พร้อมแอนิเมชันสถานะระบบและรองรับระบบสามภาษา
5. **รันการทดสอบ Unit & Widget Tests อัตโนมัติ:** ผ่านครบ 56/56 Tests สมบูรณ์แบบ 100%
