#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
Photorealistic Documentary Animation: "The Art of Hand-Planting Rice"
ภาพยนตร์สารคดีเสมือนจริง: "วิถีชาวนากับหัตถกรรมดำนาบนผืนแผ่นดินไทย"
=============================================================================
ความยาว: 60.00 วินาที (1,800 เฟรม @ 30 fps) ความละเอียด HD 720p (1280x720)
แนวภาพ: สารคดีภาพยนตร์เสมือนจริง (Cinematic Realism / National Geographic Aesthetic)
ดนตรี: อคูสติกโฟล์กไทยร่วมสมัย (Resonant Acoustic Strings & Nature Water Ambient)
=============================================================================
"""

import os
import sys
import math
import wave
import time
import json
import subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import imageio.v3 as iio

OUTPUT_DIR = Path(__file__).resolve().parent / "output_videos"
PROJECT_DIR = OUTPUT_DIR / "projects" / "05_thai_farmers_rice_planting_1min"
AUDIO_DIR = PROJECT_DIR / "audio"
THUMB_DIR = PROJECT_DIR / "thumbnails"
AUDIO_DIR.mkdir(parents=True, exist_ok=True)
THUMB_DIR.mkdir(parents=True, exist_ok=True)

FINAL_VIDEO_PATH = PROJECT_DIR / "video.mp4"
AUDIO_WAV_PATH = AUDIO_DIR / "rice_field_acoustic_soundtrack.wav"

WIDTH = 1280
HEIGHT = 720
FPS = 30
TOTAL_SECONDS = 60
TOTAL_FRAMES = TOTAL_SECONDS * FPS # 1800 frames

# ฟอนต์ภาษาไทยคมชัดระดับภาพยนตร์
FONT_PATH = "/System/Library/Fonts/Supplemental/Thonburi.ttc"
try:
    font_cinematic = ImageFont.truetype(FONT_PATH, 30)
    font_sub = ImageFont.truetype(FONT_PATH, 20)
    font_title = ImageFont.truetype(FONT_PATH, 42)
    font_small = ImageFont.truetype(FONT_PATH, 16)
except Exception:
    font_cinematic = font_sub = font_title = font_small = ImageFont.load_default()

# =============================================================================
# 1. ระบบสังเคราะห์ดนตรีบรรเลงอคูสติกไทย & เสียงธรรมชาติ (Acoustic Nature Soundtrack)
# =============================================================================
def generate_rice_soundtrack(duration_sec=60, sample_rate=44100):
    """สร้างบทเพลงอคูสติกไทยร่วมสมัย (D-Major Pentatonic) เคล้าเสียงสายน้ำและลมทุ่งนา"""
    t = np.linspace(0, duration_sec, int(sample_rate * duration_sec), endpoint=False)
    audio = np.zeros_like(t)
    
    # จังหวะดนตรี 75 BPM ชวนให้เกิดความรู้สึกสงบ อบอุ่น ผูกพันกับธรรมชาติ
    beat_dur = 60.0 / 75.0 # ~0.8 วินาที
    total_beats = int(duration_sec / beat_dur)
    
    # บันไดเสียง D-Major Pentatonic: D3, F#3, A3, B3, D4, E4, F#4, A4, B4
    scale = [146.83, 185.00, 220.00, 246.94, 293.66, 329.63, 369.99, 440.00, 493.88]
    bass_notes = [73.42, 92.50, 110.00, 98.00] # Sub-bass โค้งมน
    
    for b in range(total_beats):
        b_start = b * beat_dur
        idx_s = int(b_start * sample_rate)
        idx_l = int(beat_dur * sample_rate)
        idx_e = min(len(t), idx_s + idx_l)
        t_b = t[idx_s:idx_e] - b_start
        
        # 1. เสียงสายกีตาร์โปร่ง / พิณอคูสติก (Acoustic Pluck Harmonic Attack)
        note_freq = scale[(b * 2 + (b // 3)) % len(scale)]
        pluck_env = np.exp(-t_b * 5.0)
        pluck_wave = (
            np.sin(2 * np.pi * note_freq * t_b) +
            0.5 * np.sin(2 * np.pi * note_freq * 2.0 * t_b) * np.exp(-t_b * 7.0) +
            0.2 * np.sin(2 * np.pi * note_freq * 3.0 * t_b) * np.exp(-t_b * 10.0)
        )
        audio[idx_s:idx_e] += 0.35 * pluck_wave * pluck_env
        
        # 2. เสียงเบสอุ่นๆ (Warm Acoustic Bass)
        bass_f = bass_notes[(b // 4) % len(bass_notes)]
        bass_env = np.exp(-t_b * 3.5)
        audio[idx_s:idx_e] += 0.30 * np.sin(2 * np.pi * bass_f * t_b) * bass_env
        
    # 3. เสียงธรรมชาติแห่งท้องทุ่ง (เสียงน้ำไหลในคันนา + เสียงลมพัดยอดข้าว)
    water_flow = np.random.normal(0, 0.02, len(t))
    # ปรับ Low-pass จำลองเสียงน้ำไหลเอื่อยๆ
    audio += water_flow * (0.5 + 0.3 * np.sin(2 * np.pi * 0.2 * t))
    
    # 4. เสียงสายน้ำกระเซ็นยามปักดำต้นกล้า (Water splashes at key moments)
    for splash_sec in [14, 26, 32, 38, 44]:
        sp_idx = int(splash_sec * sample_rate)
        sp_len = int(1.2 * sample_rate)
        t_sp = np.linspace(0, 1.2, sp_len)
        splash = 0.08 * np.random.normal(0, 1.0, sp_len) * np.exp(-t_sp * 4.0)
        audio[sp_idx:sp_idx + sp_len] += splash
        
    # Normalization & Fade out 3 วินาทีสุดท้าย
    audio = audio / (np.max(np.abs(audio)) + 1e-6) * 0.85
    fade_len = int(sample_rate * 3.0)
    audio[-fade_len:] *= np.linspace(1.0, 0.0, fade_len)
    
    audio_int16 = (audio * 32767).astype(np.int16)
    with wave.open(str(AUDIO_WAV_PATH), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(audio_int16.tobytes())
        
    print(f"🎵 สังเคราะห์บทเพลงวิถีชาวนาสำเร็จ: {AUDIO_WAV_PATH}")
    return str(AUDIO_WAV_PATH)

# =============================================================================
# 2. ฟังก์ชันวาดทัศนียภาพและรายละเอียดเสมือนจริง (Photorealistic Canvas Engine)
# =============================================================================
def draw_dawn_sky_and_mountains(draw, sec):
    """วาดท้องฟ้ายามเช้า แสงสีทอง และทิวเขาเงาหมอกแบบ National Geographic"""
    # 1. ไล่เฉดท้องฟ้าสีทอง-ส้ม-ฟ้าอมชมพู
    for y in range(0, 360):
        ratio = y / 360.0
        r = int(245 - 30 * ratio)
        g = int(160 + 50 * ratio)
        b = int(90 + 95 * ratio)
        draw.line([(0, y), (WIDTH, y)], fill=(r, g, b))
        
    # 2. พระอาทิตย์สีทองยามเช้ากำลังขึ้นพ้นเหลี่ยมเขา
    sun_x, sun_y = int(WIDTH * 0.65), 180
    for r_outer in range(120, 20, -15):
        draw.ellipse([(sun_x - r_outer, sun_y - r_outer), (sun_x + r_outer, sun_y + r_outer)], fill=(255, 240, 190, 40))
    draw.ellipse([(sun_x - 30, sun_y - 30), (sun_x + 30, sun_y + 30)], fill=(255, 250, 220))
    
    # 3. ทิวเขาสลับซับซ้อนเคล้าสายหมอก (Mountain Ridges in Fog)
    # เขาชั้นไกลสุด
    draw.polygon([(0, 340), (280, 220), (620, 280), (950, 200), (WIDTH, 290), (WIDTH, 360), (0, 360)], fill=(135, 140, 160))
    # หมอกบางๆ คลุมเขา
    draw.rectangle([(0, 260), (WIDTH, 320)], fill=(240, 240, 245, 120))
    # เขาชั้นกลางสีเขียวชอุ่มเข้ม
    draw.polygon([(0, 350), (380, 260), (740, 330), (1080, 250), (WIDTH, 340), (WIDTH, 370), (0, 370)], fill=(80, 105, 85))

def draw_flooded_paddy_field(draw, frame_idx, sec):
    """วาดผืนนาขังน้ำสะท้อนเงาท้องฟ้า พร้อมระลอกคลื่นน้ำ (Water Ripples)"""
    # พื้นผิวน้ำในนา (สะท้อนสีท้องฟ้าและโคลนตม)
    for y in range(360, HEIGHT):
        ratio = (y - 360) / (HEIGHT - 360)
        # สะท้อนแสงทองของท้องฟ้าด้านบน แต่มีความลึกของโคลนตมด้านล่าง
        r = int(190 * (1 - ratio) + 60 * ratio)
        g = int(160 * (1 - ratio) + 50 * ratio)
        b = int(110 * (1 - ratio) + 35 * ratio)
        draw.line([(0, y), (WIDTH, y)], fill=(r, g, b))
        
    # คันนาคดเคี้ยวสีดินเข้ม (Earthen Dikes)
    draw.polygon([(0, 410), (WIDTH, 390), (WIDTH, 405), (0, 425)], fill=(75, 55, 40))
    draw.polygon([(0, 500), (WIDTH, 480), (WIDTH, 498), (0, 520)], fill=(65, 45, 30))
    
    # กอข้าวต้นกล้าที่ปักดำแล้วเป็นแถวระเบียบประณีต (Rows of Planted Seedlings)
    for row in range(3):
        ry = 440 + row * 85
        spacing = 65 + row * 15
        for rx in range(40, WIDTH - 20, spacing):
            # ระลอกคลื่นน้ำรอบกอข้าว
            rip_r = int((frame_idx * 0.8 + rx) % 25)
            draw.arc([rx - rip_r, ry + 12 - rip_r // 3, rx + rip_r, ry + 12 + rip_r // 3], 0, 360, fill=(230, 215, 180), width=1)
            # กอต้นกล้าสีเขียวมรกต 3-4 ต้น
            draw.line([(rx, ry + 15), (rx - 5, ry - 18)], fill=(0, 200, 80), width=2)
            draw.line([(rx, ry + 15), (rx + 2, ry - 24)], fill=(46, 204, 113), width=2)
            draw.line([(rx, ry + 15), (rx + 8, ry - 16)], fill=(39, 174, 96), width=2)

def draw_farmer_planting(draw, cx, cy, frame_idx, action="plant"):
    """วาดภาพจำลองชาวนาก้มดำนา สวมเสื้อม่อฮ่อมและหมวกงอบแบบสมจริง"""
    # 1. เงาสะท้อนในน้ำใต้ตัวชาวนา (Water Reflection)
    draw.ellipse([(cx - 70, cy + 95), (cx + 70, cy + 125)], fill=(40, 30, 20, 180))
    
    # 2. ขาและเท้าที่ก้าวลงในโคลนตม (Muddy Legs in Water)
    draw.polygon([(cx - 28, cy + 45), (cx - 18, cy + 105), (cx - 36, cy + 105)], fill=(50, 40, 35))
    draw.polygon([(cx + 12, cy + 45), (cx + 26, cy + 95), (cx + 10, cy + 100)], fill=(50, 40, 35))
    # ละอองโคลนเปื้อนขา
    draw.ellipse([(cx - 28, cy + 70), (cx - 18, cy + 90)], fill=(65, 45, 30))
    
    # 3. ลำตัวก้มลงเพื่อปักดำ (Bending Torso in Indigo Mor Hom)
    # เสื้อม่อฮ่อมสีน้ำเงินครามธรรมชาติ
    draw.polygon([(cx - 45, cy + 10), (cx + 35, cy + 5), (cx + 45, cy + 55), (cx - 35, cy + 60)], fill=(26, 35, 126))
    
    # 4. แขนและมือที่กำลังปักดำกล้าข้าวลงดิน
    # แขนซ้ายถือมัดต้นกล้า (Bundle of Seedlings)
    draw.line([(cx - 35, cy + 25), (cx - 65, cy + 55)], fill=(195, 140, 100), width=8) # แขน
    # มัดกล้าข้าวในมือซ้าย
    draw.ellipse([(cx - 85, cy + 45), (cx - 55, cy + 75)], fill=(46, 125, 50)) # โคนมัด
    for i in range(7):
        draw.line([(cx - 70, cy + 60), (cx - 95 - i * 3, cy + 20 - i * 2)], fill=(0, 220, 90), width=2)
        
    # แขนขวาโน้มลงปักกล้าข้าวลงในดินเลน
    sway = int(8 * math.sin(frame_idx * 0.15))
    hand_x, hand_y = cx + 15 + sway, cy + 85
    draw.line([(cx + 25, cy + 30), (hand_x, hand_y)], fill=(190, 135, 95), width=8)
    
    # ระลอกคลื่นน้ำกระจายออกจากจุดที่มือปักดำ
    rip_size = int((frame_idx * 1.5) % 40)
    draw.arc([hand_x - rip_size, hand_y + 10 - rip_size // 3, hand_x + rip_size, hand_y + 10 + rip_size // 3], 0, 360, fill=(255, 245, 210), width=2)
    # กล้าข้าวที่เพิ่งปักเสร็จสดๆ ในมือขวา
    draw.line([(hand_x, hand_y + 10), (hand_x - 4, hand_y - 20)], fill=(0, 230, 80), width=3)
    draw.line([(hand_x, hand_y + 10), (hand_x + 5, hand_y - 16)], fill=(46, 204, 113), width=2)
    
    # 5. หมวกงอบใบลานสานทรงกรวย (Traditional Ngop Bamboo Hat)
    hat_y = cy - 20
    draw.polygon([(cx - 75, hat_y + 15), (cx + 75, hat_y + 15), (cx, hat_y - 45)], fill=(215, 185, 135), outline=(160, 130, 85), width=2)
    # ลายสานของใบลาน
    for hy in range(hat_y - 30, hat_y + 10, 10):
        hw = int(75 * (hy - (hat_y - 45)) / 60)
        draw.line([(cx - hw, hy), (cx + hw, hy)], fill=(185, 155, 105), width=1)
    # ขอบงอบ
    draw.line([(cx - 75, hat_y + 15), (cx + 75, hat_y + 15)], fill=(140, 105, 65), width=3)

def draw_macro_hand_planting(draw, frame_idx, sec):
    """วาดมุมกล้องเจาะลึก (Macro Close-Up): มือชาวนาปักกล้าข้าวลงในโคลนตมละเอียด"""
    # พื้นหลังผิวน้ำใสสะท้อนแสงแดดประกายระยับ
    draw.rectangle([(0, 0), (WIDTH, HEIGHT)], fill=(75, 55, 38))
    # ผิวน้ำด้านบนใสประกาย
    for y in range(0, 380):
        alpha_ratio = y / 380.0
        draw.line([(0, y), (WIDTH, y)], fill=(int(180 - 100 * alpha_ratio), int(150 - 90 * alpha_ratio), int(105 - 65 * alpha_ratio)))
        
    # ระลอกคลื่นน้ำวงกลมซ้อนกันจากการกดมือลงโคลน
    center_x, center_y = 640, 480
    for wave_r in range(30, 380, 45):
        r_dyn = (wave_r + int(frame_idx * 1.5)) % 380
        draw.arc([center_x - r_dyn, center_y - r_dyn // 2, center_x + r_dyn, center_y + r_dyn // 2], 0, 360, fill=(240, 225, 180), width=2)
        
    # มือชาวนาผู้ช่ำชองและเปี่ยมประสบการณ์ (Weathered Hand)
    # แขนและข้อมือสีแทนคล้ำแดด
    draw.polygon([(460, 150), (560, 180), (660, 440), (580, 460)], fill=(175, 120, 80))
    # นิ้วมือ 4 นิ้วจับโคนต้นกล้าข้าวอย่างประณีต
    draw.polygon([(640, 430), (670, 460), (690, 520), (650, 530), (620, 460)], fill=(160, 105, 68))
    # นิ้วหัวแม่มือ
    draw.polygon([(590, 420), (620, 440), (635, 480), (600, 490)], fill=(165, 110, 72))
    # โคลนเปื้อนปลายนิ้ว
    draw.ellipse([(640, 500), (690, 540)], fill=(55, 38, 25))
    
    # กอต้นกล้าข้าวสีเขียวมรกต 3 ต้น ปักลึกในดินเลน
    draw.line([(660, 520), (640, 260)], fill=(0, 230, 90), width=6)
    draw.line([(660, 520), (680, 230)], fill=(46, 204, 113), width=7)
    draw.line([(660, 520), (715, 280)], fill=(39, 174, 96), width=5)
    # ใบข้าวเรียวแหลมพลิ้วไหว
    draw.polygon([(640, 260), (620, 160), (645, 250)], fill=(0, 240, 100))
    draw.polygon([(680, 230), (690, 120), (685, 220)], fill=(46, 204, 113))
    draw.polygon([(715, 280), (745, 180), (718, 270)], fill=(39, 174, 96))
    
    # หยดน้ำค้างเกาะบนยอดใบข้าวสะท้อนแสงแดด
    draw.ellipse([(620, 158), (628, 166)], fill=(255, 255, 255))
    draw.ellipse([(690, 118), (698, 126)], fill=(255, 255, 255))

def draw_telemetry_hud(draw, sec):
    """วาดข้อมูลวิทยาศาสตร์เกษตรดิจิทัล (Precision Rice Telemetry HUD)"""
    hx, hy = 840, 90
    draw.rounded_rectangle([(hx, hy), (hx + 380, hy + 195)], radius=14, fill=(15, 25, 35, 220), outline=(0, 230, 160), width=2)
    draw.text((hx + 20, hy + 15), "✦ DIGITAL PADDY TELEMETRY ✦", fill=(0, 255, 200), font=font_small)
    draw.text((hx + 20, hy + 45), f"• ระดับน้ำในแปลง: 10.5 cm [เหมาะสม]", fill=(255, 255, 255), font=font_sub)
    draw.text((hx + 20, hy + 80), f"• อุณหภูมิดินเลน: 26.8 °C [แตกกอดีเยี่ยม]", fill=(255, 225, 120), font=font_sub)
    draw.text((hx + 20, hy + 115), f"• ศักย์ออกซิเดชัน Eh: -150 mV [สภาวะรีดิวซ์]", fill=(120, 230, 255), font=font_sub)
    draw.text((hx + 20, hy + 150), f"• ค่า pH น้ำในนา: 6.2 [สมดุลธรรมชาติ]", fill=(140, 255, 180), font=font_sub)

# =============================================================================
# 3. เรนเดอร์ 5 องก์ภาพยนตร์สารคดี (60 วินาที = 1,800 เฟรม)
# =============================================================================
def render_rice_farming_frame(frame_idx, total_frames=1800):
    sec = frame_idx / FPS
    img = Image.new("RGB", (WIDTH, HEIGHT), (20, 30, 40))
    draw = ImageDraw.Draw(img)
    
    # -------------------------------------------------------------
    # องก์ที่ 1 (0:00 - 0:12): รุ่งอรุณเหนือผืนนาสีทอง
    # -------------------------------------------------------------
    if sec < 12.0:
        local_t = sec / 12.0
        draw_dawn_sky_and_mountains(draw, sec)
        draw_flooded_paddy_field(draw, frame_idx, sec)
        
        # ชาวนาเดินถือคันหลาวหอบมัดกล้าข้าวเข้าสู่แปลงนาไกลๆ
        farmer_x = int(240 + local_t * 90)
        draw_farmer_planting(draw, cx=farmer_x, cy=440, frame_idx=frame_idx, action="walk")
        
        # ป้ายเปิดสารคดีระดับภาพยนตร์ (Cinematic Title Card)
        cx, cy = WIDTH // 2, 140
        draw.rounded_rectangle([(cx - 450, cy - 65), (cx + 450, cy + 65)], radius=18, fill=(10, 20, 30, 210), outline=(218, 165, 32), width=2)
        draw.text((cx - 390, cy - 45), "วิถีแห่งแผ่นดิน: หัตถกรรมดำนาบนผืนนาไทย", fill=(255, 230, 140), font=font_title)
        draw.text((cx - 390, cy + 12), "The Art of Hand-Planting Rice • A Tribute to Thai Farmers", fill=(220, 230, 240), font=font_sub)
        
        # คำบรรยายด้านล่าง
        draw.rounded_rectangle([(140, 610), (WIDTH - 140, 685)], radius=12, fill=(15, 25, 35, 230))
        draw.text((180, 625), "“รุ่งอรุณแห่งสายธารา... เมื่อแสงแรกแห่งวันสาดส่องลงสู่ผืนน้ำและโคลนตมอันอุดมสมบูรณ์”", fill=(255, 255, 255), font=font_cinematic)

    # -------------------------------------------------------------
    # องก์ที่ 2 (0:12 - 0:24): มัดกล้าข้าวสีมรกตและก้าวลงสู่โคลนตม
    # -------------------------------------------------------------
    elif sec < 24.0:
        local_t = (sec - 12.0) / 12.0
        draw_dawn_sky_and_mountains(draw, sec)
        draw_flooded_paddy_field(draw, frame_idx, sec)
        
        # ชาวนา 2 ท่านกำลังก้าวลงนาและเริ่มปักดำ
        draw_farmer_planting(draw, cx=460, cy=470, frame_idx=frame_idx, action="plant")
        draw_farmer_planting(draw, cx=820, cy=430, frame_idx=frame_idx + 15, action="plant")
        
        # คำบรรยายภาพยนตร์
        draw.rounded_rectangle([(140, 610), (WIDTH - 140, 685)], radius=12, fill=(15, 25, 35, 230))
        draw.text((180, 625), "“มัดกล้าข้าวสีเขียวมรกตที่ฟูมฟักมานับเดือน พร้อมปักดำหยั่งรากลงสู่ผืนนาด้วยความหวัง”", fill=(255, 255, 255), font=font_cinematic)

    # -------------------------------------------------------------
    # องก์ที่ 3 (0:24 - 0:36): หัตถกรรมแห่งแผ่นดิน: การดำนาอย่างประณีต (Macro Close-up)
    # -------------------------------------------------------------
    elif sec < 36.0:
        local_t = (sec - 24.0) / 12.0
        # สลับเป็นมุมกล้องมาโครระยะประชิด (Macro Camera)
        draw_macro_hand_planting(draw, frame_idx, sec)
        
        # หัวเรื่องฉาก
        draw.text((80, 60), "MACRO PERSPECTIVE: PRECISION TRANSPLANTING", fill=(0, 240, 180), font=font_cinematic)
        
        # คำบรรยายภาพยนตร์
        draw.rounded_rectangle([(140, 610), (WIDTH - 140, 685)], radius=12, fill=(15, 25, 35, 230))
        draw.text((180, 625), "“จังหวะแห่งชีวิต: ปลายนิ้วสัมผัสโคลนเย็น ปักต้นกล้าทีละกอด้วยระยะห่างแม่นยำ 20x20 ซม.”", fill=(255, 255, 255), font=font_cinematic)

    # -------------------------------------------------------------
    # องก์ที่ 4 (0:36 - 0:48): วิทยาศาสตร์แห่งดินและน้ำในนาข้าว (Agri-Physics Telemetry)
    # -------------------------------------------------------------
    elif sec < 48.0:
        local_t = (sec - 36.0) / 12.0
        draw_dawn_sky_and_mountains(draw, sec)
        draw_flooded_paddy_field(draw, frame_idx, sec)
        
        # ชาวนาปักดำเรียงแถวสวยงาม 3 คน
        draw_farmer_planting(draw, cx=320, cy=490, frame_idx=frame_idx, action="plant")
        draw_farmer_planting(draw, cx=580, cy=460, frame_idx=frame_idx + 10, action="plant")
        draw_farmer_planting(draw, cx=840, cy=440, frame_idx=frame_idx + 20, action="plant")
        
        # แผง Telemetry ทางขวาบน
        draw_telemetry_hud(draw, sec)
        
        # คำบรรยายภาพยนตร์
        draw.rounded_rectangle([(140, 610), (WIDTH - 140, 685)], radius=12, fill=(15, 25, 35, 230))
        draw.text((180, 625), "“ผสานภูมิปัญญาดั้งเดิมกับดิจิทัลฟิสิกส์เกษตร: ควบคุมระดับน้ำและแร่ธาตุ เพื่อการแตกกอสมบูรณ์”", fill=(255, 255, 255), font=font_cinematic)

    # -------------------------------------------------------------
    # องก์ที่ 5 (0:48 - 1:00): สรรเสริญหยาดเหงื่อชาวนาไทย & บทสรุป
    # -------------------------------------------------------------
    else:
        local_t = (sec - 48.0) / 12.0
        draw_dawn_sky_and_mountains(draw, sec)
        draw_flooded_paddy_field(draw, frame_idx, sec)
        
        # แสงทองอัสดงสาดส่องทุ่งนาเป็นประกายสีทองอร่าม
        for r_len in range(80, 450, 40):
            draw.arc([640 - r_len, 200 - r_len, 640 + r_len, 200 + r_len], 30, 150, fill=(255, 220, 130), width=2)
            
        # การ์ดสดุดีชาวนาไทยตรงกลางจอ
        cx, cy = WIDTH // 2, 260
        draw.rounded_rectangle([(cx - 460, cy - 90), (cx + 460, cy + 90)], radius=20, fill=(15, 25, 35, 230), outline=(230, 185, 60), width=3)
        draw.text((cx - 410, cy - 65), "“สรรเสริญหยาดเหงื่อชาวนาไทย... กระดูกสันหลังของชาติ”", fill=(255, 235, 140), font=font_title)
        draw.text((cx - 410, cy - 10), "ผู้พลิกฟื้นผืนดิน ปลูกข้าวหล่อเลี้ยงทุกชีวิตอย่างไม่รู้เหน็ดเหนื่อย 🌾", fill=(255, 255, 255), font=font_cinematic)
        draw.text((cx - 410, cy + 40), "ดิจิทัลฟิสิกส์เกษตรและปัญญาประดิษฐ์ • ผศ.ดร.ชีวะ ทัศนา (RBRU)", fill=(0, 230, 180), font=font_sub)
        
        # ค่อยๆ เฟดลงสู่ความมืดใน 2 วินาทีสุดท้าย
        if sec > 58.0:
            dark_alpha = int(255 * ((sec - 58.0) / 2.0))
            overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, dark_alpha))
            img.paste(overlay, (0, 0), overlay)

    return img

def main():
    print(f"\n🎬 เริ่มต้นสร้างภาพยนตร์สารคดีเสมือนจริง: วิถีชาวนาดำนา ({TOTAL_SECONDS} วินาที @ {FPS} fps = {TOTAL_FRAMES} เฟรม)...")
    start_time = time.time()
    
    # 1. สังเคราะห์บทเพลงอคูสติกไทย & เสียงธรรมชาติ
    audio_wav = generate_rice_soundtrack(duration_sec=TOTAL_SECONDS, sample_rate=44100)
    
    # 2. เรนเดอร์และบันทึกลง FFmpeg Pipe
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
        frame_img = render_rice_farming_frame(f, TOTAL_FRAMES)
        proc.stdin.write(frame_img.tobytes())
        if f % 300 == 0:
            elapsed = time.time() - start_time
            fps_speed = (f + 1) / (elapsed + 1e-6)
            pct = (f / TOTAL_FRAMES) * 100
            print(f"   🌾 เรนเดอร์สารคดีชาวนา: {f}/{TOTAL_FRAMES} เฟรม ({pct:.1f}%) | ความเร็ว: {fps_speed:.1f} fps")
            
    proc.stdin.close()
    proc.wait()
    
    # 3. สกัดภาพพรีวิว 5 ซีน (Thumbnails)
    print(f"🖼️ กำลังสกัดภาพนิ่งพรีวิว 5 ฉาก...")
    for sec, f_idx in [(6, 180), (18, 540), (30, 900), (42, 1260), (54, 1620)]:
        f_arr = iio.imread(str(FINAL_VIDEO_PATH), index=f_idx)
        Image.fromarray(f_arr).save(str(THUMB_DIR / f"rice_scene_{sec}s.png"))
        
    # 4. บันทึก Metadata และ README ประจำโปรเจกต์
    meta = {
        "project_name": "05_thai_farmers_rice_planting_1min",
        "title": "The Art of Hand-Planting Rice (วิถีชาวนากับหัตถกรรมดำนาบนผืนนาไทย)",
        "theme": "ภาพยนตร์สารคดีเสมือนจริง วิถีชีวิตชาวนาไทยกำลังดำนาปลูกข้าวในทุ่งน้ำยามเช้า",
        "aesthetic": "Cinematic Photorealism / National Geographic Style",
        "elements": [
            "ผืนนาขังน้ำสะท้อนเงาท้องฟ้ายามรุ่งอรุณและทิวเขาเคล้าสายหมอก",
            "ชาวนาสวมเสื้อม่อฮ่อมสีครามและหมวกงอบใบลานสาน ก้มปักดำกล้าข้าว",
            "มุมกล้องมาโครเจาะลึก: มือชาวนาสัมผัสโคลนเลน ปักต้นกล้าข้าวสีเขียวมรกต",
            "ระลอกคลื่นน้ำกระจายวงกลมสะท้อนประกายแดดสีทอง",
            "ระบบวัดค่าระดับน้ำ อุณหภูมิดิน และศักย์ไฟฟ้า Eh (Digital Agri-Physics)"
        ],
        "duration_seconds": 60.0,
        "frames": 1800,
        "fps": 30,
        "resolution": "1280x720 (HD)",
        "audio_track": "audio/rice_field_acoustic_soundtrack.wav",
        "soundtrack_style": "Contemporary Thai Acoustic Strings & Nature Soundscape",
        "created_at": time.strftime("%Y-%m-%d %H:%M:%S")
    }
    with open(PROJECT_DIR / "metadata.json", "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
        
    with open(PROJECT_DIR / "README.md", "w", encoding="utf-8") as f:
        f.write(f"""# Project 05: {meta['title']}

### สารคดีภาพยนตร์เสมือนจริง: วิถีชาวนากับการดำนาปลูกข้าว
- **แนวคิด:** {meta['theme']}
- **สไตล์ภาพ:** {meta['aesthetic']}
- **ความยาว:** {meta['duration_seconds']} วินาที ({meta['frames']} เฟรม @ {meta['fps']} fps)
- **ความละเอียด:** {meta['resolution']}
- **บทเพลงประกอบ:** {meta['soundtrack_style']}
- **ไฟล์วิดีโอหลัก:** [`video.mp4`](file://{PROJECT_DIR}/video.mp4)

#### ภาพพรีวิวแต่ละฉาก:
- ฉาก 1: รุ่งอรุณเหนือผืนนาสีทอง [`thumbnails/rice_scene_6s.png`](file://{THUMB_DIR}/rice_scene_6s.png)
- ฉาก 2: มัดกล้าข้าวและก้าวลงสู่โคลนตม [`thumbnails/rice_scene_18s.png`](file://{THUMB_DIR}/rice_scene_18s.png)
- ฉาก 3: มาโครเจาะลึกมือปักดำกล้าข้าว [`thumbnails/rice_scene_30s.png`](file://{THUMB_DIR}/rice_scene_30s.png)
- ฉาก 4: วิทยาศาสตร์แห่งดินและน้ำในนาข้าว [`thumbnails/rice_scene_42s.png`](file://{THUMB_DIR}/rice_scene_42s.png)
- ฉาก 5: สรรเสริญหยาดเหงื่อชาวนาไทย [`thumbnails/rice_scene_54s.png`](file://{THUMB_DIR}/rice_scene_54s.png)
""")

    total_elapsed = time.time() - start_time
    print(f"\n🎉 สำเร็จสมบูรณ์! ภาพยนตร์สารคดีชาวนาดำนาความยาว 1 นาทีถูกเรนเดอร์เสร็จในเวลา {total_elapsed:.1f} วินาที!")
    print(f"📁 บันทึกในโฟลเดอร์โปรเจกต์: {PROJECT_DIR}")

if __name__ == "__main__":
    main()
