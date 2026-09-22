#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate SVD Neural Video Motion for Rice Farming Scenes (768x432 16:9 Widescreen)
"""
import time
from pathlib import Path
from PIL import Image
import torch
from diffusers import StableVideoDiffusionPipeline
from diffusers.utils import export_to_video

PROJECT_DIR = Path("/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/projects/09_cinematic_neural_motion_thai_farmers_1min")
SOURCE_DIR = Path("/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/projects/08_ultra_realistic_thai_farmers_rice_documentary_1min/source_photos")
RAW_DIR = PROJECT_DIR / "raw_svd_clips"
RAW_DIR.mkdir(parents=True, exist_ok=True)

SCENES = [
    {"name": "svd_scene1.mp4", "img": SOURCE_DIR / "scene1.jpg", "motion": 135},
    {"name": "svd_scene2.mp4", "img": SOURCE_DIR / "scene2.jpg", "motion": 125},
    {"name": "svd_scene3.mp4", "img": SOURCE_DIR / "scene3.jpg", "motion": 140},
    {"name": "svd_scene4.mp4", "img": SOURCE_DIR / "scene4.jpg", "motion": 145},
    {"name": "svd_scene5.mp4", "img": SOURCE_DIR / "scene5.jpg", "motion": 130},
]

def main():
    missing = [s for s in SCENES if not (RAW_DIR / s["name"]).exists()]
    if not missing:
        print("✅ คลิป SVD ดิบครบถ้วนทั้ง 5 ฉากแล้ว!")
        return

    print(f"\n🚀 โหลดโมเดล Stable Video Diffusion (SVD-XT) บน Apple Silicon MPS...")
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    pipe = StableVideoDiffusionPipeline.from_pretrained(
        "stabilityai/stable-video-diffusion-img2vid-xt",
        torch_dtype=torch.float16,
        variant="fp16"
    )
    pipe.to(device)
    if hasattr(pipe, "enable_attention_slicing"):
        pipe.enable_attention_slicing()

    for idx, sc in enumerate(missing, 1):
        out_file = RAW_DIR / sc["name"]
        print(f"\n🎬 [{idx}/{len(missing)}] กำลังสร้างการเคลื่อนไหวจริง (Neural Motion): {sc['name']}")
        img = Image.open(sc["img"]).convert("RGB").resize((768, 432))
        
        t0 = time.time()
        generator = torch.manual_seed(42 + idx)
        frames = pipe(
            img,
            decode_chunk_size=2,
            generator=generator,
            motion_bucket_id=sc["motion"],
            noise_aug_strength=0.02,
            num_frames=16,
            num_inference_steps=15,
            height=432,
            width=768
        ).frames[0]
        
        export_to_video(frames, str(out_file), fps=8)
        print(f"   ✅ เรนเดอร์สำเร็จในเวลา {time.time() - t0:.1f} วินาที -> {sc['name']}")

if __name__ == "__main__":
    main()
