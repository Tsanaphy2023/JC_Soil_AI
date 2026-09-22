#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
Assembly Pipeline: Project 10 - Unidirectional Forward Cinematic Documentary
"วิถีชาวนาไทย: การเคลื่อนไหวไปข้างหน้าอย่างต่อเนื่อง (Unidirectional Living Flow)"
=============================================================================
100% Forward Living Motion - Zero Reverse, Zero Ping-Pong, Zero Boomerang:
- 10 ช็อตต่อเนื่องที่ก้าวไปข้างหน้าในมิติกาลเวลาอย่างสมบูรณ์แบบ
- ร้อยเรียงจากรุ่งอรุณ การเตรียมกล้า การก้าวลงโคลน การกดรากลงดิน จนถึงรวงทองยามเย็น
- ผิวน้ำและคลื่นน้ำแผ่ขยายออกไปข้างหน้า ไม่มีการดูดกลับ
- สองมือชาวนากดรากลงดินอย่างเป็นธรรมชาติ ไม่มีการเด้งย้อนกลับขึ้นมา
- ความยาว 60.00 วินาทีเป๊ะ (1,800 เฟรม @ 30 fps, HD 720p 1280x720)
=============================================================================
"""

import os
import sys
import time
import json
import wave
import struct
import math
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

PROJECT_DIR = Path("/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/projects/10_forward_flowing_cinematic_thai_farmers_1min")
RAW_DIR = PROJECT_DIR / "raw_svd_clips"
SHOTS_DIR = PROJECT_DIR / "shots"
AUDIO_DIR = PROJECT_DIR / "audio"
THUMB_DIR = PROJECT_DIR / "thumbnails"

FINAL_VIDEO = PROJECT_DIR / "video.mp4"
SOUNDTRACK_PATH = AUDIO_DIR / "thai_rice_field_acoustic.wav"

FONT_PATH = "/System/Library/Fonts/Supplemental/Thonburi.ttc"
if not os.path.exists(FONT_PATH):
    FONT_PATH = "/System/Library/Fonts/Thonburi.ttc"

# นิยาม 10 ช็อตภาพยนตร์สารคดีคมชัดสูง (10 Pristine Master SVD Shots)
SHOT_SPECS = [
    # Act 1: รุ่งอรุณ
    {
        "raw": "clip_01a_scene1_dawn_terrace_p1.mp4",
        "title": "องก์ที่ 1: รุ่งอรุณเหนือนาขั้นบันได",
        "sub": "สายหมอกยามเช้าเคลื่อนผ่านเทือกเขา แสงตะวันส่องกระทบผืนน้ำระยิบระยับ",
        "dur": 6.5
    },
    {
        "raw": "clip_02_buffalo_ridge.mp4",
        "title": "องก์ที่ 1: รุ่งอรุณเหนือนาขั้นบันได",
        "sub": "ชาวนาและควายคู่ใจก้าวเดินบนคันดินเลนมุ่งสู่แปลงปลูกกลางไอหมอก",
        "dur": 6.5
    },
    # Act 2: มัดกล้า
    {
        "raw": "clip_02a_scene2_seedling_bundle_p1.mp4",
        "title": "องก์ที่ 2: มัดกล้าข้าวมรกต",
        "sub": "สองมือกุมมัดกล้าข้าวอย่างทะนุถนอม คัดสรรยอดใบอ่อนที่สมบูรณ์แข็งแรง",
        "dur": 6.5
    },
    {
        "raw": "clip_04_seedlings_splash.mp4",
        "title": "องก์ที่ 2: มัดกล้าข้าวมรกต",
        "sub": "ยกมัดกล้าสะบัดหยดน้ำค้างรับประกายแดด ละอองน้ำกระเซ็นวาววับ",
        "dur": 6.5
    },
    # Act 3: จังหวะดำนา
    {
        "raw": "clip_05_farmers_line.mp4",
        "title": "องก์ที่ 3: หัตถกรรมและวิถีดำนา",
        "sub": "ขบวนชาวนาก้าวเดินลงสู่แปลงนาขังน้ำ ผืนน้ำแตกเป็นคลื่นระลอกกว้าง",
        "dur": 6.5
    },
    {
        "raw": "clip_03a_scene3_farmers_planting_p1.mp4",
        "title": "องก์ที่ 3: หัตถกรรมและวิถีดำนา",
        "sub": "ชาวนาในชุดม่อฮ่อมก้มตัวลงปักดำพร้อมเพรียง สองมือจุ่มลงน้ำอย่างชำนาญ",
        "dur": 6.5
    },
    # Act 4: สัมผัสดิน
    {
        "raw": "clip_04a_scene4_macro_mud_water_p1.mp4",
        "title": "องก์ที่ 4: สัมผัสผืนดินและสายน้ำ",
        "sub": "สองมือเปื้อนโคลนบรรจงกดรากกล้าลงดินเลนลึก ผิวน้ำกระเซ็นเป็นประกาย",
        "dur": 6.5
    },
    {
        "raw": "clip_08_ripples_macro.mp4",
        "title": "องก์ที่ 4: สัมผัสผืนดินและสายน้ำ",
        "sub": "คลื่นน้ำแผ่ขยายออกเป็นวงกลมต่อเนื่อง ดินเลนโอบอุ้มต้นกล้าให้หยั่งราก",
        "dur": 6.5
    },
    # Act 5: มรดกชาวนา
    {
        "raw": "clip_09_rows_wind.mp4",
        "title": "องก์ที่ 5: มรดกหยาดเหงื่อและรอยยิ้ม",
        "sub": "แนวต้นกล้าเรียงตรงสวยงามพลิ้วไหวตามสายลม แผ่นน้ำสะท้อนฟ้าสีคราม",
        "dur": 6.5
    },
    {
        "raw": "clip_05a_scene5_golden_heritage_p1.mp4",
        "title": "องก์ที่ 5: มรดกหยาดเหงื่อและรอยยิ้ม",
        "sub": "ชาวนาเงยหน้าเช็ดเหงื่อ รอยยิ้มเปี่ยมสุข สรรเสริญเกียรติยศกระดูกสันหลังของชาติ",
        "dur": 6.5
    },
]

def generate_soundtrack():
    """สร้างเพลงบรรเลงกีตาร์โฟล์กไทย D-Major Pentatonic ผสานเสียงน้ำธรรมชาติ 60.00 วินาที"""
    print("🎵 กำลังสังเคราะห์เพลงบรรเลงอคูสติกโฟล์กไทย Hi-Fi (60 วินาที)...")
    sample_rate = 44100
    total_seconds = 60.0
    total_samples = int(sample_rate * total_seconds)
    
    chords = [
        [146.83, 220.00, 293.66, 370.00],  # D
        [196.00, 246.94, 293.66, 392.00],  # G
        [146.83, 220.00, 293.66, 370.00],  # D
        [220.00, 277.18, 329.63, 440.00],  # A
        [164.81, 246.94, 329.63, 392.00],  # Em
        [196.00, 246.94, 293.66, 370.00],  # G
        [146.83, 220.00, 293.66, 440.00],  # D add9
    ]
    
    buffer = bytearray()
    measure_duration = 3.0
    
    for i in range(total_samples):
        t = i / sample_rate
        water_noise = math.sin(2 * math.pi * 3.2 * t) * 0.035 * math.sin(2 * math.pi * 440 * t)
        water_stream = math.sin(2 * math.pi * 1.5 * t) * 0.025 * math.sin(2 * math.pi * 650 * t)
        birds = math.sin(2 * math.pi * 2800 * t) * 0.015 if (int(t * 2) % 7 == 3 and (t % 0.5) < 0.15) else 0.0
        
        chord_idx = int((t / measure_duration)) % len(chords)
        current_chord = chords[chord_idx]
        
        beat = (t % 0.5) / 0.5
        note_idx = int((t / 0.5) % len(current_chord))
        freq = current_chord[note_idx]
        
        decay = math.exp(-beat * 4.2)
        harm1 = math.sin(2 * math.pi * freq * t)
        harm2 = 0.55 * math.sin(2 * math.pi * freq * 2 * t)
        harm3 = 0.28 * math.sin(2 * math.pi * freq * 3 * t)
        
        tone = (harm1 + harm2 + harm3) * decay * 0.38
        bass = math.sin(2 * math.pi * 73.42 * t) * 0.14 * math.exp(-(t % 1.5) * 2.2)
        
        master_gain = 1.0
        if t < 2.0:
            master_gain = t / 2.0
        elif t > 57.0:
            master_gain = max(0.0, (60.0 - t) / 3.0)
            
        sample = (tone + bass + water_noise + water_stream + birds) * master_gain
        sample = max(-0.95, min(0.95, sample))
        int_sample = int(sample * 32767)
        buffer.extend(struct.pack("<h", int_sample))
        
    with wave.open(str(SOUNDTRACK_PATH), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(buffer)
    print("✅ สังเคราะห์เพลงสำเร็จ!")

def create_title_banner(title: str, sub: str, output_png: Path):
    """สร้างภาพแบนเนอร์ข้อความภาษาไทยพื้นหลังโปร่งใสระดับ HD"""
    img = Image.new('RGBA', (1280, 720), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # แถบเงาดำโปร่งแสงด้านล่าง
    for y in range(590, 720):
        alpha = int(215 * (y - 590) / 130)
        draw.line([(0, y), (1280, y)], fill=(0, 0, 0, alpha))
        
    font_title = ImageFont.truetype(FONT_PATH, 34)
    font_sub = ImageFont.truetype(FONT_PATH, 22)
    draw.text((641, 631), title, font=font_title, fill=(0, 0, 0, 200), anchor="mm")
    draw.text((640, 630), title, font=font_title, fill=(255, 255, 255, 255), anchor="mm")
    draw.text((641, 676), sub, font=font_sub, fill=(0, 0, 0, 200), anchor="mm")
    draw.text((640, 675), sub, font=font_sub, fill=(225, 225, 225, 240), anchor="mm")
    img.save(str(output_png))

def build_forward_flowing_shots():
    """
    สร้าง 10 ช็อตภาพยนตร์ที่เคลื่อนไหวไปข้างหน้า 100% (Strictly Unidirectional Forward Flow)
    - ปราศจาก reverse / boomerang / ping-pong
    - ใช้ setpts ขยายเวลาการเคลื่อนไหวไปข้างหน้าอย่างนุ่มนวล
    - ใช้ minterpolate=fps=30:mi_mode=blend เพื่อเฟรมเรต 30 fps ลื่นไหล ไร้การกระตุก
    - สเกลภาพเป็น HD 720p ด้วย Lanczos + Unsharp Mask
    """
    shot_paths = []
    for idx, spec in enumerate(SHOT_SPECS, 1):
        raw_video = RAW_DIR / spec["raw"]
        out_shot = SHOTS_DIR / f"forward_shot_{idx:02d}.mp4"
        banner_png = SHOTS_DIR / f"banner_{idx:02d}.png"
        create_title_banner(spec["title"], spec["sub"], banner_png)
        shot_paths.append(out_shot)
        
        # Crystal-Clear Motion Compensated Interpolation (MCI) Filter
        # mi_mode=mci: Advanced Overlapped Block Motion Compensation (AOBMC)
        # ปราศจาก Ghosting Blur และ Double Exposure 100%
        # รักษาความคมชัดของลวดลายหมวกงอบ ต้นข้าว และหยดน้ำระดับ 720p HD
        vf_filter = (
            f"[0:v]setpts=PTS*1.48,"
            f"minterpolate=fps=30:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1,"
            f"scale=1280:720:flags=lanczos+accurate_rnd,"
            f"unsharp=5:5:1.2:3:3:0.6,"
            f"eq=contrast=1.08:saturation=1.15:brightness=0.01,"
            f"tpad=stop_mode=clone:stop_duration=3.0[bg];"
            f"[bg][1:v]overlay=0:0:shortest=1[v]"
        )
        
        cmd = [
            "ffmpeg", "-y",
            "-i", str(raw_video),
            "-loop", "1", "-i", str(banner_png),
            "-filter_complex", vf_filter,
            "-map", "[v]",
            "-t", str(spec["dur"]),
            "-c:v", "libx264", "-preset", "medium", "-crf", "15",
            "-pix_fmt", "yuv420p",
            str(out_shot)
        ]
        print(f"🎬 กำลังเรนเดอร์ช็อตคมชัดสูง (MCI Crystal-Sharp) {idx:02d}/10 ({spec['title']})...")
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
    return shot_paths

def assemble_final_montage(shot_paths):
    """
    เชื่อมต่อ 10 ช็อตด้วย Cross-Dissolve 0.5 วินาที รวมดนตรีให้ได้ 60.00 วินาทีเป๊ะ
    """
    print("\n🎞️ กำลังประกอบ 10 ช็อตภาพยนตร์ด้วย Cinematic Cross-Dissolves...")
    inputs = []
    for sp in shot_paths:
        inputs.extend(["-i", str(sp)])
        
    # XFade chain:
    # 10 clips @ 6.5s, each xfade lasts 0.5s:
    # offset 1: 6.0
    # offset 2: 11.5
    # offset 3: 17.0
    # offset 4: 22.5
    # offset 5: 28.0
    # offset 6: 33.5
    # offset 7: 39.0
    # offset 8: 44.5
    # offset 9: 50.0
    filter_parts = []
    curr_stream = "[0:v]"
    offsets = [6.0, 11.5, 17.0, 22.5, 28.0, 33.5, 39.0, 44.5, 50.0]
    
    for i in range(1, 10):
        next_in = f"[{i}:v]"
        out_stream = f"[v{i}]"
        offset = offsets[i-1]
        filter_parts.append(
            f"{curr_stream}{next_in}xfade=transition=fade:duration=0.5:offset={offset:.1f}{out_stream}"
        )
        curr_stream = out_stream
        
    # Cut at 60.00s and add final fade-out
    filter_parts.append(
        f"{curr_stream}fade=t=out:st=58.5:d=1.5[vfinal]"
    )
    
    filter_str = ";".join(filter_parts)
    
    cmd = [
        "ffmpeg", "-y",
        *inputs,
        "-i", str(SOUNDTRACK_PATH),
        "-filter_complex", filter_str,
        "-map", "[vfinal]",
        "-map", f"{len(shot_paths)}:a",
        "-t", "60.00",
        "-c:v", "libx264", "-preset", "slow", "-crf", "16",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "256k",
        "-movflags", "+faststart",
        str(FINAL_VIDEO)
    ]
    
    t0 = time.time()
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print(f"🎉 ประกอบภาพยนตร์ 60.00 วินาทีสำเร็จใน {time.time() - t0:.1f} วินาที -> {FINAL_VIDEO.name}")

def create_thumbnails():
    """สกัดภาพตัวอย่าง 5 ภาพหลักประจำโปรเจกต์"""
    print("📸 กำลังสกัดภาพพรีวิวตัวอย่าง...")
    timestamps = [6, 18, 30, 42, 54]
    for ts in timestamps:
        out_thumb = THUMB_DIR / f"forward_motion_scene_{ts}s.png"
        cmd = [
            "ffmpeg", "-y",
            "-ss", str(ts),
            "-i", str(FINAL_VIDEO),
            "-vframes", "1",
            "-q:v", "2",
            str(out_thumb)
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def generate_metadata_and_readme():
    """สร้าง metadata.json และ README.md ประจำโปรเจกต์ 10"""
    meta = {
        "project_name": "10_forward_flowing_cinematic_thai_farmers_1min",
        "title": "The Living Art of Thai Rice Farming (Unidirectional Forward Motion Documentary)",
        "type": "unidirectional-forward-cinematic-documentary",
        "resolution": "1280x720 HD",
        "fps": 30,
        "duration_seconds": 60.0,
        "frames": 1800,
        "motion_engine": "Stable Video Diffusion (SVD-XT) Autoregressive Forward Chaining (Zero Ping-Pong / Zero Reverse)",
        "soundtrack": "Thai Folk Pentatonic Acoustic Guitar with Ambient Stream Sounds",
        "created_at": time.strftime("%Y-%m-%d %H:%M:%S")
    }
    with open(PROJECT_DIR / "metadata.json", "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)
        
    readme_text = f"""# 🎬 Project 10: The Living Art of Thai Rice Farming (Unidirectional Forward Motion)
### ภาพยนตร์สารคดีชาวนาไทย 60 วินาที: การเคลื่อนไหวไปข้างหน้าอย่างต่อเนื่อง 100% (Zero Reverse / Zero Ping-Pong)

---

## 🌟 จุดเด่นสำคัญของการปรับปรุงครั้งนี้
1. **การเคลื่อนไหวไหลไปข้างหน้าทิศทางเดียวต่อเนื่อง 100% (Unidirectional Forward Vector Flow):**
   - แก้ปัญหาภาพย้อนกลับไปกลับมา (Ping-Pong / Boomerang Effect) โดยตัดระบบ Reverse Playback ออกทั้งหมด
   - คลื่นน้ำและผิวน้ำแผ่ขยายออกไปข้างหน้าอย่างเป็นธรรมชาติ ไม่มีการหดหรือดูดกลับ
   - สองมือของชาวนากดรากกล้าลงดินโคลนอย่างต่อเนื่อง ไม่มีการเด้งย้อนขึ้นมา
2. **เทคนิค Autoregressive Forward Chaining บน SVD-XT:**
   - เชื่อมต่อการเคลื่อนไหว Part 1 สู่ Part 2 โดยดึงเฟรมท้ายสุดมาเป็นภาพตั้งต้นต่อเนื่อง
3. **10 ช็อตภาพยนตร์สารคดีความยาว 60.00 วินาทีเป๊ะ (1,800 เฟรม @ 30 fps HD 720p):**
   - ผสานการเชื่อมฉากด้วย Cinematic Cross-Dissolves (0.5s)
   - ดนตรีบรรเลงอคูสติกโฟล์กไทย D-Major Pentatonic 44.1kHz พร้อมเสียงน้ำธรรมชาติ

---

## 🖥️ วิธีเปิดชมวิดีโอ
```bash
open "{FINAL_VIDEO}"
```
"""
    with open(PROJECT_DIR / "README.md", "w", encoding="utf-8") as f:
        f.write(readme_text)

def main():
    SHOTS_DIR.mkdir(parents=True, exist_ok=True)
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    THUMB_DIR.mkdir(parents=True, exist_ok=True)
    
    if not SOUNDTRACK_PATH.exists():
        generate_soundtrack()
        
    shots = build_forward_flowing_shots()
    assemble_final_montage(shots)
    create_thumbnails()
    generate_metadata_and_readme()
    print("\n✅ เสร็จสมบูรณ์ทุกขั้นตอน 100% สำหรับโปรเจกต์ 10!")

if __name__ == "__main__":
    main()
