#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
60-Second Full Documentary Video Generator
Smart Soil AI & Precision Agriculture in Durian Orchards
=============================================================================
สร้างวิดีโอนำเสนอความยาว 1 นาที (60 วินาที) ความละเอียด HD 720p 30fps
พร้อมผสานคลิป AI Video Diffusion, แดชบอร์ด Telemetry และเสียงดนตรีประกอบ
=============================================================================
"""

import os
import sys
import math
import time
import subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import imageio.v3 as iio

OUTPUT_DIR = Path(__file__).resolve().parent / "output_videos"
PROJECT_DIR = OUTPUT_DIR / "projects" / "02_smart_soil_ai_telemetry_1min"
(PROJECT_DIR / "audio").mkdir(parents=True, exist_ok=True)
(PROJECT_DIR / "thumbnails").mkdir(parents=True, exist_ok=True)
FINAL_VIDEO_PATH = PROJECT_DIR / "video.mp4"
AUDIO_WAV_PATH = PROJECT_DIR / "audio" / "ambient_soundtrack_1min.wav"

WIDTH = 1280
HEIGHT = 720
FPS = 30
TOTAL_SECONDS = 60
TOTAL_FRAMES = TOTAL_SECONDS * FPS # 1800 frames

# โหลดคลิป AI Diffusion ที่สร้างไว้ใน Project 01
AI_DIFFUSION_VIDEO = OUTPUT_DIR / "projects" / "01_soil_water_drop_diffusion" / "video.mp4"
ai_frames = None
if AI_DIFFUSION_VIDEO.exists():
    try:
        ai_frames = iio.imread(str(AI_DIFFUSION_VIDEO))
        print(f"✅ โหลดคลิป AI Diffusion สำเร็จ: {ai_frames.shape}")
    except Exception as e:
        print(f"⚠️ ไม่สามารถโหลดคลิป AI ได้: {e}")

def create_ambient_soundtrack(duration_sec=60, sample_rate=44100):
    """สังเคราะห์ดนตรีบรรเลงแบบ Cinematic Ambient Pad ความยาว 60 วินาที"""
    t = np.linspace(0, duration_sec, int(sample_rate * duration_sec), endpoint=False)
    
    # คอร์ดเปียโน/ซินธ์ Ambient: Am9 -> Fmaj7 -> Cmaj9 -> G -> Dm9 -> F -> Am
    chord_times = [0, 9, 18, 27, 36, 45, 54, 60]
    chord_freqs = [
        [220.0, 261.63, 329.63, 392.0, 493.88], # Am9 (A, C, E, G, B)
        [174.61, 220.0, 261.63, 329.63],       # Fmaj7 (F, A, C, E)
        [130.81, 164.81, 196.0, 246.94, 293.66],# Cmaj9 (C, E, G, B, D)
        [196.0, 246.94, 293.66, 392.0],        # G (G, B, D, G)
        [146.83, 174.61, 220.0, 261.63, 329.63],# Dm9 (D, F, A, C, E)
        [174.61, 220.0, 261.63, 349.23],       # F (F, A, C, F)
        [220.0, 261.63, 329.63, 440.0],        # Am (A, C, E, A)
    ]
    
    audio = np.zeros_like(t)
    
    for i in range(len(chord_freqs)):
        t_start = chord_times[i]
        t_end = chord_times[i+1]
        mask = (t >= t_start) & (t < t_end)
        t_segment = t[mask] - t_start
        seg_dur = t_end - t_start
        
        # Envelope การเฟดเสียง
        envelope = np.sin(np.pi * (t_segment / seg_dur)) ** 0.5
        
        chord_wave = np.zeros_like(t_segment)
        for f in chord_freqs[i]:
            # ผสมเสียง Sine + Overtones อุ่นๆ
            chord_wave += 0.5 * np.sin(2 * np.pi * f * t_segment)
            chord_wave += 0.25 * np.sin(2 * np.pi * (f * 2) * t_segment)
            chord_wave += 0.1 * np.sin(2 * np.pi * (f * 3) * t_segment)
            # เสียงสั่นไหวเบาๆ (LFO vibrato)
            lfo = 1.0 + 0.02 * np.sin(2 * np.pi * 0.5 * t_segment)
            chord_wave *= lfo
            
        audio[mask] += chord_wave * envelope
        
    # เพิ่มเสียงเบส Sub-bass นุ่มนวลตลอด 60 วินาที
    sub_bass = 0.3 * np.sin(2 * np.pi * 55.0 * t) + 0.2 * np.sin(2 * np.pi * 82.4 * t)
    audio += sub_bass
    
    # เพิ่มเสียงสายลมเบาๆ (Atmospheric pink noise)
    noise = np.random.normal(0, 0.015, len(t))
    audio += noise
    
    # Normalization & Fade out ใน 3 วินาทีสุดท้าย
    audio = audio / np.max(np.abs(audio) + 1e-6) * 0.85
    fade_out_samples = int(sample_rate * 3.0)
    fade_curve = np.linspace(1.0, 0.0, fade_out_samples)
    audio[-fade_out_samples:] *= fade_curve
    
    # แปลงเป็น 16-bit PCM WAV
    audio_int16 = (audio * 32767).astype(np.int16)
    wav_path = str(AUDIO_WAV_PATH)
    import wave
    with wave.open(wav_path, "wb") as wf:
        wf.setnchannels(1) # Mono/Stereo
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(audio_int16.tobytes())
        
    print(f"🎵 สังเคราะห์เสียงดนตรีประกอบความยาว 60 วินาทีสำเร็จ: {wav_path}")
    return wav_path

def draw_hud_bracket(draw, x1, y1, x2, y2, color, length=20, width=2):
    """วาดขอบมุมสไตล์ Futuristic Cyberpunk / Precision HUD"""
    # Top-left
    draw.line([(x1, y1), (x1 + length, y1)], fill=color, width=width)
    draw.line([(x1, y1), (x1, y1 + length)], fill=color, width=width)
    # Top-right
    draw.line([(x2, y1), (x2 - length, y1)], fill=color, width=width)
    draw.line([(x2, y1), (x2, y1 + length)], fill=color, width=width)
    # Bottom-left
    draw.line([(x1, y2), (x1 + length, y2)], fill=color, width=width)
    draw.line([(x1, y2), (x1, y2 - length)], fill=color, width=width)
    # Bottom-right
    draw.line([(x2, y2), (x2 - length, y2)], fill=color, width=width)
    draw.line([(x2, y2), (x2, y2 - length)], fill=color, width=width)

def render_scene(frame_idx, total_frames=1800):
    """เรนเดอร์ภาพเฟรมเดี่ยวสำหรับวิดีโอ 1 นาที"""
    sec = frame_idx / FPS
    img = Image.new("RGB", (WIDTH, HEIGHT), (10, 15, 20))
    draw = ImageDraw.Draw(img)
    
    # แถบ Header แสดงเวลาและ Telemetry ตลอดเรื่อง
    draw.rectangle([(0, 0), (WIDTH, 50)], fill=(15, 22, 30))
    draw.line([(0, 50), (WIDTH, 50)], fill=(0, 200, 180), width=1)
    
    timestamp_str = f"TIME CODE: {int(sec // 60):02d}:{int(sec % 60):02d}:{int((sec % 1) * 30):02d} | FRAME: {frame_idx:04d}/{total_frames}"
    draw.text((30, 18), "SMART SOIL AI • RESEARCH & FIELD TELEMETRY", fill=(0, 240, 200))
    draw.text((WIDTH - 420, 18), timestamp_str, fill=(160, 180, 200))
    
    # แถบความคืบหน้าด้านล่าง (Timeline Bar)
    progress_w = int((frame_idx / total_frames) * WIDTH)
    draw.rectangle([(0, HEIGHT - 8), (WIDTH, HEIGHT)], fill=(20, 30, 40))
    draw.rectangle([(0, HEIGHT - 8), (progress_w, HEIGHT)], fill=(0, 230, 150))
    
    # -------------------------------------------------------------
    # ฉากที่ 1 (0:00 - 0:10): Intro & สวนทุเรียนยามเช้า (Morning Orchard Drone)
    # -------------------------------------------------------------
    if sec < 10.0:
        local_t = sec / 10.0
        # Background: ไล่เฉดท้องฟ้าสีทองและสวนผลไม้
        for y in range(50, HEIGHT - 8):
            ratio = (y - 50) / (HEIGHT - 58)
            r = int(18 + 50 * (1 - ratio) + 10 * math.sin(local_t * math.pi))
            g = int(25 + 70 * (1 - ratio) + 30 * ratio)
            b = int(35 + 40 * ratio)
            draw.line([(0, y), (WIDTH, y)], fill=(r, g, b))
            
        # แสงแดดสีทองพุ่งลงมา (Volumetric rays)
        sun_x = int(WIDTH * 0.75 + 30 * math.sin(local_t * 2))
        for r_len in range(100, 350, 40):
            draw.arc([sun_x - r_len, 80 - r_len, sun_x + r_len, 80 + r_len], 30, 120, fill=(255, 230, 140), width=2)
            
        # HUD Card กลางจอ
        card_w, card_h = 780, 280
        cx, cy = (WIDTH - card_w) // 2, (HEIGHT - card_h) // 2
        draw.rectangle([(cx, cy), (cx + card_w, cy + card_h)], fill=(12, 20, 28))
        draw_hud_bracket(draw, cx, cy, cx + card_w, cy + card_h, (0, 240, 200), length=30, width=3)
        
        draw.text((cx + 50, cy + 40), "SCENE 01: DURIAN ORCHARD AERIAL SURVEY", fill=(0, 220, 255))
        draw.text((cx + 50, cy + 85), "SMART SOIL AI PLATFORM", fill=(255, 255, 255))
        draw.text((cx + 50, cy + 140), "Deep Agri-Physics Research & Autonomous Soil Monitoring", fill=(180, 200, 220))
        draw.text((cx + 50, cy + 185), "Chanthaburi Durian Research Hub • RBRU Agri-Physics Lab", fill=(0, 240, 160))
        
        # Animated scanline
        scan_y = cy + int((frame_idx % 90) / 90 * card_h)
        draw.line([(cx + 10, scan_y), (cx + card_w - 10, scan_y)], fill=(0, 240, 200), width=1)

    # -------------------------------------------------------------
    # ฉากที่ 2 (0:10 - 0:20): AI Video Diffusion - การซึมซับของน้ำในดิน
    # -------------------------------------------------------------
    elif sec < 20.0:
        local_t = (sec - 10.0) / 10.0
        draw.rectangle([(0, 50), (WIDTH, HEIGHT - 8)], fill=(15, 18, 22))
        
        # ใส่คลิป AI Video Diffusion ที่สร้างไว้ตรงกลางจอ
        if ai_frames is not None:
            # เล่นลูปคลิป 16 เฟรม แบบสโลว์โมชัน
            ai_idx = int((frame_idx - 300) / 3) % len(ai_frames)
            ai_pil = Image.fromarray(ai_frames[ai_idx])
            ai_pil_scaled = ai_pil.resize((480, 480), Image.Resampling.BILINEAR)
            img.paste(ai_pil_scaled, (80, 120))
            draw_hud_bracket(draw, 75, 115, 80 + 485, 120 + 485, (0, 255, 200), length=25, width=2)
            
        # แผง Telemetry ทางขวา
        rx = 620
        draw.rectangle([(rx, 120), (WIDTH - 80, 600)], fill=(20, 28, 36))
        draw_hud_bracket(draw, rx, 120, WIDTH - 80, 600, (0, 200, 255), length=25, width=2)
        
        draw.text((rx + 40, 150), "SCENE 02: SOIL WATER ABSORPTION DYNAMICS", fill=(0, 240, 200))
        draw.text((rx + 40, 195), "AI Generative Diffusion (ali-vilab T2V)", fill=(255, 255, 255))
        draw.text((rx + 40, 245), "• Soil Type: Tropical Loam Soil (Chanthaburi)", fill=(190, 210, 230))
        draw.text((rx + 40, 285), f"• Surface Tension: 72.8 mN/m", fill=(190, 210, 230))
        draw.text((rx + 40, 325), f"• Infiltration Velocity: {14.2 + 0.5 * math.sin(local_t * 6):.2f} mm/hr", fill=(0, 240, 160))
        draw.text((rx + 40, 365), f"• Soil Porosity: 46.8% (Healthy Aeration)", fill=(190, 210, 230))
        
        # Dynamic micro-graph
        draw.text((rx + 40, 420), "Live Infiltration Flow Graph:", fill=(255, 220, 120))
        for gx in range(480):
            gy = int(520 - 30 * math.exp(-gx / 150) * math.sin(gx * 0.08 + local_t * 10))
            draw.point((rx + 40 + gx, gy), fill=(0, 240, 200))

    # -------------------------------------------------------------
    # ฉากที่ 3 (0:20 - 0:30): IoT Smart Soil Probe Telemetry
    # -------------------------------------------------------------
    elif sec < 30.0:
        local_t = (sec - 20.0) / 10.0
        draw.rectangle([(0, 50), (WIDTH, HEIGHT - 8)], fill=(12, 16, 24))
        
        # หัวข้อฉาก
        draw.text((80, 80), "SCENE 03: MULTI-DEPTH SOIL SENSOR TELEMETRY", fill=(0, 240, 200))
        draw.text((80, 115), "Real-time NPK, pH & Moisture Sensor Fusion", fill=(255, 255, 255))
        
        # ชุดแถบกราฟ Telemetry 5 ช่อง
        sensors = [
            ("Soil Moisture (ความชื้น)", f"{68.4 + 0.3 * math.sin(local_t * 8):.1f} %", 68.4 / 100, (0, 230, 160)),
            ("Nitrogen (N - ไนโตรเจน)", f"{142.5 + 1.2 * math.sin(local_t * 5):.1f} mg/kg", 142.5 / 200, (0, 200, 255)),
            ("Phosphorus (P - ฟอสฟอรัส)", f"{48.2 + 0.8 * math.cos(local_t * 6):.1f} mg/kg", 48.2 / 100, (255, 210, 80)),
            ("Potassium (K - โพแทสเซียม)", f"{185.0 + 1.5 * math.sin(local_t * 4):.1f} mg/kg", 185.0 / 250, (255, 120, 160)),
            ("Soil pH (ความเป็นกรด-ด่าง)", f"{6.48 + 0.02 * math.sin(local_t * 7):.2f}", (6.48 - 4) / 6, (180, 140, 255)),
        ]
        
        for i, (name, val_str, ratio, bar_col) in enumerate(sensors):
            sy = 170 + i * 85
            draw.rectangle([(80, sy), (WIDTH - 80, sy + 70)], fill=(20, 28, 38))
            draw.text((100, sy + 15), name, fill=(220, 230, 240))
            draw.text((WIDTH - 280, sy + 15), val_str, fill=bar_col)
            
            # หลอดค่าพลังงาน
            bar_w = int((WIDTH - 380) * ratio)
            draw.rectangle([(100, sy + 45), (100 + (WIDTH - 380), sy + 55)], fill=(40, 50, 65))
            draw.rectangle([(100, sy + 45), (100 + bar_w, sy + 55)], fill=bar_col)

    # -------------------------------------------------------------
    # ฉากที่ 4 (0:30 - 0:40): AI Deep Learning Calibration Engine
    # -------------------------------------------------------------
    elif sec < 40.0:
        local_t = (sec - 30.0) / 10.0
        draw.rectangle([(0, 50), (WIDTH, HEIGHT - 8)], fill=(16, 20, 28))
        
        draw.text((80, 80), "SCENE 04: EDGE DEEP LEARNING CALIBRATOR", fill=(0, 240, 200))
        draw.text((80, 115), "Neural Network Calibration for Environmental Drift & Temperature Compensation", fill=(255, 255, 255))
        
        # วาดโมเดลโครงข่ายประสาท (Neural Network Visualization)
        layers = [4, 6, 6, 3]
        layer_x = [150, 300, 450, 600]
        node_positions = []
        for l_idx, num_nodes in enumerate(layers):
            nx = layer_x[l_idx]
            l_nodes = []
            for n in range(num_nodes):
                ny = int(220 + (n - (num_nodes - 1) / 2) * 60)
                l_nodes.append((nx, ny))
            node_positions.append(l_nodes)
            
        # วาดเส้น Synaptic Weights
        for l in range(len(node_positions) - 1):
            for n1 in node_positions[l]:
                for n2 in node_positions[l+1]:
                    pulse = math.sin(local_t * 12 + n1[1] * 0.05)
                    alpha_val = int(80 + 120 * (pulse > 0))
                    draw.line([n1, n2], fill=(0, alpha_val, int(alpha_val * 0.8)), width=1)
                    
        # วาดโหนด
        for layer in node_positions:
            for nx, ny in layer:
                draw.ellipse([(nx - 12, ny - 12), (nx + 12, ny + 12)], fill=(0, 240, 200), outline=(255, 255, 255))
                
        # ข้อมูล AI Metrics ด้านขวา
        rx = 700
        draw.rectangle([(rx, 180), (WIDTH - 80, 580)], fill=(22, 30, 42))
        draw_hud_bracket(draw, rx, 180, WIDTH - 80, 580, (0, 230, 160), length=25, width=2)
        
        draw.text((rx + 30, 210), "EDGE AI CALIBRATION METRICS", fill=(0, 240, 200))
        draw.text((rx + 30, 260), f"• Epoch: {int(500 * min(1.0, local_t * 1.5))}/500", fill=(255, 255, 255))
        loss = 0.045 * math.exp(-local_t * 4) + 0.0012
        draw.text((rx + 30, 305), f"• Mean Squared Error: {loss:.5f}", fill=(0, 240, 160))
        draw.text((rx + 30, 350), f"• R² Determination: 0.9942", fill=(255, 210, 80))
        draw.text((rx + 30, 395), "• Latency: 4.8 ms (Local CoreML/MPS)", fill=(0, 220, 255))
        draw.text((rx + 30, 440), "• Quantization: INT8 Precision", fill=(190, 210, 230))
        draw.text((rx + 30, 490), "STATUS: AI CALIBRATION COMPLETE ✔", fill=(0, 255, 150))

    # -------------------------------------------------------------
    # ฉากที่ 5 (0:40 - 0:50): Precision Irrigation & Farm Automation
    # -------------------------------------------------------------
    elif sec < 50.0:
        local_t = (sec - 40.0) / 10.0
        draw.rectangle([(0, 50), (WIDTH, HEIGHT - 8)], fill=(14, 18, 26))
        
        draw.text((80, 80), "SCENE 05: CLOSED-LOOP AUTONOMOUS IRRIGATION", fill=(0, 240, 200))
        draw.text((80, 115), "Dynamic Moisture Zoning & Water Conservation Management", fill=(255, 255, 255))
        
        # แผนผังแปลงเกษตรอัจฉริยะ (Grid Map)
        for gx in range(5):
            for gy in range(4):
                px = 120 + gx * 105
                py = 180 + gy * 95
                zone_val = math.sin(gx * 0.7 + gy * 0.5 + local_t * 3)
                col = (0, int(150 + 80 * zone_val), int(180 + 60 * zone_val))
                draw.rectangle([(px, py), (px + 90, py + 80)], fill=col, outline=(30, 45, 60))
                draw.text((px + 10, py + 10), f"Z{gx+1}{gy+1}", fill=(255, 255, 255))
                draw.text((px + 10, py + 40), f"{65 + int(8 * zone_val)}%", fill=(255, 230, 150))
                
        # กล่องคำสั่งควบคุมวาล์วทางขวา
        rx = 700
        draw.rectangle([(rx, 180), (WIDTH - 80, 560)], fill=(20, 28, 40))
        draw_hud_bracket(draw, rx, 180, WIDTH - 80, 560, (0, 240, 200), length=25, width=2)
        
        draw.text((rx + 30, 210), "AUTOMATED ACTUATION LOG:", fill=(0, 240, 200))
        draw.text((rx + 30, 265), "• Valve A-1 (Plot North): CLOSED", fill=(180, 190, 200))
        draw.text((rx + 30, 315), "• Valve B-2 (Plot Center): OPEN (45%)", fill=(0, 240, 160))
        draw.text((rx + 30, 365), "• Flow Rate: 12.4 Liters / Minute", fill=(255, 210, 80))
        draw.text((rx + 30, 415), "• Expected Soil Equilibrium: 18 Mins", fill=(0, 220, 255))
        draw.text((rx + 30, 475), "ENERGY SAVINGS: 34.2% REDUCTION", fill=(0, 255, 180))

    # -------------------------------------------------------------
    # ฉากที่ 6 (0:50 - 1:00): Conclusion & Final Credits
    # -------------------------------------------------------------
    else:
        local_t = (sec - 50.0) / 10.0
        fade_alpha = max(0.0, 1.0 - (sec - 56.0) / 4.0) if sec > 56.0 else 1.0
        
        draw.rectangle([(0, 50), (WIDTH, HEIGHT - 8)], fill=(10, 14, 20))
        
        cx, cy = WIDTH // 2, HEIGHT // 2
        card_w, card_h = 860, 340
        x1, y1 = cx - card_w // 2, cy - card_h // 2
        draw.rectangle([(x1, y1), (x1 + card_w, y1 + card_h)], fill=(16, 24, 34))
        draw_hud_bracket(draw, x1, y1, x1 + card_w, y1 + card_h, (0, 240, 200), length=35, width=3)
        
        draw.text((x1 + 60, y1 + 50), "SUSTAINABLE PRECISION AGRICULTURE", fill=(0, 240, 200))
        draw.text((x1 + 60, y1 + 105), "EMPOWERING THAI SMART FARMERS WITH EDGE AI", fill=(255, 255, 255))
        draw.text((x1 + 60, y1 + 165), "Project: Digital Agri-Physics & IoT Soil Telemetry", fill=(190, 210, 230))
        draw.text((x1 + 60, y1 + 210), "Chief Investigator: ผศ.ดร.ชีวะ ทัศนา และคณะวิจัย", fill=(255, 220, 120))
        draw.text((x1 + 60, y1 + 255), "Rambhai Barni Rajabhat University (RBRU) • Chanthaburi", fill=(0, 240, 160))
        
        # ค่อยๆ เฟดลงสู่ความมืดใน 2 วินาทีสุดท้าย
        if sec > 58.0:
            dark_alpha = int(255 * ((sec - 58.0) / 2.0))
            overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, dark_alpha))
            img.paste(overlay, (0, 0), overlay)

    return img

def main():
    print(f"\n🎬 เริ่มต้นเรนเดอร์วิดีโอ 1 นาที ({TOTAL_SECONDS} วินาที @ {FPS} fps = {TOTAL_FRAMES} เฟรม)...")
    start_time = time.time()
    
    # 1. สังเคราะห์เสียงดนตรีประกอบ Ambient ความยาว 60 วินาที
    audio_wav = create_ambient_soundtrack(duration_sec=TOTAL_SECONDS, sample_rate=44100)
    
    # 2. เรนเดอร์เฟรมและส่งผ่าน FFmpeg Pipe สดๆ (Zero-disk footprint)
    ffmpeg_cmd = [
        "/opt/homebrew/bin/ffmpeg",
        "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{WIDTH}x{HEIGHT}",
        "-pix_fmt", "rgb24",
        "-r", str(FPS),
        "-i", "-", # รับภาพจาก stdin
        "-i", audio_wav, # รับเสียงดนตรี
        "-c:v", "libx264",
        "-preset", "veryfast",
        "-crf", "18",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "192k",
        "-t", "60",
        str(FINAL_VIDEO_PATH)
    ]
    
    print(f"⚡ เริ่มต้นไปป์ไลน์ FFmpeg H.264 + AAC...")
    proc = subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE)
    
    for f in range(TOTAL_FRAMES):
        frame_img = render_scene(f, TOTAL_FRAMES)
        proc.stdin.write(frame_img.tobytes())
        if f % 180 == 0:
            elapsed = time.time() - start_time
            fps_speed = (f + 1) / (elapsed + 1e-6)
            pct = (f / TOTAL_FRAMES) * 100
            print(f"   🎞️ ความคืบหน้า: {f}/{TOTAL_FRAMES} เฟรม ({pct:.1f}%) | ความเร็ว: {fps_speed:.1f} fps | ใช้เวลา: {elapsed:.1f}s")
            
    proc.stdin.close()
    proc.wait()
    
    total_elapsed = time.time() - start_time
    print(f"\n🎉 สำเร็จสมบูรณ์! วิดีโอความยาว 1 นาที (60.0 วินาที) ถูกเรนเดอร์เสร็จในเวลา {total_elapsed:.1f} วินาที!")
    print(f"📁 บันทึกที่: {FINAL_VIDEO_PATH}")

if __name__ == "__main__":
    main()
