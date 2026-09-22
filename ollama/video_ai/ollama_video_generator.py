#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
Ollama + Local Video Generation Pipeline (macOS Apple Silicon Metal MPS)
=============================================================================
บทบาท:
1. Ollama (LLM เช่น llama3.2 / deepseek-r1 / qwen2.5): ทำหน้าที่เป็น "AI Director"
   ช่วยแปลง Concept ภาษาไทย/อังกฤษสั้นๆ ให้กลายเป็นบทกำกับภาพยนตร์, รายละเอียด
   การเคลื่อนไหวของกล้อง (Camera Motion), และ Visual Prompt สำหรับ Video AI
2. Local Video Diffusion Engine: ทำหน้าที่ Render ไฟล์วิดีโอ .mp4 บนชิป Apple Silicon
   โดยไม่ต้องต่ออินเทอร์เน็ต และใช้งานได้ฟรี 100%
=============================================================================
"""

import os
import sys
import json
import time
import argparse
import re
from datetime import datetime
from pathlib import Path
from PIL import Image
import requests
import torch
import numpy as np

OLLAMA_API_URL = "http://127.0.0.1:11434/api/generate"
DEFAULT_T2V_MODEL = "ali-vilab/text-to-video-ms-1.7b"
DEFAULT_I2V_MODEL = "stabilityai/stable-video-diffusion-img2vid-xt"
DEFAULT_OLLAMA_MODEL = "video-director"
OUTPUT_DIR = Path(__file__).resolve().parent / "output_videos"
PROJECTS_DIR = OUTPUT_DIR / "projects"
PROJECTS_DIR.mkdir(parents=True, exist_ok=True)

def setup_project_folder(prompt: str = "", custom_output: str = None) -> tuple:
    """
    สร้างโฟลเดอร์โปรเจกต์ใหม่และจัดสรรโฟลเดอร์ย่อย (thumbnails, audio)
    คืนค่า: (project_dir, video_path)
    """
    if custom_output:
        custom_path = Path(custom_output).resolve()
        proj_dir = custom_path.parent
        proj_dir.mkdir(parents=True, exist_ok=True)
        (proj_dir / "thumbnails").mkdir(parents=True, exist_ok=True)
        (proj_dir / "audio").mkdir(parents=True, exist_ok=True)
        return proj_dir, str(custom_path)
        
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    # สกัดคำสำคัญเป็น slug โฟลเดอร์
    slug = re.sub(r'[^a-zA-Z0-9_]+', '_', prompt[:30].strip()).strip('_').lower()
    folder_name = f"{timestamp}_{slug}" if slug else f"video_{timestamp}"
    
    proj_dir = PROJECTS_DIR / folder_name
    proj_dir.mkdir(parents=True, exist_ok=True)
    (proj_dir / "thumbnails").mkdir(parents=True, exist_ok=True)
    (proj_dir / "audio").mkdir(parents=True, exist_ok=True)
    video_path = str(proj_dir / "video.mp4")
    return proj_dir, video_path

def get_device():
    """ตรวจสอบและเลือกอุปกรณ์ประมวลผลที่ดีที่สุด (Apple Silicon MPS หรือ CPU)"""
    if torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")

def query_ollama_director(user_idea: str, model_name: str = DEFAULT_OLLAMA_MODEL) -> dict:
    """
    ส่ง Prompt ของผู้ใช้ไปยัง Ollama เพื่อให้ทำหน้าที่เป็น AI Director
    ขยายเป็น Cinematic Video Prompt และ Camera Motion Description
    """
    print(f"\n🎬 [AI Director] กำลังปรึกษา Ollama ({model_name}) เพื่อออกแบบฉากและมุมกล้อง...")
    
    system_instruction = (
        "You are an award-winning cinematic AI film director and video prompt engineer. "
        "The user will provide a simple video concept. "
        "You must translate and expand it into a high-quality video generation prompt in English. "
        "Focus on: visual realism, exact camera motion (e.g. slow cinematic drone forward, orbital pan), "
        "lighting (golden hour, volumetric rays), and fluid natural movement. "
        "Return STRICT JSON with keys: "
        "'prompt' (string, max 45 words), "
        "'negative_prompt' (string of artifacts to avoid), "
        "'camera_movement' (string describing camera direction), "
        "'recommended_fps' (integer, 8 or 16), "
        "'director_note_th' (short explanation in Thai of your directorial choice)."
    )
    
    payload = {
        "model": model_name,
        "prompt": f"{system_instruction}\n\nUser Concept: {user_idea}",
        "format": "json",
        "stream": False,
        "options": {
            "temperature": 0.7
        }
    }
    
    try:
        res = requests.post(OLLAMA_API_URL, json=payload, timeout=60)
        res.raise_for_status()
        data = res.json()
        raw_resp = data.get("response", "{}").strip()
        
        # ถอด Markdown ```json ... ``` ถ้ามี
        if raw_resp.startswith("```"):
            raw_resp = raw_resp.split("```")[1]
            if raw_resp.startswith("json"):
                raw_resp = raw_resp[4:].strip()
                
        director_output = json.loads(raw_resp)
        return director_output
    except Exception as e:
        print(f"⚠️ ไม่สามารถเชื่อมต่อ Ollama ได้สมบูรณ์ ({e}) -> กำลังใช้โหมดพื้นฐาน")
        return {
            "prompt": user_idea,
            "negative_prompt": "blurry, low quality, jitter, flicker, distorted, watermark",
            "camera_movement": "Smooth steady forward pan",
            "recommended_fps": 8,
            "director_note_th": "ประมวลผลข้อความโดยตรงโดยไม่ผ่าน Ollama"
        }

def generate_text_to_video(prompt: str, negative_prompt: str = "", num_frames: int = 16, fps: int = 8, output_path: str = None, director_data: dict = None):
    """สร้างวิดีโอจากข้อความ (Text-to-Video) ด้วย Diffusers บน Apple Silicon MPS"""
    from diffusers import TextToVideoSDPipeline
    from diffusers.utils import export_to_video
    
    device = get_device()
    print(f"\n🚀 เริ่มต้นโหลดโมเดล Text-to-Video: {DEFAULT_T2V_MODEL}")
    print(f"⚡ อุปกรณ์ประมวลผล: {device} (Apple Silicon Metal MPS)")
    
    # โหลด Pipeline ด้วย float16 เพื่อประสิทธิภาพบน Metal GPU
    dtype = torch.float16 if device.type == "mps" else torch.float32
    pipe = TextToVideoSDPipeline.from_pretrained(
        DEFAULT_T2V_MODEL,
        torch_dtype=dtype,
        variant="fp16" if dtype == torch.float16 else None
    )
    pipe.to(device)
    
    # เปิดการประหยัดหน่วยความจำ (Memory Optimization)
    if hasattr(pipe, "enable_attention_slicing"):
        pipe.enable_attention_slicing()
        
    print(f"\n🎨 กำลังเรนเดอร์วิดีโอ {num_frames} เฟรม ด้วยพรอมพ์:")
    print(f"   Positive: {prompt}")
    if negative_prompt:
        print(f"   Negative: {negative_prompt}")
        
    start_time = time.time()
    result = pipe(
        prompt=prompt,
        negative_prompt=negative_prompt or "ugly, distorted, blurry, watermark",
        num_frames=num_frames,
        num_inference_steps=25,
        height=256,
        width=256
    )
    elapsed = time.time() - start_time
    video_frames = result.frames[0]
    
    proj_dir, final_output_path = setup_project_folder(prompt=prompt, custom_output=output_path)
    export_to_video(video_frames, final_output_path, fps=fps)
    
    # บันทึกภาพ Thumbnail พรีวิว
    if len(video_frames) > 0:
        thumb_path = proj_dir / "thumbnails" / "thumb_01.png"
        first_frame = video_frames[0]
        if isinstance(first_frame, np.ndarray):
            if first_frame.dtype != np.uint8:
                if first_frame.max() <= 1.0:
                    first_frame = (first_frame * 255).clip(0, 255).astype(np.uint8)
                else:
                    first_frame = first_frame.clip(0, 255).astype(np.uint8)
            Image.fromarray(first_frame).save(thumb_path)
        elif isinstance(first_frame, Image.Image):
            first_frame.save(thumb_path)
        
    # บันทึก Metadata อย่างละเอียด
    meta = {
        "project_name": proj_dir.name,
        "type": "text-to-video",
        "model": DEFAULT_T2V_MODEL,
        "positive_prompt": prompt,
        "negative_prompt": negative_prompt,
        "duration_seconds": round(num_frames / fps, 2),
        "frames": num_frames,
        "fps": fps,
        "resolution": "256x256",
        "render_time_sec": round(elapsed, 2),
        "director_data": director_data or {},
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    with open(proj_dir / "metadata.json", "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
        
    with open(proj_dir / "README.md", "w", encoding="utf-8") as f:
        f.write(f"# Project: {proj_dir.name}\n\n"
                f"- **โมเดล:** `{DEFAULT_T2V_MODEL}`\n"
                f"- **Prompt:** {prompt}\n"
                f"- **ความยาว:** {meta['duration_seconds']} วินาที ({num_frames} เฟรม @ {fps} fps)\n"
                f"- **เวลาเรนเดอร์:** {meta['render_time_sec']} วินาที\n"
                f"- **ไฟล์วิดีโอ:** [`video.mp4`](file://{proj_dir}/video.mp4)\n"
                f"- **ภาพพรีวิว:** [`thumbnails/thumb_01.png`](file://{proj_dir}/thumbnails/thumb_01.png)\n")

    print(f"\n✅ เรนเดอร์วิดีโอสำเร็จในเวลา {elapsed:.1f} วินาที!")
    print(f"📁 บันทึกในโฟลเดอร์โปรเจกต์: {proj_dir}")
    print(f"   🎥 วิดีโอ: {final_output_path}")
    print(f"   🖼️ พรีวิว: {proj_dir / 'thumbnails' / 'thumb_01.png'}")
    print(f"   📝 ข้อมูล: {proj_dir / 'metadata.json'}")
    return final_output_path

def generate_image_to_video(image_path: str, num_frames: int = 25, fps: int = 7, motion_bucket_id: int = 127, output_path: str = None):
    """สร้างวิดีโอจากรูปภาพ (Image-to-Video) ด้วย Stable Video Diffusion (SVD)"""
    from diffusers import StableVideoDiffusionPipeline
    from diffusers.utils import load_image, export_to_video
    
    device = get_device()
    print(f"\n🚀 เริ่มต้นโหลดโมเดล Image-to-Video: {DEFAULT_I2V_MODEL}")
    print(f"⚡ อุปกรณ์ประมวลผล: {device} (Apple Silicon Metal MPS)")
    
    image = load_image(image_path)
    image = image.resize((1024, 576))
    
    dtype = torch.float16 if device.type == "mps" else torch.float32
    pipe = StableVideoDiffusionPipeline.from_pretrained(
        DEFAULT_I2V_MODEL,
        torch_dtype=dtype,
        variant="fp16" if dtype == torch.float16 else None
    )
    pipe.to(device)
    
    if hasattr(pipe, "enable_attention_slicing"):
        pipe.enable_attention_slicing()
        
    print(f"\n🎨 กำลังประมวลผลการเคลื่อนไหวจากภาพ {image_path} (Motion Bucket: {motion_bucket_id})...")
    start_time = time.time()
    frames = pipe(
        image,
        num_frames=num_frames,
        decode_chunk_size=8,
        motion_bucket_id=motion_bucket_id,
        noise_aug_strength=0.02
    ).frames[0]
    elapsed = time.time() - start_time
    
    proj_dir, final_output_path = setup_project_folder(prompt="svd_image_anim", custom_output=output_path)
    export_to_video(frames, final_output_path, fps=fps)
    
    if len(frames) > 0:
        Image.fromarray(frames[0]).save(proj_dir / "thumbnails" / "thumb_01.png")
        
    meta = {
        "project_name": proj_dir.name,
        "type": "image-to-video",
        "model": DEFAULT_I2V_MODEL,
        "source_image": image_path,
        "motion_bucket_id": motion_bucket_id,
        "duration_seconds": round(num_frames / fps, 2),
        "frames": num_frames,
        "fps": fps,
        "render_time_sec": round(elapsed, 2),
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    with open(proj_dir / "metadata.json", "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
        
    print(f"\n✅ สร้างวิดีโอสำเร็จในเวลา {elapsed:.1f} วินาที!")
    print(f"📁 บันทึกในโฟลเดอร์โปรเจกต์: {proj_dir}")
    return final_output_path

def main():
    parser = argparse.ArgumentParser(description="Ollama + Local Video AI Generator (Apple Silicon)")
    parser.add_argument("--prompt", "-p", type=str, help="คำบรรยายวิดีโอที่ต้องการสร้าง (ภาษาไทยหรืออังกฤษ)")
    parser.add_argument("--image", "-i", type=str, help="พาธไฟล์ภาพต้นแบบสำหรับ Image-to-Video (SVD)")
    parser.add_argument("--ollama-model", "-m", type=str, default=DEFAULT_OLLAMA_MODEL, help="โมเดล Ollama ที่ต้องการใช้เป็น Director (ค่าเริ่มต้น: llama3.2)")
    parser.add_argument("--skip-ollama", action="store_true", help="ข้ามขั้นตอนการขยาย Prompt ด้วย Ollama")
    parser.add_argument("--frames", "-f", type=int, default=16, help="จำนวนเฟรมของวิดีโอ (ค่าเริ่มต้น: 16)")
    parser.add_argument("--fps", type=int, default=8, help="เฟรมเรตของวิดีโอต่อวินาที (ค่าเริ่มต้น: 8)")
    parser.add_argument("--output", "-o", type=str, help="พาธไฟล์บันทึกผลลัพธ์ .mp4")
    parser.add_argument("--list-models", action="store_true", help="แสดงรายชื่อโมเดล Ollama ในเครื่อง")
    
    args = parser.parse_args()
    
    if args.list_models:
        print("\n📋 รายการโมเดล Ollama ในเครื่อง:")
        os.system("ollama list")
        return
        
    if not args.prompt and not args.image:
        print("\n" + "="*70)
        print("🎬 ยินดีต้อนรับสู่ Ollama + Local Video AI Generator")
        print("="*70)
        print("ตัวอย่างการใช้งาน:")
        print("  1. สร้างจากไอเดีย (ผ่าน Ollama AI Director):")
        print("     python ollama_video_generator.py -p 'โดรนบินตรวจแปลงเกษตรอัจฉริยะในสวนทุเรียน'")
        print("\n  2. สร้างจากภาพนิ่ง (Image-to-Video):")
        print("     python ollama_video_generator.py -i my_soil_photo.png")
        print("\n  3. สั่งให้ DeepSeek-R1 เป็นผู้กำกับ:")
        print("     python ollama_video_generator.py -p 'น้ำหยดลงดิน' -m deepseek-r1:latest")
        print("="*70)
        
        # Interactive prompt
        concept = input("\n💡 กรุณาใส่ไอเดียหรือฉากวิดีโอที่ต้องการสร้าง: ").strip()
        if not concept:
            print("ยกเลิกการทำงาน")
            return
        args.prompt = concept

    # 1. จัดการ Image-to-Video
    if args.image:
        if not os.path.exists(args.image):
            print(f"❌ ไม่พบไฟล์รูปภาพ: {args.image}")
            sys.exit(1)
        generate_image_to_video(
            image_path=args.image,
            num_frames=args.frames if args.frames else 25,
            fps=args.fps if args.fps else 7,
            output_path=args.output
        )
        return

    # 2. จัดการ Text-to-Video
    director_data = {}
    if not args.skip_ollama:
        director_data = query_ollama_director(args.prompt, model_name=args.ollama_model)
        video_prompt = director_data.get("prompt", args.prompt)
        negative_prompt = director_data.get("negative_prompt", "")
        camera_motion = director_data.get("camera_movement", "")
        director_note = director_data.get("director_note_th", "")
        
        print("\n" + "-"*60)
        print(f"🎬 [Ollama Director Plan]:")
        print(f"   🎥 Prompt อังกฤษ: {video_prompt}")
        print(f"   📐 มุมกล้อง: {camera_motion}")
        if director_note:
            print(f"   📝 บันทึกผู้กำกับ: {director_note}")
        print("-"*60)
    else:
        video_prompt = args.prompt
        negative_prompt = ""

    generate_text_to_video(
        prompt=video_prompt,
        negative_prompt=negative_prompt,
        num_frames=args.frames,
        fps=args.fps,
        output_path=args.output,
        director_data=director_data
    )

if __name__ == "__main__":
    main()
