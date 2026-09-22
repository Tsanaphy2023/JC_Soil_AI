#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate 10 Strictly Forward-Flowing Neural Motion Clips for Project 10
Using Stable Video Diffusion with Autoregressive Forward Chaining (Part 1 -> Part 2)
100% Forward Vector Kinematics - Zero Reverse Playback
"""
import os
import time
from pathlib import Path
from PIL import Image
import torch
from diffusers import StableVideoDiffusionPipeline
from diffusers.utils import export_to_video

PROJECT_DIR = Path("/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/projects/10_forward_flowing_cinematic_thai_farmers_1min")
SOURCE_DIR = Path("/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/projects/08_ultra_realistic_thai_farmers_rice_documentary_1min/source_photos")
RAW_DIR = PROJECT_DIR / "raw_svd_clips"
RAW_DIR.mkdir(parents=True, exist_ok=True)

# 5 Master Scenes with Part 1 & Part 2 chaining
SCENE_CONFIGS = [
    {
        "id": 1,
        "name_prefix": "scene1_dawn_terrace",
        "source_img": SOURCE_DIR / "scene1.jpg",
        "motion1": 135,
        "motion2": 125,
        "title1": "หมอกลอยเหนือน้ำรุ่งอรุณ",
        "title2": "ก้าวเดินลุยคันนาสู่แปลงปลูก"
    },
    {
        "id": 2,
        "name_prefix": "scene2_seedling_bundle",
        "source_img": SOURCE_DIR / "scene2.jpg",
        "motion1": 125,
        "motion2": 130,
        "title1": "คัดแยกมัดกล้าข้าวมรกต",
        "title2": "สะบัดหยดน้ำค้างรับประกายแดด"
    },
    {
        "id": 3,
        "name_prefix": "scene3_farmers_planting",
        "source_img": SOURCE_DIR / "scene3.jpg",
        "motion1": 140,
        "motion2": 135,
        "title1": "ก้าวเดินสู่แปลงนาขังน้ำ",
        "title2": "ก้มตัวลงปักดำอย่างพร้อมเพรียง"
    },
    {
        "id": 4,
        "name_prefix": "scene4_macro_mud_water",
        "source_img": SOURCE_DIR / "scene4.jpg",
        "motion1": 145,
        "motion2": 130,
        "title1": "สองมือกดรากกล้าลงดินเลน",
        "title2": "ระลอกคลื่นน้ำแผ่ขยายเป็นวง"
    },
    {
        "id": 5,
        "name_prefix": "scene5_golden_heritage",
        "source_img": SOURCE_DIR / "scene5.jpg",
        "motion1": 130,
        "motion2": 120,
        "title1": "สายลมพัดระลอกยอดข้าวเขียวขจี",
        "title2": "รอยยิ้มเปี่ยมสุขแห่งกระดูกสันหลังของชาติ"
    }
]

def main():
    print("\n=======================================================")
    print("🚀 SVD Forward-Flowing Neural Motion Engine (Project 10)")
    print("=======================================================")
    
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"🖥️ Using compute device: {device}")
    
    pipe = StableVideoDiffusionPipeline.from_pretrained(
        "stabilityai/stable-video-diffusion-img2vid-xt",
        torch_dtype=torch.float16,
        variant="fp16"
    )
    pipe.to(device)
    if hasattr(pipe, "enable_attention_slicing"):
        pipe.enable_attention_slicing()
        
    num_frames = 22
    steps = 12
    width = 768
    height = 432
    
    for sc in SCENE_CONFIGS:
        sc_id = sc["id"]
        p1_file = RAW_DIR / f"clip_{sc_id:02d}a_{sc['name_prefix']}_p1.mp4"
        p2_file = RAW_DIR / f"clip_{sc_id:02d}b_{sc['name_prefix']}_p2.mp4"
        
        last_frame_img = None
        
        # --- Part 1 ---
        if p1_file.exists():
            print(f"⏩ [Scene {sc_id} Part 1] มีไฟล์อยู่แล้ว ข้าม: {p1_file.name}")
            # Load last frame from p1 to continue if needed
            # We can extract last frame using ffmpeg
            tmp_last = PROJECT_DIR / f"tmp_last_{sc_id}.png"
            os.system(f"ffmpeg -y -sseof -1 -i '{p1_file}' -frames:v 1 '{tmp_last}' 2>/dev/null")
            if tmp_last.exists():
                last_frame_img = Image.open(tmp_last).convert("RGB")
        else:
            print(f"\n🎬 [Scene {sc_id} Part 1] สร้างการเคลื่อนไหวไปข้างหน้า: {sc['title1']}")
            img1 = Image.open(sc["source_img"]).convert("RGB").resize((width, height))
            t0 = time.time()
            gen1 = torch.manual_seed(200 + sc_id * 10 + 1)
            frames1 = pipe(
                img1,
                decode_chunk_size=2,
                generator=gen1,
                motion_bucket_id=sc["motion1"],
                noise_aug_strength=0.02,
                num_frames=num_frames,
                num_inference_steps=steps,
                height=height,
                width=width
            ).frames[0]
            
            export_to_video(frames1, str(p1_file), fps=5)
            last_frame_img = frames1[-1]
            print(f"   ✅ Part 1 เสร็จใน {time.time() - t0:.1f}s -> {p1_file.name}")
            
        # --- Part 2 (Chained from Part 1) ---
        if p2_file.exists():
            print(f"⏩ [Scene {sc_id} Part 2] มีไฟล์อยู่แล้ว ข้าม: {p2_file.name}")
        else:
            print(f"\n🎬 [Scene {sc_id} Part 2] Chained Forward Motion: {sc['title2']}")
            if last_frame_img is None:
                tmp_last = PROJECT_DIR / f"tmp_last_{sc_id}.png"
                os.system(f"ffmpeg -y -sseof -1 -i '{p1_file}' -frames:v 1 '{tmp_last}' 2>/dev/null")
                last_frame_img = Image.open(tmp_last).convert("RGB").resize((width, height))
            else:
                last_frame_img = last_frame_img.resize((width, height))
                
            t0 = time.time()
            gen2 = torch.manual_seed(200 + sc_id * 10 + 2)
            frames2 = pipe(
                last_frame_img,
                decode_chunk_size=2,
                generator=gen2,
                motion_bucket_id=sc["motion2"],
                noise_aug_strength=0.02,
                num_frames=num_frames,
                num_inference_steps=steps,
                height=height,
                width=width
            ).frames[0]
            
            export_to_video(frames2, str(p2_file), fps=5)
            print(f"   ✅ Part 2 เสร็จใน {time.time() - t0:.1f}s -> {p2_file.name}")

    print("\n🎉 สร้างคลิปการเคลื่อนไหวไปข้างหน้าต่อเนื่องครบทั้ง 10 ช็อตเรียบร้อยแล้ว!")

if __name__ == "__main__":
    main()
