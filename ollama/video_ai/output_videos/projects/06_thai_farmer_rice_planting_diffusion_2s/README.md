# Project 06: Thai Farmer Rice Planting (True AI Video Diffusion)

ภาพยนตร์วิดีโอสั้นสร้างด้วย **AI Neural Network Diffusion Model แท้ๆ (`ali-vilab/text-to-video-ms-1.7b`)** บนชิปประมวลผล Apple Silicon Metal GPU (MPS) โดยใช้โมเดลตัวเดียวกับโปรเจกต์ 01 เพื่อเปรียบเทียบเนื้อภาพ แสงเงา และความสมจริงแบบ Generative AI

---

## 📋 ข้อมูลทางเทคนิค
- **โมเดล AI:** `ali-vilab/text-to-video-ms-1.7b` (Text-to-Video Diffusion)
- **AI Director:** `video-director` (Ollama LLaMA 3.2)
- **Prompt:** `A slow cinematic drone flies forward over a serene paddy field at dawn, as a Thai farmer tenderly plants green rice seedlings amidst the murky waters. The scene is bathed in warm golden hour light, with volumetric rays illuminating the lush vegetation and delicate water droplets. Highly detailed realistic documentary style.`
- **Negative Prompt:** `artificial textures, pixelation, motion blur, blurry, low quality`
- **ความยาว:** 2.0 วินาที (16 เฟรม @ 8 fps)
- **ความละเอียด:** 256x256 พิกเซล
- **ฮาร์ดแวร์ประมวลผล:** Apple Silicon Metal MPS (FP16 Attention Slicing)

---

## 🎬 ไฟล์ในโปรเจกต์
- 🎥 วิดีโอหลัก: [`video.mp4`](file:///Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/projects/06_thai_farmer_rice_planting_diffusion_2s/video.mp4)
- 🖼️ ภาพพรีวิว: [`thumbnails/thumb_01.png`](file:///Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/projects/06_thai_farmer_rice_planting_diffusion_2s/thumbnails/thumb_01.png)
- 📝 ข้อมูลจำเพาะ: [`metadata.json`](file:///Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/projects/06_thai_farmer_rice_planting_diffusion_2s/metadata.json)

---

## 💻 วิธีเปิดชมบน macOS
```bash
open /Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/soil_app/ollama/video_ai/output_videos/projects/06_thai_farmer_rice_planting_diffusion_2s/video.mp4
```
