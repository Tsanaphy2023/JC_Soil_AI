#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
3D Ghibli Sci-Fi Animation: "The Secret of the Durian Orchard"
แอนิเมชัน 3D สไตล์ Studio Ghibli ผสมผสานเทคโนโลยี Sci-Fi
เรื่องราว: เด็กๆ น่ารักกับแมวขาว-แมวส้ม สำรวจและตรวจวิเคราะห์ดินใต้ต้นทุเรียนและมังคุด
=============================================================================
ความยาว: 60.00 วินาที (1,800 เฟรม @ 30 fps) ความละเอียด HD 720p (1280x720)
บทเพลง: ดนตรีบรรเลงสไตล์ Joe Hisaishi (Ghibli Nostalgic Piano & Orchestra)
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
PROJECT_DIR = OUTPUT_DIR / "projects" / "04_ghibli_scifi_durian_soil_1min"
(PROJECT_DIR / "audio").mkdir(parents=True, exist_ok=True)
(PROJECT_DIR / "thumbnails").mkdir(parents=True, exist_ok=True)
FINAL_VIDEO_PATH = PROJECT_DIR / "video.mp4"
AUDIO_WAV_PATH = PROJECT_DIR / "audio" / "ghibli_piano_soundtrack.wav"

WIDTH = 1280
HEIGHT = 720
FPS = 30
TOTAL_SECONDS = 60
TOTAL_FRAMES = TOTAL_SECONDS * FPS # 1800 frames

# โหลดฟอนต์ภาษาไทยสำหรับคำบรรยายสไตล์ภาพยนตร์แอนิเมชัน
FONT_PATH = "/System/Library/Fonts/Supplemental/Thonburi.ttc"
try:
    font_cinematic = ImageFont.truetype(FONT_PATH, 32)
    font_sub = ImageFont.truetype(FONT_PATH, 22)
    font_hologram = ImageFont.truetype(FONT_PATH, 20)
    font_title = ImageFont.truetype(FONT_PATH, 44)
    font_small = ImageFont.truetype(FONT_PATH, 16)
except Exception:
    font_cinematic = font_sub = font_hologram = font_title = font_small = ImageFont.load_default()

# =============================================================================
# 1. ระบบสังเคราะห์ดนตรีบรรเลงสไตล์ Studio Ghibli (Joe Hisaishi Style Soundtrack)
# =============================================================================
def generate_ghibli_soundtrack(duration_sec=60, sample_rate=44100):
    """สังเคราะห์บทเพลงเปียโนและเครื่องสายแสนอบอุ่นสไตล์ Studio Ghibli (Summer / Spirited Away)"""
    t = np.linspace(0, duration_sec, int(sample_rate * duration_sec), endpoint=False)
    audio = np.zeros_like(t)
    
    # คอร์ดดำเนินแบบ Ghibli Cadence: Fmaj7 -> G6 -> Em7 -> Am7 -> Dm9 -> G7 -> Cmaj7
    chord_duration = 3.75 # วินาทีต่อคอร์ด (16 ห้องเพลง = 60 วินาที)
    num_chords = int(duration_sec / chord_duration)
    
    ghibli_progression = [
        [174.61, 220.00, 261.63, 329.63], # Fmaj7 (F, A, C, E)
        [196.00, 246.94, 293.66, 329.63], # G6 (G, B, D, E)
        [164.81, 196.00, 246.94, 293.66], # Em7 (E, G, B, D)
        [220.00, 261.63, 329.63, 392.00], # Am7 (A, C, E, G)
        [146.83, 174.61, 220.00, 261.63, 329.63], # Dm9 (D, F, A, C, E)
        [196.00, 246.94, 293.66, 349.23], # G7 (G, B, D, F)
        [130.81, 164.81, 196.00, 246.94], # Cmaj7 (C, E, G, B)
        [130.81, 164.81, 196.00, 233.08], # C7 (C, E, G, Bb)
    ]
    
    # เมโลดี้เปียโนอ่อนหวาน (Acoustic Piano Pentatonic Lyrical Melodies)
    melody_notes = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 880.00, 659.25]
    
    for c in range(num_chords):
        c_start = c * chord_duration
        idx_start = int(c_start * sample_rate)
        idx_len = int(chord_duration * sample_rate)
        idx_end = min(len(t), idx_start + idx_len)
        t_c = t[idx_start:idx_end] - c_start
        
        chord = ghibli_progression[c % len(ghibli_progression)]
        
        # 1. Warm String Pad & Electric Piano Arpeggio
        pad_wave = np.zeros_like(t_c)
        for freq in chord:
            pad_wave += 0.25 * np.sin(2 * np.pi * freq * t_c)
            pad_wave += 0.10 * np.sin(2 * np.pi * freq * 2.0 * t_c)
            
        # Envelope การไล่เสียงอย่างนุ่มนวล
        env = (np.sin(np.pi * (t_c / chord_duration))) ** 0.6
        audio[idx_start:idx_end] += pad_wave * env
        
        # 2. เสียงเปียโนบรรเลงเมโลดี้เดี่ยว (Solo Piano Notes)
        sub_beats = 4
        sub_dur = chord_duration / sub_beats
        for sb in range(sub_beats):
            sb_start = sb * sub_dur
            sb_idx_s = int((c_start + sb_start) * sample_rate)
            sb_idx_len = int(sub_dur * sample_rate)
            sb_idx_e = min(len(t), sb_idx_s + sb_idx_len)
            t_sb = t[sb_idx_s:sb_idx_e] - (c_start + sb_start)
            
            p_note = melody_notes[(c * 2 + sb) % len(melody_notes)]
            piano_env = np.exp(-t_sb * 4.5)
            # เสียงค้อนเปียโนกระทบสาย (Piano Hammer Attack + Harmonic resonance)
            p_wave = (
                np.sin(2 * np.pi * p_note * t_sb) +
                0.5 * np.sin(2 * np.pi * p_note * 2.0 * t_sb) * np.exp(-t_sb * 7.0) +
                0.2 * np.sin(2 * np.pi * p_note * 3.0 * t_sb) * np.exp(-t_sb * 10.0)
            )
            audio[sb_idx_s:sb_idx_e] += 0.35 * p_wave * piano_env
            
    # 3. เสียงธรรมชาติแห่งป่า Ghibli (เสียงลมพัดใบไม้ + นกร้องยามเช้า)
    wind = np.random.normal(0, 0.018, len(t))
    audio += wind
    # เสียงนกทวีตแสนสดใส (Bird chirps)
    for b_sec in [5, 12, 22, 33, 44, 52]:
        b_idx = int(b_sec * sample_rate)
        b_len = int(0.6 * sample_rate)
        t_b = np.linspace(0, 0.6, b_len)
        chirp = 0.12 * np.sin(2 * np.pi * (2400 + 800 * np.sin(2 * np.pi * 14 * t_b)) * t_b) * np.exp(-t_b * 6.0)
        audio[b_idx:b_idx + b_len] += chirp
        
    # Normalization & Fade out 2.5 วินาทีสุดท้าย
    audio = audio / (np.max(np.abs(audio)) + 1e-6) * 0.85
    fade_len = int(sample_rate * 2.5)
    audio[-fade_len:] *= np.linspace(1.0, 0.0, fade_len)
    
    audio_int16 = (audio * 32767).astype(np.int16)
    with wave.open(str(AUDIO_WAV_PATH), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(audio_int16.tobytes())
        
    print(f"🎵 สังเคราะห์เพลงบรรเลง 3D Ghibli สำเร็จ: {AUDIO_WAV_PATH}")
    return str(AUDIO_WAV_PATH)

# =============================================================================
# 2. เครื่องมือวาดทัศนียภาพและตัวละคร 3D Ghibli Sci-Fi
# =============================================================================
def draw_ghibli_sky_and_trees(draw, frame_idx, sec):
    """วาดท้องฟ้าสีพาสเทล เมฆฟูสไตล์มิยาซากิ และต้นทุเรียน-มังคุดแสนร่มรื่น"""
    # 1. ท้องฟ้าสีฟ้าครามไล่เฉดแดดเช้า (Pastel Ghibli Horizon)
    for y in range(0, 480):
        ratio = y / 480.0
        r = int(140 + 75 * ratio)
        g = int(200 + 40 * ratio)
        b = int(245 - 20 * ratio)
        draw.line([(0, y), (WIDTH, y)], fill=(r, g, b))
        
    # 2. เมฆฟูขาวสไตล์ Ghibli (Miyazaki Fluffy Clouds)
    cloud_shift = (frame_idx * 0.4) % (WIDTH + 300) - 150
    for cx_base, cy_base in [(200, 110), (750, 90), (1150, 130)]:
        cx = int(cx_base + cloud_shift) % (WIDTH + 300) - 150
        for ox, oy, rad in [(-50, 10, 45), (0, -10, 65), (55, 10, 48), (25, 15, 40)]:
            draw.ellipse([(cx + ox - rad, cy_base + oy - rad), (cx + ox + rad, cy_base + oy + rad)], fill=(255, 255, 255, 220))
            
    # 3. ภูเขาไกลๆ สีฟ้าอมเขียว (Distant Verdant Hills)
    draw.polygon([(0, 460), (350, 360), (720, 440), (1100, 380), (WIDTH, 450), (WIDTH, 500), (0, 500)], fill=(120, 175, 150))
    
    # 4. พื้นดินสนามหญ้าและเนินดินสวนทุเรียน
    draw.rectangle([(0, 470), (WIDTH, HEIGHT)], fill=(85, 140, 60))
    # ผิวดินชั้นล่างสีน้ำตาลเข้มอุดมสมบูรณ์
    draw.rectangle([(0, 560), (WIDTH, HEIGHT)], fill=(105, 75, 50))
    
    # 5. ลำต้นทุเรียนใหญ่ (Ancient Durian Tree) ทางซ้าย
    draw.polygon([(60, 490), (140, 490), (115, 150), (75, 150)], fill=(95, 68, 48))
    # พุ่มใบไม้หนาทึบและผลทุเรียนหนามสีทองห้อยย้อย
    for bx, by, brad in [(80, 140, 90), (140, 110, 100), (60, 90, 80), (160, 160, 80)]:
        draw.ellipse([(bx - brad, by - brad), (bx + brad, by + brad)], fill=(65, 125, 50))
    # ผลทุเรียนห้อยจากกิ่ง
    for dx, dy in [(120, 190), (170, 220), (50, 210)]:
        draw.ellipse([(dx - 16, dy - 22), (dx + 16, dy + 22)], fill=(185, 175, 75), outline=(130, 120, 40), width=2)
        draw.line([(dx, dy - 22), (dx, dy - 30)], fill=(80, 55, 35), width=3)
        
    # 6. ต้นมังคุด (Mangosteen Tree - Queen of Fruits) ทางขวา
    draw.polygon([(1120, 490), (1190, 490), (1160, 200), (1130, 200)], fill=(105, 75, 55))
    for mx, my, mrad in [(1140, 180, 85), (1190, 150, 90), (1100, 150, 75)]:
        draw.ellipse([(mx - mrad, my - mrad), (mx + mrad, my + mrad)], fill=(50, 105, 45))
    # ผลมังคุดสีม่วงเข้ม (Royal Purple Mangosteens)
    for fx, fy in [(1110, 230), (1160, 250), (1200, 210)]:
        draw.ellipse([(fx - 14, fy - 14), (fx + 14, fy + 14)], fill=(85, 30, 85), outline=(50, 15, 50), width=2)
        # กลีบเลี้ยงสีเขียวมรกต 4 กลีบ
        draw.ellipse([(fx - 8, fy - 18), (fx + 8, fy - 10)], fill=(100, 180, 60))

def draw_white_cat(draw, cx, cy, walking=False, frame_idx=0):
    """วาด 'เจ้าเหมียวสีขาว' ตัวกลมนุ่ม สไตล์ Ghibli"""
    leg_shift = int(5 * math.sin(frame_idx * 0.4)) if walking else 0
    # หางแมวแกว่งดุ๊กดิ๊ก
    tail_angle = math.sin(frame_idx * 0.2) * 15
    tx = cx + 25
    draw.line([(tx, cy + 5), (tx + 18, cy - 15 + tail_angle)], fill=(250, 250, 250), width=6)
    
    # ขา 4 ข้าง
    draw.ellipse([(cx - 16 + leg_shift, cy + 12), (cx - 6 + leg_shift, cy + 24)], fill=(240, 240, 240))
    draw.ellipse([(cx + 6 - leg_shift, cy + 12), (cx + 16 - leg_shift, cy + 24)], fill=(240, 240, 240))
    
    # ลำตัวสีขาวขนปุย
    draw.ellipse([(cx - 22, cy - 10), (cx + 22, cy + 18)], fill=(255, 255, 255), outline=(225, 230, 235), width=2)
    # หัวแมว
    draw.ellipse([(cx - 18, cy - 26), (cx + 12, cy + 2)], fill=(255, 255, 255), outline=(225, 230, 235), width=2)
    # หูสีชมพูพาสเทล
    draw.polygon([(cx - 16, cy - 22), (cx - 22, cy - 36), (cx - 8, cy - 26)], fill=(255, 200, 215))
    draw.polygon([(cx + 2, cy - 26), (cx + 12, cy - 36), (cx + 8, cy - 22)], fill=(255, 200, 215))
    # ตาสีฟ้าไซยานสดใส
    draw.ellipse([(cx - 12, cy - 16), (cx - 6, cy - 10)], fill=(0, 180, 230))
    draw.ellipse([(cx - 2, cy - 16), (cx + 4, cy - 10)], fill=(0, 180, 230))
    # จมูกและปากยิ้ม
    draw.polygon([(cx - 5, cy - 8), (cx - 3, cy - 8), (cx - 4, cy - 6)], fill=(255, 140, 160))

def draw_orange_cat(draw, cx, cy, walking=False, frame_idx=0):
    """วาด 'เจ้าเหมียวส้มลายทาง' แสนซน สไตล์ Ghibli"""
    leg_shift = int(5 * math.cos(frame_idx * 0.4)) if walking else 0
    # หางส้มปลายขาว
    tail_angle = math.cos(frame_idx * 0.25) * 18
    tx = cx - 25
    draw.line([(tx, cy + 5), (tx - 18, cy - 18 + tail_angle)], fill=(245, 140, 40), width=6)
    
    # ขา 4 ข้าง
    draw.ellipse([(cx - 16 + leg_shift, cy + 12), (cx - 6 + leg_shift, cy + 24)], fill=(255, 250, 240))
    draw.ellipse([(cx + 6 - leg_shift, cy + 12), (cx + 16 - leg_shift, cy + 24)], fill=(255, 250, 240))
    
    # ลำตัวสีส้มทอง
    draw.ellipse([(cx - 22, cy - 10), (cx + 22, cy + 18)], fill=(245, 145, 45), outline=(200, 100, 25), width=2)
    # ลายพาดกลอนสีส้มเข้ม
    draw.line([(cx - 10, cy - 6), (cx - 10, cy + 6)], fill=(195, 90, 20), width=3)
    draw.line([(cx + 2, cy - 6), (cx + 2, cy + 6)], fill=(195, 90, 20), width=3)
    
    # หัวแมวส้ม
    draw.ellipse([(cx - 12, cy - 26), (cx + 18, cy + 2)], fill=(245, 145, 45), outline=(200, 100, 25), width=2)
    # หูส้ม
    draw.polygon([(cx - 8, cy - 24), (cx - 4, cy - 36), (cx + 4, cy - 24)], fill=(245, 130, 35))
    draw.polygon([(cx + 8, cy - 24), (cx + 18, cy - 36), (cx + 16, cy - 22)], fill=(245, 130, 35))
    # ตาสีเขียวมรกตแป๋วแหวว
    draw.ellipse([(cx - 4, cy - 16), (cx + 2, cy - 10)], fill=(76, 175, 80))
    draw.ellipse([(cx + 8, cy - 16), (cx + 14, cy - 10)], fill=(76, 175, 80))

def draw_ghibli_child(draw, cx, cy, gender="girl", action="stand", bounce=0):
    """วาดตัวละครเด็กนักสำรวจจิ๋วสไตล์ 3D Ghibli น่ารัก สดใส"""
    cy += bounce
    # ขาและรองเท้าบูททำสวน
    draw.rectangle([(cx - 14, cy + 45), (cx - 4, cy + 80)], fill=(70, 95, 135))
    draw.rectangle([(cx + 4, cy + 45), (cx + 14, cy + 80)], fill=(70, 95, 135))
    draw.ellipse([(cx - 18, cy + 74), (cx - 2, cy + 86)], fill=(160, 90, 45)) # บูทน้ำตาล
    draw.ellipse([(cx + 2, cy + 74), (cx + 18, cy + 86)], fill=(160, 90, 45))
    
    # ชุดเอี๊ยมทำสวนสีน้ำเงินเดนิม และเสื้อยืดลายขวาง
    draw.rounded_rectangle([(cx - 24, cy + 5), (cx + 24, cy + 52)], radius=10, fill=(85, 120, 175), outline=(50, 80, 130), width=2)
    # เสื้อด้านใน
    inner_col = (255, 195, 60) if gender == "girl" else (120, 215, 140)
    draw.ellipse([(cx - 18, cy - 5), (cx + 18, cy + 18)], fill=inner_col)
    
    # ใบหน้าอนิเมะ Ghibli กลมมน
    draw.ellipse([(cx - 22, cy - 42), (cx + 22, cy + 2)], fill=(255, 228, 205), outline=(220, 175, 145), width=2)
    # แก้มชมพูระเรื่อ
    draw.ellipse([(cx - 20, cy - 18), (cx - 8, cy - 6)], fill=(255, 150, 160))
    draw.ellipse([(cx + 8, cy - 18), (cx + 20, cy - 6)], fill=(255, 150, 160))
    # ตากลมโตประกายสดใส
    draw.ellipse([(cx - 14, cy - 25), (cx - 4, cy - 13)], fill=(45, 30, 20))
    draw.ellipse([(cx - 11, cy - 22), (cx - 7, cy - 17)], fill=(255, 255, 255))
    draw.ellipse([(cx + 4, cy - 25), (cx + 14, cy - 13)], fill=(45, 30, 20))
    draw.ellipse([(cx + 7, cy - 22), (cx + 11, cy - 17)], fill=(255, 255, 255))
    # รอยยิ้มสดใส
    draw.arc([cx - 8, cy - 10, cx + 8, cy + 2], 0, 180, fill=(180, 50, 50), width=2)
    
    # หมวกฟางสานใบใหญ่สไตล์มิยาซากิ พร้อมสายเสาสัญญาณ Sci-Fi จิ๋ว
    hat_y = cy - 44
    draw.ellipse([(cx - 45, hat_y - 8), (cx + 45, hat_y + 12)], fill=(235, 200, 120), outline=(180, 140, 70), width=2)
    draw.arc([cx - 26, hat_y - 28, cx + 26, hat_y + 4], 180, 360, fill=(215, 175, 95), width=18)
    # แถบผ้าคาดหมวกสีแดง
    draw.line([(cx - 26, hat_y - 4), (cx + 26, hat_y - 4)], fill=(220, 60, 60), width=4)
    # เสาสัญญาณ Sci-Fi IoT พับได้จิ๋วบนหมวก
    draw.line([(cx + 20, hat_y - 12), (cx + 28, hat_y - 32)], fill=(0, 220, 255), width=2)
    draw.ellipse([(cx + 26, hat_y - 36), (cx + 30, hat_y - 30)], fill=(0, 255, 200))

def draw_scifi_soil_hologram(draw, cx, cy, frame_idx):
    """วาดลูกแก้วโฮโลแกรมตรวจดินสามมิติ (Sci-Fi Holographic Diagnostics Sphere)"""
    rot = frame_idx * 0.08
    # วงแหวนไจโรสโคปหมุนวน 3 มิติ
    for rad, color in [(95, (0, 240, 255)), (115, (0, 255, 160)), (135, (255, 215, 0))]:
        w_box = int(rad * abs(math.cos(rot + rad)))
        draw.arc([cx - rad, cy - w_box, cx + rad, cy + w_box], 0, 360, fill=color, width=2)
        
    # แกนกลางลูกแก้วเรืองแสง
    draw.ellipse([(cx - 45, cy - 45), (cx + 45, cy + 45)], fill=(15, 45, 65), outline=(0, 255, 220), width=3)
    draw.text((cx - 30, cy - 14), "SOIL AI", fill=(0, 255, 200), font=font_small)
    
    # ละอองแร่ธาตุ N-P-K ลอยฟุ้งเป็นประกายไฟ (Bioluminescent nutrient particles)
    for p in range(16):
        p_ang = rot * 2 + p * (2 * math.pi / 16)
        p_dist = 60 + 40 * math.sin(p * 1.5 + rot)
        px = int(cx + p_dist * math.cos(p_ang))
        py = int(cy + p_dist * math.sin(p_ang) * 0.7)
        p_col = [(0, 255, 180), (255, 215, 0), (255, 100, 150), (0, 220, 255)][p % 4]
        draw.ellipse([(px - 4, py - 4), (px + 4, py + 4)], fill=p_col)

# =============================================================================
# 3. เรนเดอร์ 5 องก์เรื่องราว 3D Ghibli Sci-Fi (60 วินาที = 1,800 เฟรม)
# =============================================================================
def render_ghibli_frame(frame_idx, total_frames=1800):
    sec = frame_idx / FPS
    img = Image.new("RGB", (WIDTH, HEIGHT), (220, 245, 255))
    draw = ImageDraw.Draw(img)
    
    # วาดพื้นหลังสวนทุเรียน-มังคุด
    draw_ghibli_sky_and_trees(draw, frame_idx, sec)
    
    # ละอองแสงทองส่องลอดผ่านกิ่งไม้ (Volumetric Sunlight Rays)
    for ray in range(5):
        rx = 200 + ray * 220 + int(20 * math.sin(sec * 1.2 + ray))
        draw.polygon([(rx, 0), (rx + 70, 0), (rx + 160, HEIGHT), (rx + 40, HEIGHT)], fill=(255, 250, 210))
        
    bounce_child = int(6 * abs(math.sin(sec * 4 * math.pi)))
    
    # -------------------------------------------------------------
    # องก์ที่ 1 (0:00 - 0:12): แดดเช้าในสวนทุเรียนและมังคุดแห่งอนาคต
    # -------------------------------------------------------------
    if sec < 12.0:
        local_t = sec / 12.0
        # Title Card สไตล์ภาพยนตร์แอนิเมชันของ Studio Ghibli
        cx, cy = WIDTH // 2, 220
        draw.rounded_rectangle([(cx - 420, cy - 80), (cx + 420, cy + 80)], radius=20, fill=(255, 255, 255, 210), outline=(90, 150, 70), width=3)
        draw.text((cx - 380, cy - 55), "มหัศจรรย์สวนทุเรียน: ปริศนาดินใต้ต้นไม้ใหญ่", fill=(45, 85, 35), font=font_title)
        draw.text((cx - 380, cy + 12), "3D Ghibli Sci-Fi • The Secret of the Durian Orchard", fill=(80, 130, 95), font=font_cinematic)
        
        # แมวขาวกับแมวส้มวิ่งไล่ผีเสื้อไซไฟเรืองแสง
        draw_white_cat(draw, cx=480 + int(local_t * 80), cy=510, walking=True, frame_idx=frame_idx)
        draw_orange_cat(draw, cx=360 + int(local_t * 80), cy=515, walking=True, frame_idx=frame_idx)
        
        # ผีเสื้อโฮโลแกรมไซไฟบินนำทาง
        bf_x = 580 + int(local_t * 90) + int(20 * math.sin(frame_idx * 0.3))
        bf_y = 460 + int(15 * math.cos(frame_idx * 0.4))
        draw.ellipse([(bf_x - 8, bf_y - 8), (bf_x + 8, bf_y + 8)], fill=(0, 240, 255))
        draw.text((bf_x - 4, bf_y - 20), "✨", fill=(255, 215, 0), font=font_small)

    # -------------------------------------------------------------
    # องก์ที่ 2 (0:12 - 0:24): เด็กๆ นักสำรวจจิ๋วและสองเหมียวออกเดินทาง
    # -------------------------------------------------------------
    elif sec < 24.0:
        local_t = (sec - 12.0) / 12.0
        # เด็กผู้หญิงและเด็กผู้ชายสะพายกระเป๋าอุปกรณ์ไซไฟ
        draw_ghibli_child(draw, cx=380, cy=460, gender="girl", bounce=bounce_child)
        draw_ghibli_child(draw, cx=520, cy=465, gender="boy", bounce=-bounce_child)
        
        # แมวขาวเดินคลอเคลียข้างขาเด็กผู้หญิง แมวส้มวิ่งนำหน้า
        draw_white_cat(draw, cx=310, cy=520, walking=True, frame_idx=frame_idx)
        draw_orange_cat(draw, cx=640, cy=515, walking=True, frame_idx=frame_idx)
        
        # กล่องแคปซูลเก็บตัวอย่างดินไฮเทคลอยตามหลังเด็กๆ (Anti-gravity Pod)
        pod_x = 240 + int(15 * math.sin(sec * 3))
        pod_y = 440 + int(10 * math.cos(sec * 2))
        draw.rounded_rectangle([(pod_x - 30, pod_y - 20), (pod_x + 30, pod_y + 20)], radius=12, fill=(240, 250, 255), outline=(0, 200, 255), width=2)
        draw.text((pod_x - 22, pod_y - 10), "AI POD", fill=(0, 180, 220), font=font_small)
        
        # ป้ายคำบรรยายภาพยนตร์ด้านล่าง
        draw.rounded_rectangle([(140, 610), (WIDTH - 140, 685)], radius=14, fill=(20, 35, 45, 220))
        draw.text((180, 625), "“ไปกันเถอะเจ้าเหมียว! วันนี้เราจะไปเก็บตัวอย่างดินใต้ต้นทุเรียนต้นใหญ่กัน!”", fill=(255, 255, 255), font=font_cinematic)

    # -------------------------------------------------------------
    # องก์ที่ 3 (0:24 - 0:36): การเก็บตัวอย่างดินใต้ต้นทุเรียนยักษ์
    # -------------------------------------------------------------
    elif sec < 36.0:
        local_t = (sec - 24.0) / 12.0
        # ซูมมุมใกล้ใต้ร่มเงาต้นทุเรียนโบราณ
        draw.text((80, 80), "SCENE: DEEP ROOT-ZONE SAMPLING", fill=(60, 120, 60), font=font_cinematic)
        
        # เด็กๆ นั่งคุกเข่าใช้ช้อนตักดินไซไฟเรืองแสง
        draw_ghibli_child(draw, cx=440, cy=480, gender="girl", bounce=0)
        
        # ช้อนตักดินไซไฟเรืองแสงสีฟ้า (Glowing Quantum Trowel)
        draw.line([(475, 520), (510, 545)], fill=(0, 220, 255), width=5)
        draw.ellipse([(505, 540), (525, 555)], fill=(0, 255, 200))
        
        # ชั้นดินตัดขวางใต้ต้นทุเรียน แสดงรากฝอยและเม็ดดินอุดมสมบูรณ์
        draw.rectangle([(510, 545), (820, 650)], fill=(85, 60, 40), outline=(120, 90, 60), width=3)
        for r_line in [(530, 550, 590, 620), (600, 560, 660, 640), (680, 555, 740, 610)]:
            draw.line([(r_line[0], r_line[1]), (r_line[2], r_line[3])], fill=(220, 190, 140), width=3)
            
        # แมวขาวนั่งมองตาแป๋ว แมวส้มนอนเกลือกกลิ้งบนหญ้าอย่างมีความสุข
        draw_white_cat(draw, cx=320, cy=525, walking=False, frame_idx=frame_idx)
        draw_orange_cat(draw, cx=900, cy=535, walking=False, frame_idx=frame_idx)
        
        # ป้ายบรรยายภาพยนตร์
        draw.rounded_rectangle([(140, 610), (WIDTH - 140, 685)], radius=14, fill=(20, 35, 45, 220))
        draw.text((180, 625), "“ดินใต้ต้นทุเรียนตรงนี้นุ่มและหอมกลิ่นป่ามากเลย... ดินดีแบบนี้นี่เอง ทุเรียนถึงลูกดก!”", fill=(255, 255, 255), font=font_cinematic)

    # -------------------------------------------------------------
    # องก์ที่ 4 (0:36 - 0:48): การวิเคราะห์คุณภาพดินด้วยโฮโลแกรม 3D ไซไฟ
    # -------------------------------------------------------------
    elif sec < 48.0:
        local_t = (sec - 36.0) / 12.0
        # ลูกแก้วแคปซูลฉายโฮโลแกรมสว่างจ้าตรงกลาง
        holo_cx, holo_cy = 640, 330
        draw_scifi_soil_hologram(draw, holo_cx, holo_cy, frame_idx)
        
        # เด็กหญิงและเด็กชายยืนดูด้วยความตื่นตาตื่นใจ (Waving hands)
        draw_ghibli_child(draw, cx=320, cy=460, gender="girl", bounce=-bounce_child)
        draw_ghibli_child(draw, cx=960, cy=465, gender="boy", bounce=bounce_child)
        
        # แมวขาวกระโดดตะปบละอองโฮโลแกรม แมวส้มนั่งจ้องตาวาว
        draw_white_cat(draw, cx=440, cy=500 - int(15 * abs(math.sin(sec * 3))), walking=True, frame_idx=frame_idx)
        draw_orange_cat(draw, cx=840, cy=510, walking=False, frame_idx=frame_idx)
        
        # แผงอ่านผลการวิเคราะห์ดิน 3D Hologram HUD
        hud_x, hud_y = 460, 110
        draw.rounded_rectangle([(hud_x, hud_y), (hud_x + 360, hud_y + 115)], radius=15, fill=(10, 30, 50, 220), outline=(0, 240, 200), width=2)
        draw.text((hud_x + 20, hud_y + 15), "✦ ผลวิเคราะห์คุณภาพดินใต้ต้นทุเรียน ✦", fill=(0, 255, 200), font=font_hologram)
        draw.text((hud_x + 20, hud_y + 45), f"• ความชื้นในดิน: 68.2% [ชุ่มฉ่ำพอดี]", fill=(255, 255, 255), font=font_sub)
        draw.text((hud_x + 20, hud_y + 75), f"• ค่ากรด-ด่าง pH: 6.35 [ระดับทองคำ]", fill=(255, 215, 0), font=font_sub)
        
        # ป้ายบรรยายภาพยนตร์
        draw.rounded_rectangle([(140, 610), (WIDTH - 140, 685)], radius=14, fill=(20, 35, 45, 220))
        draw.text((180, 625), "“ว้าววว! แร่ธาตุ NPK กับจุลินทรีย์ดินสมบูรณ์แบบมากเลย รากทุเรียนกำลังมีความสุขสุดๆ!”", fill=(255, 255, 255), font=font_cinematic)

    # -------------------------------------------------------------
    # องก์ที่ 5 (0:48 - 1:00): สวนทุเรียนและมังคุดแห่งอนาคตที่ยั่งยืน
    # -------------------------------------------------------------
    else:
        local_t = (sec - 48.0) / 12.0
        # แสงอาทิตย์อัสดงสีทองอบอุ่นสาดส่องทั่วทั้งสวน
        for y in range(0, 480):
            ratio = y / 480.0
            r = int(245 - 20 * ratio)
            g = int(180 + 30 * ratio)
            b = int(120 + 40 * ratio)
            draw.line([(0, y), (WIDTH, y)], fill=(r, g, b))
            
        # เด็กๆ นั่งกอดเจ้าเหมียวขาวและส้มใต้ร่มเงาไม้ใหญ่อย่างมีความสุข
        draw_ghibli_child(draw, cx=580, cy=475, gender="girl", bounce=0)
        draw_ghibli_child(draw, cx=700, cy=475, gender="boy", bounce=0)
        draw_white_cat(draw, cx=520, cy=525, walking=False, frame_idx=frame_idx)
        draw_orange_cat(draw, cx=760, cy=525, walking=False, frame_idx=frame_idx)
        
        # ผลทุเรียนและมังคุดบนต้นเปล่งประกายสีทองระยิบระยับ
        for sparkle in [(120, 190), (170, 220), (1110, 230), (1160, 250)]:
            draw.text((sparkle[0] + 15, sparkle[1] - 10), "✨", fill=(255, 235, 100), font=font_cinematic)
            
        # การ์ดข้อคิดและเครดิตปิดท้ายภาพยนตร์
        draw.rounded_rectangle([(200, 120), (WIDTH - 200, 260)], radius=20, fill=(255, 255, 255, 230), outline=(210, 160, 50), width=3)
        draw.text((240, 138), "“เมื่อหัวใจรักธรรมชาติ ผสานกับปัญญาประดิษฐ์และวิทยาศาสตร์...”", fill=(65, 45, 25), font=font_cinematic)
        draw.text((240, 185), "สวนทุเรียนและผลไม้ไทยจะเติบโตอย่างงดงามและยั่งยืนตลอดไป 🍃", fill=(45, 100, 40), font=font_title)
        
        draw.text((320, 645), "ดิจิทัลฟิสิกส์เกษตร & AI • ผศ.ดร.ชีวะ ทัศนา (มหาวิทยาลัยราชภัฏรำไพพรรณี)", fill=(255, 255, 255), font=font_sub)
        
        # ค่อยๆ เฟดลงสู่ความมืดใน 2 วินาทีสุดท้าย
        if sec > 58.0:
            dark = int(255 * ((sec - 58.0) / 2.0))
            overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, dark))
            img.paste(overlay, (0, 0), overlay)

    return img

def main():
    print(f"\n🎬 เริ่มต้นสร้างแอนิเมชัน 3D Ghibli Sci-Fi ({TOTAL_SECONDS} วินาที @ {FPS} fps = {TOTAL_FRAMES} เฟรม)...")
    start_time = time.time()
    
    # 1. สังเคราะห์บทเพลงสไตล์ Joe Hisaishi (Piano & Strings)
    audio_wav = generate_ghibli_soundtrack(duration_sec=TOTAL_SECONDS, sample_rate=44100)
    
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
        frame_img = render_ghibli_frame(f, TOTAL_FRAMES)
        proc.stdin.write(frame_img.tobytes())
        if f % 300 == 0:
            elapsed = time.time() - start_time
            fps_speed = (f + 1) / (elapsed + 1e-6)
            pct = (f / TOTAL_FRAMES) * 100
            print(f"   🌿 เรนเดอร์ 3D Ghibli: {f}/{TOTAL_FRAMES} เฟรม ({pct:.1f}%) | ความเร็ว: {fps_speed:.1f} fps")
            
    proc.stdin.close()
    proc.wait()
    
    total_elapsed = time.time() - start_time
    print(f"\n🎉 สำเร็จสมบูรณ์! แอนิเมชัน 3D Ghibli Sci-Fi ความยาว 1 นาที (60.0 วินาที) ถูกเรนเดอร์เสร็จในเวลา {total_elapsed:.1f} วินาที!")
    print(f"📁 บันทึกไฟล์ที่: {FINAL_VIDEO_PATH}")

if __name__ == "__main__":
    main()
