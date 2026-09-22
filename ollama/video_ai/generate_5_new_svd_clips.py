#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate 5 New Pristine SVD Clips for Project 10
From High-Resolution Master Photos (Buffalo, Droplets Splash, Line Walking, Macro Ripples, Wind Rows)
"""
import time
from pathlib import Path
from PIL import Image
import torch
from diffusers import StableVideoDiffusionPipeline
from diffusers.utils import export_to_video

PROJECT_DIR = Path("/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/projects/10_forward_flowing_cinematic_thai_farmers_1min")
PHOTOS_DIR = PROJECT_DIR / "source_photos"
RAW_DIR = PROJECT_DIR / "raw_svd_clips"
RAW_DIR.mkdir(parents=True, exist_ok=True)

NEW_SCENES = [
    {
        "out": RAW_DIR / "clip_02_buffalo_ridge.mp4",
        "img": PHOTOS_DIR / "photo_02_buffalo_ridge.jpg",
        "motion": 125,
        "title": "ชาวนาและควายเดินลุยคันนา"
    },
    {
        "out": RAW_DIR / "clip_04_seedlings_splash.mp4",
        "img": PHOTOS_DIR / "photo_04_seedlings_splash.jpg",
        "motion": 135,
        "title": "สะบัดมัดกล้าละอองน้ำกระเซ็น"
    },
    {
        "out": RAW_DIR / "clip_05_farmers_line.mp4",
        "img": PHOTOS_DIR / "photo_05_farmers_line.jpg",
        "motion": 130,
        "title": "ขบวนชาวนาก้าวเดินในแปลงน้ำ"
    },
    {
        "out": RAW_DIR / "clip_08_ripples_macro.mp4",
        "img": PHOTOS_DIR / "photo_08_ripples_macro.jpg",
        "motion": 120,
        "title": "คลื่นน้ำแผ่ขยายยอดข้าวตั้งตรง"
    },
    {
        "out": RAW_DIR / "clip_09_rows_wind.mp4",
        "img": PHOTOS_DIR / "photo_09_rows_wind.jpg",
        "motion": 125,
        "title": "แถวต้นกล้าพลิ้วไหวตามสายลม"
    }
]

def main():
    missing = [sc for sc in NEW_SCENES if not sc["out"].exists()]
    if not missing:
        print("✅ คลิปใหม่ทั้ง 5 คลิปมีอยู่แล้ว!")
        return

    print(f"\n🚀 โหลดโมเดล SVD-XT เพื่อสร้างคลิปใหม่ {len(missing)} คลิป...")
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    pipe = StableVideoDiffusionPipeline.from_pretrained(
        "stabilityai/stable-video-diffusion-img2vid-xt",
        torch_dtype=torch.float16,
        variant="fp16"
    ).to(device)
    if hasattr(pipe, "enable_attention_slicing"):
        pipe.enable_attention_slicing()

    for idx, sc in enumerate(missing, 1):
        print(f"\n🎬 [{idx}/{len(missing)}] กำลังสร้างคลิปคมชัดสูง: {sc['title']} ({sc['out'].name})")
        img = Image.open(sc["img"]).convert("RGB").resize((768, 432))
        t0 = time.time()
        generator = torch.manual_seed(500 + idx)
        frames = pipe(
            img,
            decode_chunk_size=2,
            generator=generator,
            motion_bucket_id=sc["motion"],
            noise_aug_strength=0.015,
            num_frames=22,
            num_inference_steps=12,
            height=432,
            width=768
        ).frames[0]
        
        export_to_video(frames, str(sc["out"]), fps=5)
        print(f"   ✅ สำเร็จในเวลา {time.time() - t0:.1f} วินาที -> {sc['out'].name}")

    print("\n🎉 สร้างคลิป SVD คมชัดสูงชุดใหม่ครบถ้วน 100%!")

if __name__ == "__main__":
    main()
