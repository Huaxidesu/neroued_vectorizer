from fastapi import FastAPI, UploadFile, File
from fastapi.responses import FileResponse, HTMLResponse
import subprocess
import uuid
import os

app = FastAPI()

# 1. 访问根目录时，直接返回 index.html 网页
@app.get("/")
async def get_index():
    with open("index.html", "r", encoding="utf-8") as f:
        return HTMLResponse(content=f.read())

# 2. 处理图片转 SVG 的 API 接口
@app.post("/api/vectorize")
async def vectorize_image(file: UploadFile = File(...)):
    job_id = str(uuid.uuid4())
    in_path = f"/tmp/{job_id}.png"
    out_path = f"/tmp/{job_id}.svg"

    # 保存上传的图片到容器的临时目录
    with open(in_path, "wb") as f:
        f.write(await file.read())

    # 调用底层的 C++ 核心工具
    subprocess.run([
        "raster_to_svg", 
        "--image", in_path, 
        "--out", out_path,
        "--pipeline", "v2" # 这里可以自由修改默认的转换参数
    ], check=True)

    # 返回生成的 SVG 文件，并在返回后清理临时文件
    response = FileResponse(out_path, media_type="image/svg+xml")
    
    # 清理原始上传的图片 (SVG 会由 FastAPI 发送完毕后自动释放，这里只删原图)
    os.remove(in_path) 
    return response