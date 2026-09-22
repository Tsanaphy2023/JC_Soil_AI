#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
Durian Smart Agriculture Cartoon Animation (60 Seconds / 1 Minute)
แอนิเมชันการ์ตูนเกษตรดิจิทัล: "น้องทุเรียนหนามน้อย & SoilBot ฮีโร่กู้สวน"
=============================================================================
ความยาว: 60.00 วินาที (1,800 เฟรม @ 30 fps) ความละเอียด HD 720p (1280x720)
แฝงความรู้วิชาการ: การจัดการน้ำ ดินกรดด่าง pH 5.5-6.5 และการคุมธาตุอาหาร N-P-K
พร้อมดนตรีประกอบแนวการ์ตูนแสนสดใส (Playful Marimba & Chimes)
=============================================================================
"""

import os
import sys
import math
import wave
import time
import subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = Path(__file__).resolve().parent / "output_videos"
PROJECT_DIR = OUTPUT_DIR / "projects" / "03_durian_smart_agri_cartoon_1min"
(PROJECT_DIR / "audio").mkdir(parents=True, exist_ok=True)
(PROJECT_DIR / "thumbnails").mkdir(parents=True, exist_ok=True)
FINAL_VIDEO_PATH = PROJECT_DIR / "video.mp4"
AUDIO_WAV_PATH = PROJECT_DIR / "audio" / "durian_cartoon_soundtrack.wav"

WIDTH = 1280
HEIGHT = 720
FPS = 30
TOTAL_SECONDS = 60
TOTAL_FRAMES = TOTAL_SECONDS * FPS # 1800 frames

# ฟอนต์ภาษาไทยของระบบ macOS
FONT_PATH = "/System/Library/Fonts/Supplemental/Thonburi.ttc"
try:
    font_large = ImageFont.truetype(FONT_PATH, 34)
    font_medium = ImageFont.truetype(FONT_PATH, 24)
    font_small = ImageFont.truetype(FONT_PATH, 18)
    font_title = ImageFont.truetype(FONT_PATH, 42)
except Exception:
    font_large = font_medium = font_small = font_title = ImageFont.load_default()

# =============================================================================
# 1. ระบบสังเคราะห์ดนตรีและการ์ตูน Sound FX (Cartoon Soundtrack & Audio Engine)
# =============================================================================
def generate_cartoon_audio(duration_sec=60, sample_rate=44100):
    """สร้างเพลงการ์ตูนแนวมาริมบา (Happy Marimba Pop) + Sound FX ครบ 60 วินาที"""
    t = np.linspace(0, duration_sec, int(sample_rate * duration_sec), endpoint=False)
    audio = np.zeros_like(t)
    
    # จังหวะดนตรี 120 BPM (1 บีท = 0.5 วินาที)
    beat_duration = 0.5
    total_beats = int(duration_sec / beat_duration)
    
    # ตัวโน้ต C-Major Pentatonic: C4, D4, E4, G4, A4, C5, D5, E5
    scale = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25]
    bass_scale = [130.81, 146.83, 164.81, 196.00]
    
    for b in range(total_beats):
        t_start = b * beat_duration
        idx_start = int(t_start * sample_rate)
        idx_len = int(beat_duration * sample_rate)
        idx_end = min(len(t), idx_start + idx_len)
        t_b = t[idx_start:idx_end] - t_start
        
        # 1. เสียงเบสกลอง/ตุ้บตั้บ (Bouncing Bass)
        b_freq = bass_scale[(b // 4) % len(bass_scale)]
        bass_env = np.exp(-t_b * 7.0)
        audio[idx_start:idx_end] += 0.35 * np.sin(2 * np.pi * b_freq * t_b) * bass_env
        
        # 2. เมโลดี้มาริมบา (Playful Marimba Chimes)
        m_note = scale[(b * 3 + (b // 2)) % len(scale)]
        marimba_env = np.exp(-t_b * 12.0)
        marimba_wave = (
            np.sin(2 * np.pi * m_note * t_b) +
            0.4 * np.sin(2 * np.pi * m_note * 2.0 * t_b) +
            0.15 * np.sin(2 * np.pi * m_note * 3.0 * t_b)
        )
        audio[idx_start:idx_end] += 0.30 * marimba_wave * marimba_env
        
        # 3. เสียงเคาะจังหวะ Shaker
        shaker = np.random.normal(0, 0.02, len(t_b)) * np.exp(-t_b * 25.0)
        audio[idx_start:idx_end] += shaker
        
    # --- เพิ่ม Sound Effects ประจำฉาก ---
    # SFX 1: เสียงสแกนเรดาร์ดิจิทัลของ SoilBot (วินาทีที่ 14 - 17)
    s_idx1 = int(14.0 * sample_rate)
    s_len1 = int(3.0 * sample_rate)
    t_s1 = np.linspace(0, 3.0, s_len1)
    chirp = 0.15 * np.sin(2 * np.pi * (600 + 400 * np.sin(2 * np.pi * 4 * t_s1)) * t_s1)
    audio[s_idx1:s_idx1 + s_len1] += chirp
    
    # SFX 2: เสียงสปริงเกลอร์ฉีดน้ำ ซู่ๆ (วินาทีที่ 37 - 42)
    s_idx2 = int(37.0 * sample_rate)
    s_len2 = int(5.0 * sample_rate)
    t_s2 = np.linspace(0, 5.0, s_len2)
    water_hiss = np.random.normal(0, 0.08, s_len2) * (0.6 + 0.4 * np.sin(2 * np.pi * 3.5 * t_s2))
    audio[s_idx2:s_idx2 + s_len2] += water_hiss
    
    # SFX 3: เสียงกริ๊งเวทมนตร์ดีใจ / ระฆังทอง (วินาทีที่ 48 - 52)
    s_idx3 = int(48.0 * sample_rate)
    s_len3 = int(4.0 * sample_rate)
    t_s3 = np.linspace(0, 4.0, s_len3)
    magic_bell = 0.25 * np.sin(2 * np.pi * 1046.5 * t_s3) * np.exp(-t_s3 * 1.5) + \
                 0.15 * np.sin(2 * np.pi * 1318.5 * t_s3) * np.exp(-t_s3 * 1.8)
    audio[s_idx3:s_idx3 + s_len3] += magic_bell

    # Normalization & Fade out ใน 2 วินาทีสุดท้าย
    audio = audio / (np.max(np.abs(audio)) + 1e-6) * 0.85
    fade_out_len = int(sample_rate * 2.0)
    audio[-fade_out_len:] *= np.linspace(1.0, 0.0, fade_out_len)
    
    audio_int16 = (audio * 32767).astype(np.int16)
    with wave.open(str(AUDIO_WAV_PATH), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(audio_int16.tobytes())
        
    print(f"🎵 สังเคราะห์เพลงการ์ตูนเกษตรดิจิทัลสำเร็จ: {AUDIO_WAV_PATH}")
    return str(AUDIO_WAV_PATH)

# =============================================================================
# 2. อุปกรณ์วาดตัวละครการ์ตูน (Cartoon Character Drawing Engine)
# =============================================================================
def draw_durian_character(draw, cx, cy, scale=1.0, mood="happy", bounce_offset=0):
    """วาดตัวละครการ์ตูน 'น้องหนามน้อย' (Durian-chan) พร้อมอนิเมชันสีหน้า"""
    cy += bounce_offset
    rx = int(75 * scale)
    ry = int(95 * scale)
    
    # 1. วาดหนามรอบตัวทุเรียน (Mini Spikes)
    num_spikes = 20
    spike_r = max(rx, ry) + int(14 * scale)
    for i in range(num_spikes):
        angle = (2 * math.pi / num_spikes) * i
        sx = cx + int((rx + 8 * scale) * math.cos(angle))
        sy = cy + int((ry + 8 * scale) * math.sin(angle))
        tip_x = cx + int((rx + 22 * scale) * math.cos(angle))
        tip_y = cy + int((ry + 22 * scale) * math.sin(angle))
        draw.polygon([(sx - 8, sy), (sx + 8, sy), (tip_x, tip_y)], fill=(115, 175, 55))
        
    # 2. ลำตัวรูปไข่สีเขียวทอง
    body_col = (138, 195, 74) if mood != "thirsty" else (160, 160, 95)
    draw.ellipse([(cx - rx, cy - ry), (cx + rx, cy + ry)], fill=body_col, outline=(90, 145, 40), width=3)
    
    # 3. ขั้วก้านและใบไม้หมวกจิ๋วบนหัว
    stem_top = cy - ry - int(25 * scale)
    draw.line([(cx, cy - ry), (cx - 5, stem_top)], fill=(92, 64, 51), width=6)
    # ใบไม้ประดับ
    draw.polygon([(cx - 5, stem_top), (cx + 25, stem_top - 12), (cx + 15, stem_top + 8)], fill=(76, 175, 80))
    
    # 4. สีหน้าและดวงตาตามอารมณ์
    eye_y = cy - int(12 * scale)
    eye_offset = int(24 * scale)
    
    if mood == "thirsty": # หน้าหิวน้ำ ปากเบะ เหงื่อตก
        # ตาหมุนวน X_X
        draw.line([(cx - eye_offset - 8, eye_y - 8), (cx - eye_offset + 8, eye_y + 8)], fill=(40, 40, 40), width=3)
        draw.line([(cx - eye_offset + 8, eye_y - 8), (cx - eye_offset - 8, eye_y + 8)], fill=(40, 40, 40), width=3)
        draw.line([(cx + eye_offset - 8, eye_y - 8), (cx + eye_offset + 8, eye_y + 8)], fill=(40, 40, 40), width=3)
        draw.line([(cx + eye_offset + 8, eye_y - 8), (cx + eye_offset - 8, eye_y + 8)], fill=(40, 40, 40), width=3)
        # ปากคลื่นหยัก
        draw.arc([cx - 15, cy + 18, cx + 15, cy + 32], 180, 360, fill=(60, 60, 60), width=3)
        # หยดเหงื่อสีฟ้าข้างแก้ม
        draw.ellipse([(cx + rx - 5, cy - 20), (cx + rx + 12, cy - 5)], fill=(33, 150, 243))
        
    elif mood == "shocked": # ตาโตอ้าปากหวอ ตกใจความรู้ใหม่
        draw.ellipse([(cx - eye_offset - 10, eye_y - 12), (cx - eye_offset + 10, eye_y + 12)], fill=(255, 255, 255), outline=(0, 0, 0), width=2)
        draw.ellipse([(cx + eye_offset - 10, eye_y - 12), (cx + eye_offset + 10, eye_y + 12)], fill=(255, 255, 255), outline=(0, 0, 0), width=2)
        draw.ellipse([(cx - eye_offset - 3, eye_y - 4), (cx - eye_offset + 3, eye_y + 4)], fill=(0, 0, 0))
        draw.ellipse([(cx + eye_offset - 3, eye_y - 4), (cx + eye_offset + 3, eye_y + 4)], fill=(0, 0, 0))
        # ปากอ้าวงรีใหญ่
        draw.ellipse([(cx - 14, cy + 15), (cx + 14, cy + 42)], fill=(220, 50, 50), outline=(0, 0, 0), width=2)
        
    else: # happy: ตาแป๋วมียิ้ม แก้มชมพู (Anime sparkle eyes)
        # ตาโตสีดำประกายขาว
        for ex in [cx - eye_offset, cx + eye_offset]:
            draw.ellipse([(ex - 12, eye_y - 14), (ex + 12, eye_y + 14)], fill=(25, 25, 25))
            draw.ellipse([(ex - 6, eye_y - 10), (ex + 2, eye_y - 2)], fill=(255, 255, 255)) # ไฮไลต์ใหญ่
            draw.ellipse([(ex + 2, eye_y + 2), (ex + 6, eye_y + 6)], fill=(255, 255, 255))   # ไฮไลต์เล็ก
        # แก้มชมพูระเรื่อ
        draw.ellipse([(cx - eye_offset - 18, eye_y + 12), (cx - eye_offset + 2, eye_y + 26)], fill=(255, 130, 160))
        draw.ellipse([(cx + eye_offset - 2, eye_y + 12), (cx + eye_offset + 18, eye_y + 26)], fill=(255, 130, 160))
        # ปากยิ้มกว้างเห็นลิ้น
        draw.chord([(cx - 18, cy + 12), (cx + 18, cy + 38)], 0, 180, fill=(229, 57, 53), outline=(0, 0, 0), width=2)
        draw.chord([(cx - 10, cy + 24), (cx + 10, cy + 38)], 0, 180, fill=(255, 182, 193))
        
        # มงกุฎทองเกรด A ถ้าเป็นฉากสุดท้าย
        if mood == "gold_crown":
            cw = 50
            draw.polygon([(cx - cw, cy - ry - 15), (cx - cw + 15, cy - ry - 40), (cx, cy - ry - 20),
                          (cx + cw - 15, cy - ry - 40), (cx + cw, cy - ry - 15)], fill=(255, 215, 0), outline=(200, 160, 0), width=2)

def draw_soilbot(draw, cx, cy, float_offset=0, scanning=False):
    """วาดหุ่นยนต์โรบอตเซนเซอร์ 'SoilBot' ลอยได้ พร้อมโพรบวัดดิน"""
    cy += float_offset
    
    # 1. ไอพ่นเรืองแสงด้านล่าง (Thruster Glow)
    flame_h = 15 + int(8 * math.sin(time.time() * 20))
    draw.polygon([(cx - 14, cy + 38), (cx + 14, cy + 38), (cx, cy + 38 + flame_h)], fill=(0, 229, 255))
    
    # 2. โพรบสแตนเลสปักลงดิน (Soil Probe)
    draw.line([(cx, cy + 35), (cx, cy + 120)], fill=(200, 215, 225), width=7)
    draw.polygon([(cx - 5, cy + 120), (cx + 5, cy + 120), (cx, cy + 135)], fill=(120, 140, 160)) # หัวแหลม
    
    # วงแหวนเซนเซอร์เรืองแสง N-P-K บนก้านโพรบ
    draw.ellipse([(cx - 8, cy + 55), (cx + 8, cy + 63)], fill=(0, 255, 180))  # N
    draw.ellipse([(cx - 8, cy + 75), (cx + 8, cy + 83)], fill=(255, 215, 0))  # P
    draw.ellipse([(cx - 8, cy + 95), (cx + 8, cy + 103)], fill=(255, 64, 129)) # K
    
    # 3. ลำตัวหุ่นยนต์แคปซูลสีขาวเงา (Sleek White Capsule)
    draw.rounded_rectangle([(cx - 42, cy - 42), (cx + 42, cy + 38)], radius=22, fill=(245, 250, 255), outline=(100, 140, 180), width=3)
    
    # 4. หน้าจอ LED ดิจิทัลทรงกลมสีฟ้าไซยาน (Digital Visor)
    draw.rounded_rectangle([(cx - 32, cy - 25), (cx + 32, cy + 15)], radius=12, fill=(10, 25, 40), outline=(0, 200, 255), width=2)
    
    # ดวงตาดิจิทัลบนหน้าจอ
    if scanning:
        # ตาแบบเรดาร์สแกน ( ^ o ^ )
        draw.arc([cx - 24, cy - 14, cx - 8, cy + 2], 180, 360, fill=(0, 255, 255), width=3)
        draw.arc([cx + 8, cy - 14, cx + 24, cy + 2], 180, 360, fill=(0, 255, 255), width=3)
    else:
        # ตาปกติ (> <)
        draw.text((cx - 20, cy - 18), "^  ^", fill=(0, 255, 200), font=font_small)
        
    # 5. เสาสัญญาณ Wi-Fi / LoRaWAN บนหัว
    draw.line([(cx, cy - 42), (cx, cy - 65)], fill=(120, 140, 160), width=3)
    draw.ellipse([(cx - 6, cy - 72), (cx + 6, cy - 60)], fill=(255, 60, 60))
    # คลื่นวิทยุส่งสัญญาณ
    if scanning:
        for rad in [14, 24, 34]:
            draw.arc([cx - rad, cy - 66 - rad, cx + rad, cy - 66 + rad], 220, 320, fill=(0, 220, 255), width=2)

def draw_speech_bubble(draw, x, y, w, h, text, speaker="durian", sub_text=""):
    """วาดบอลลูนคำพูดการ์ตูนสดใสสวยงาม (Cartoon Speech Bubble)"""
    bg_col = (255, 255, 255)
    border_col = (50, 60, 70)
    draw.rounded_rectangle([(x, y), (x + w, y + h)], radius=20, fill=bg_col, outline=border_col, width=3)
    
    # หางบอลลูนชี้ไปที่ตัวละคร
    if speaker == "durian":
        draw.polygon([(x + 40, y + h), (x + 70, y + h), (x + 20, y + h + 22)], fill=bg_col)
        draw.line([(x + 40, y + h), (x + 20, y + h + 22)], fill=border_col, width=3)
        draw.line([(x + 70, y + h), (x + 20, y + h + 22)], fill=border_col, width=3)
    else: # soilbot
        draw.polygon([(x + w - 70, y + h), (x + w - 40, y + h), (x + w - 20, y + h + 22)], fill=bg_col)
        draw.line([(x + w - 70, y + h), (x + w - 20, y + h + 22)], fill=border_col, width=3)
        draw.line([(x + w - 40, y + h), (x + w - 20, y + h + 22)], fill=border_col, width=3)
        
    draw.text((x + 25, y + 16), text, fill=(30, 30, 30), font=font_large)
    if sub_text:
        draw.text((x + 25, y + 58), sub_text, fill=(0, 130, 200), font=font_medium)

def draw_knowledge_card(draw, x, y, w, h, title, points):
    """วาดการ์ดความรู้วิชาการสไตล์ Infographic การ์ตูนอ่านง่าย"""
    draw.rounded_rectangle([(x, y), (x + w, y + h)], radius=18, fill=(245, 250, 255), outline=(0, 160, 220), width=3)
    # หัวการ์ด
    draw.rounded_rectangle([(x, y), (x + w, y + 55)], radius=18, fill=(0, 170, 230))
    draw.rectangle([(x, y + 35), (x + w, y + 55)], fill=(0, 170, 230))
    draw.text((x + 20, y + 10), title, fill=(255, 255, 255), font=font_title)
    
    for idx, p in enumerate(points):
        draw.text((x + 25, y + 75 + idx * 42), p, fill=(40, 50, 60), font=font_medium)

# =============================================================================
# 3. เรนเดอร์ 5 องก์เรื่องราวการ์ตูน (1 นาที = 60 วินาที)
# =============================================================================
def render_cartoon_frame(frame_idx, total_frames=1800):
    sec = frame_idx / FPS
    img = Image.new("RGB", (WIDTH, HEIGHT), (220, 240, 255))
    draw = ImageDraw.Draw(img)
    
    # คำนวณแอนิเมชันเด้งดึ๋งของตัวละคร (Bouncing animation @ 2 Hz)
    bounce = int(8 * abs(math.sin(sec * 4 * math.pi)))
    float_bot = int(12 * math.sin(sec * 2 * math.pi))
    
    # -------------------------------------------------------------
    # องก์ที่ 1 (0:00 - 0:12): วิกฤตแล้ง! น้องหนามน้อยหิวน้ำ
    # -------------------------------------------------------------
    if sec < 12.0:
        # ท้องฟ้าส้มแดดเปรี้ยง
        draw.rectangle([(0, 0), (WIDTH, 500)], fill=(255, 235, 190))
        # พระอาทิตย์ยักษ์ใส่แว่นตากันแดด
        draw.ellipse([(WIDTH - 180, -40), (WIDTH + 60, 200)], fill=(255, 160, 40))
        # ผิวดินแตกระแหงสีน้ำตาลแห้ง
        draw.rectangle([(0, 500), (WIDTH, HEIGHT)], fill=(185, 145, 100))
        for crack in range(100, WIDTH, 180):
            draw.line([(crack, 500), (crack + 30, 560), (crack - 20, 640)], fill=(140, 100, 65), width=3)
            
        # ตัวละคร: น้องหนามน้อยหน้าเหี่ยว เหงื่อตก
        draw_durian_character(draw, cx=360, cy=460, scale=1.3, mood="thirsty", bounce_offset=-bounce//2)
        
        # บอลลูนคำพูด
        draw_speech_bubble(draw, 180, 140, 620, 110,
                           "โอ๊ยยย! แดดร้อนจัง ดินแห้งผากเลย!",
                           speaker="durian",
                           sub_text="ขาดน้ำแบบนี้ ใบจะไหม้ ดอกจะร่วงมั้ยเนี่ย แงงง!")
        
        # ป้ายสถานะเตือนภัยมุมขวา
        draw.rounded_rectangle([(WIDTH - 380, 140), (WIDTH - 40, 280)], radius=15, fill=(255, 80, 80))
        draw.text((WIDTH - 350, 160), "⚠️ คำเตือนสวนทุเรียน!", fill=(255, 255, 255), font=font_large)
        draw.text((WIDTH - 350, 210), "ความชื้นดิน: 26% [แล้งวิกฤต]", fill=(255, 255, 255), font=font_medium)
        draw.text((WIDTH - 350, 240), "เสี่ยง: ดอกร่วง & ผลชะงักโต", fill=(255, 240, 180), font=font_small)

    # -------------------------------------------------------------
    # องก์ที่ 2 (0:12 - 0:24): ฮีโร่มาแล้ว! SoilBot บินมาช่วยตรวจดิน
    # -------------------------------------------------------------
    elif sec < 24.0:
        local_t = (sec - 12.0) / 12.0
        # ท้องฟ้าสดใสสีฟ้าพาสเทล
        draw.rectangle([(0, 0), (WIDTH, 500)], fill=(200, 235, 255))
        # พื้นหญ้าเขียวในสวน
        draw.rectangle([(0, 500), (WIDTH, HEIGHT)], fill=(120, 185, 75))
        draw.rectangle([(0, 560), (WIDTH, HEIGHT)], fill=(140, 105, 70)) # ชั้นดิน
        
        # น้องหนามน้อยมองหุ่นยนต์ด้วยความหวัง
        draw_durian_character(draw, cx=280, cy=470, scale=1.2, mood="thirsty", bounce_offset=-bounce)
        
        # SoilBot บินเข้ามาปักดิน
        bot_x = int(820 - 60 * math.cos(local_t * math.pi))
        bot_y = 380
        draw_soilbot(draw, cx=bot_x, cy=bot_y, float_offset=float_bot, scanning=True)
        
        # คลื่นเรดาร์สแกนดินขยายเป็นวงกลม
        scan_r = int((frame_idx % 45) * 4)
        draw.arc([bot_x - scan_r, bot_y + 120 - scan_r // 2, bot_x + scan_r, bot_y + 120 + scan_r // 2], 0, 360, fill=(0, 230, 255), width=3)
        
        # บอลลูนคำพูดของ SoilBot
        draw_speech_bubble(draw, 420, 110, 680, 115,
                           "ปี๊บๆ! ไม่ต้องกลัวนะน้องหนามน้อย!",
                           speaker="soilbot",
                           sub_text="AI ดร.ชีวะ ส่งพี่ SoilBot มาตรวจสุขภาพดินด่วนแล้วจ้า!")
        
        # แผงสแกน HUD ลอยกลางอากาศ
        draw.rounded_rectangle([(bot_x - 140, bot_y - 180), (bot_x + 140, bot_y - 70)], radius=12, fill=(10, 30, 50, 200), outline=(0, 220, 255), width=2)
        draw.text((bot_x - 120, bot_y - 165), "⚡ AI SENSOR SCANNING", fill=(0, 255, 200), font=font_small)
        draw.text((bot_x - 120, bot_y - 135), f"ความชื้น: 28.5% (ต่ำเกินไป!)", fill=(255, 100, 100), font=font_small)
        draw.text((bot_x - 120, bot_y - 105), f"ค่า pH ดิน: 6.2 (กำลังสวย!)", fill=(100, 255, 150), font=font_small)

    # -------------------------------------------------------------
    # องก์ที่ 3 (0:24 - 0:36): คัมภีร์วิชาการ: ค่า pH ดิน และสูตรปุ๋ย N-P-K
    # -------------------------------------------------------------
    elif sec < 36.0:
        # ฉากห้องเรียนกระดานความรู้กลางสวน
        draw.rectangle([(0, 0), (WIDTH, HEIGHT)], fill=(235, 245, 255))
        
        # น้องหนามน้อยทำหน้าตาโต ตกใจได้ความรู้ใหม่
        draw_durian_character(draw, cx=180, cy=460, scale=1.1, mood="shocked", bounce_offset=-bounce)
        # SoilBot ยืนชี้กระดาน
        draw_soilbot(draw, cx=1100, cy=380, float_offset=float_bot, scanning=False)
        
        # การ์ดความรู้วิชาการขนาดใหญ่ตรงกลางจอ
        knowledge_points = [
            "1. ค่า pH ดินที่ดีที่สุดของทุเรียนคือ 5.5 - 6.5 (ดินเป็นกรด ปุ๋ยจะล็อค รากดูดไม่ได้!)",
            "2. ช่วงติดผลอ่อน: 'ห้ามอัดไนโตรเจน (N) เกินเด็ดขาด!' เดี๋ยวแตกใบอ่อนแข่งแล้วสลัดลูกทิ้ง!",
            "3. เพิ่มโพแทสเซียม (K) ช่วงขยายผล: เพื่อเร่งพูอ้วน เนื้อเนียน สีทอง หวานมันอร่อย",
            "4. ดินที่ดีต้องมีความชื้น 60-70% สม่ำเสมอ: ขาดน้ำผลร่วง แฉะไปเสี่ยงโรครากเน่าโคนเน่า!"
        ]
        draw_knowledge_card(draw, 310, 80, 740, 270, "📚 คัมภีร์ลับการจัดการดินสวนทุเรียน", knowledge_points)
        
        # บอลลูนน้องหนามน้อย
        draw_speech_bubble(draw, 240, 420, 680, 105,
                           "อ๋อออ! มิน่าล่ะ ปีที่แล้วลูกร่วงเกลี้ยงต้นเลย!",
                           speaker="durian",
                           sub_text="เพราะใส่ปุ๋ยผิดช่วง แถมไม่รู้ค่า pH ดินนี่เอง พี่ SoilBot ฉลาดจัง!")

    # -------------------------------------------------------------
    # องก์ที่ 4 (0:36 - 0:48): สปริงเกลอร์ทำงาน! น้องหนามน้อยสดชื่นนน
    # -------------------------------------------------------------
    elif sec < 48.0:
        # สวนชุ่มฉ่ำ สีเขียวสดใส
        draw.rectangle([(0, 0), (WIDTH, 480)], fill=(180, 235, 255))
        draw.rectangle([(0, 480), (WIDTH, HEIGHT)], fill=(76, 175, 80))
        
        # สปริงเกลอร์หมุนฉีดละอองน้ำระยิบระยับ
        sprinkler_x = 720
        draw.line([(sprinkler_x, 480), (sprinkler_x, 400)], fill=(50, 50, 50), width=6)
        draw.ellipse([(sprinkler_x - 12, 390), (sprinkler_x + 12, 405)], fill=(0, 180, 255))
        
        # หยดน้ำและละอองน้ำฟุ้งกระจาย (Water Particles)
        for drop in range(24):
            d_angle = (drop * 15 + frame_idx * 12) * math.pi / 180
            d_dist = 60 + (drop * 14) % 280
            dx = int(sprinkler_x + d_dist * math.cos(d_angle))
            dy = int(400 - abs(d_dist * math.sin(d_angle) * 0.7))
            draw.ellipse([(dx - 4, dy - 4), (dx + 4, dy + 4)], fill=(0, 220, 255))
            
        # น้องหนามน้อยตัวพอง ยิ้มแป้นสดชื่นสุดๆ (Happy Face)
        draw_durian_character(draw, cx=360, cy=440, scale=1.35, mood="happy", bounce_offset=-bounce * 2)
        # SoilBot ยิ้มดีใจ
        draw_soilbot(draw, cx=1020, cy=340, float_offset=float_bot, scanning=False)
        
        # บอลลูนน้องหนามน้อยร้องฟิน
        draw_speech_bubble(draw, 180, 110, 680, 115,
                           "สดชื่นนนนที่สุดในโลกเลยยยย! 💦",
                           speaker="durian",
                           sub_text="สปริงเกลอร์ AI ให้น้ำพอดีเป๊ะ ดินชุ่มฉ่ำ 65% รากฟื้นตัวแข็งแรงแล้ว!")
        
        # ป้ายบอกความสำเร็จ
        draw.rounded_rectangle([(WIDTH - 380, 110), (WIDTH - 40, 230)], radius=15, fill=(46, 125, 50))
        draw.text((WIDTH - 350, 125), "✔ ระบบน้ำอัตโนมัติ", fill=(255, 255, 255), font=font_large)
        draw.text((WIDTH - 350, 170), "ความชื้น: 65% [สมบูรณ์แบบ!]", fill=(120, 255, 180), font=font_medium)

    # -------------------------------------------------------------
    # องก์ที่ 5 (0:48 - 1:00): สวนทุเรียนเกรด A พรีเมียม & บทสรุปเกษตรดิจิทัล
    # -------------------------------------------------------------
    else:
        # ท้องฟ้าฉลองสีทอง แสงระยิบระยับ
        draw.rectangle([(0, 0), (WIDTH, 480)], fill=(255, 248, 225))
        draw.rectangle([(0, 480), (WIDTH, HEIGHT)], fill=(100, 165, 60))
        
        # พลุและประกายดาวฉลองผลผลิต
        for star in range(16):
            sx = int(100 + (star * 75 + frame_idx * 3) % (WIDTH - 200))
            sy = int(80 + (star * 35) % 300)
            draw.text((sx, sy), "✨", fill=(255, 215, 0), font=font_large)
            
        # น้องหนามน้อยโตเป็นทุเรียนหมอนทองพูอ้วน ใส่มงกุฎทองเกรด A!
        draw_durian_character(draw, cx=440, cy=430, scale=1.5, mood="gold_crown", bounce_offset=-bounce)
        # SoilBot บินเคียงข้างอย่างภูมิใจ
        draw_soilbot(draw, cx=860, cy=350, float_offset=float_bot, scanning=False)
        
        # ป้ายสรุปผลผลิตเกรดพรีเมียม
        draw.rounded_rectangle([(180, 80), (WIDTH - 180, 230)], radius=20, fill=(255, 255, 255), outline=(255, 180, 0), width=4)
        draw.text((220, 95), "👑 ทุเรียนหมอนทองเกรด A ส่งออกสำเร็จ!", fill=(230, 81, 0), font=font_title)
        draw.text((220, 150), "ผลผลิตดก พูอ้วนสวย เนื้อเนียนละเอียด รสชาติหวานมัน ได้ราคาพรีเมียม!", fill=(60, 60, 60), font=font_large)
        draw.text((220, 190), "เพราะใช้ 'เกษตรดิจิทัล AI' ดูแลดินและน้ำอย่างแม่นยำทุกขั้นตอน ✔", fill=(46, 125, 50), font=font_medium)
        
        # ท้ายคลิป: เครดิตโครงการวิจัย
        draw.text((280, 650), "โครงการวิจัย Smart Durian AI • ผศ.ดร.ชีวะ ทัศนา และคณะวิจัย (RBRU)", fill=(255, 255, 255), font=font_medium)

    return img

def main():
    print(f"\n🎬 เริ่มต้นสร้างวิดีโอการ์ตูนเกษตรดิจิทัล 1 นาที ({TOTAL_SECONDS} วินาที @ {FPS} fps = {TOTAL_FRAMES} เฟรม)...")
    start_time = time.time()
    
    # 1. สังเคราะห์ดนตรีประกอบการ์ตูนสดใส + Sound FX
    audio_wav = generate_cartoon_audio(duration_sec=TOTAL_SECONDS, sample_rate=44100)
    
    # 2. เรนเดอร์เฟรมและส่งผ่าน FFmpeg Pipe
    ffmpeg_cmd = [
        "/opt/homebrew/bin/ffmpeg",
        "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{WIDTH}x{HEIGHT}",
        "-pix_fmt", "rgb24",
        "-r", str(FPS),
        "-i", "-",
        "-i", audio_wav,
        "-c:v", "libx264",
        "-preset", "veryfast",
        "-crf", "18",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "192k",
        "-t", "60",
        str(FINAL_VIDEO_PATH)
    ]
    
    print(f"⚡ เริ่มต้นไปป์ไลน์เรนเดอร์ FFmpeg H.264 + AAC...")
    proc = subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE)
    
    for f in range(TOTAL_FRAMES):
        frame_img = render_cartoon_frame(f, TOTAL_FRAMES)
        proc.stdin.write(frame_img.tobytes())
        if f % 300 == 0:
            elapsed = time.time() - start_time
            fps_speed = (f + 1) / (elapsed + 1e-6)
            pct = (f / TOTAL_FRAMES) * 100
            print(f"   🎨 ความคืบหน้า: {f}/{TOTAL_FRAMES} เฟรม ({pct:.1f}%) | ความเร็ว: {fps_speed:.1f} fps")
            
    proc.stdin.close()
    proc.wait()
    
    total_elapsed = time.time() - start_time
    print(f"\n🎉 สำเร็จสมบูรณ์! แอนิเมชันการ์ตูนความยาว 1 นาที (60.0 วินาที) ถูกเรนเดอร์เสร็จในเวลา {total_elapsed:.1f} วินาที!")
    print(f"📁 บันทึกไฟล์ที่: {FINAL_VIDEO_PATH}")

if __name__ == "__main__":
    main()
