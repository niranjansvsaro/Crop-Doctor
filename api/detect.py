import os
import json
import base64
import re
import uuid
import asyncio
from io import BytesIO
from typing import List, Optional
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from PIL import Image
import requests
from dotenv import load_dotenv
from deep_translator import GoogleTranslator
from supabase import create_client, Client

# Load environment variables
load_dotenv()

app = FastAPI(
    title="Crop Doctor AI Backend",
    description="AI-powered crop disease detection API using NVIDIA NIM and translation services.",
    version="1.0.0"
)

# Enable CORS for mobile and web frontends
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# NVIDIA API Configuration
NVIDIA_API_KEY = os.getenv("NVIDIA_API_KEY")
NVIDIA_URL = "https://integrate.api.nvidia.com/v1/chat/completions"
# Using the requested model from the provided snippet
NVIDIA_MODEL = "meta/llama-3.2-90b-vision-instruct"

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase: Optional[Client] = None
if SUPABASE_URL and SUPABASE_KEY:
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("Supabase client initialized successfully.")
    except Exception as e:
        print(f"Failed to initialize Supabase client: {e}")

# Supported Languages Map for deep-translator
LANG_MAP = {
    "hindi": "hi",
    "tamil": "ta",
    "telugu": "te",
    "kannada": "kn",
    "english": "en"
}

# Request Model
class DetectRequest(BaseModel):
    image_base64: str = Field(..., description="Base64 encoded string of the leaf image")
    language: str = Field(..., description="Target language (english, hindi, tamil, telugu, kannada)")
    farmer_id: str = Field(..., description="Unique ID of the farmer")
    gps_lat: Optional[float] = Field(None, description="GPS Latitude")
    gps_lng: Optional[float] = Field(None, description="GPS Longitude")

# Response Model
class DiseaseDetectionResponse(BaseModel):
    disease_name: str
    disease_name_local: str
    confidence: float
    severity: int
    affected_area_pct: float
    crop_type: str
    symptoms: str
    symptoms_local: str
    treatment_steps: List[str]
    treatment_steps_local: List[str]
    pesticide_name: str
    pesticide_cost_inr: str
    prevention_tips: str
    prevention_tips_local: str
    is_diseased: bool
    image_url: Optional[str] = None
    created_at: str

def clean_base64(b64_string: str) -> str:
    """Removes data URL prefix if present (e.g., 'data:image/jpeg;base64,')"""
    if "," in b64_string:
        return b64_string.split(",")[1]
    return b64_string

def compress_image(b64_string: str, max_size_kb: int = 500) -> str:
    """Validates and compresses base64 image to ensure it is under 500KB"""
    try:
        image_data = base64.b64decode(b64_string)
        img = Image.open(BytesIO(image_data))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image format: {e}")

    # If already smaller than max_size_kb, return as is
    if len(image_data) <= max_size_kb * 1024:
        return b64_string

    # Standardize format to JPEG
    if img.mode in ("RGBA", "P"):
        img = img.convert("RGB")

    # Resize/compress loop
    quality = 85
    output = BytesIO()
    
    # Let's resize if image dimensions are huge
    max_dims = 1024
    if max(img.width, img.height) > max_dims:
        img.thumbnail((max_dims, max_dims), Image.Resampling.LANCZOS)

    while quality > 30:
        output.seek(0)
        output.truncate(0)
        img.save(output, format="JPEG", quality=quality)
        data = output.getvalue()
        if len(data) <= max_size_kb * 1024:
            break
        quality -= 10

    return base64.b64encode(data).decode("utf-8")

def translate_text(text: str, target_lang: str) -> str:
    """Helper to translate text into regional language using deep-translator"""
    lang_code = LANG_MAP.get(target_lang.lower(), "en")
    if lang_code == "en" or not text:
        return text
    try:
        return GoogleTranslator(source="en", target=lang_code).translate(text)
    except Exception as e:
        print(f"Translation error: {e}")
        return text

def parse_nvidia_response(content: str) -> dict:
    """Extracts and parses JSON object from NVIDIA AI completion"""
    # Remove markdown code block markers if any
    cleaned = re.sub(r"```json|```", "", content)
    
    # Extract the first matching JSON block (from the first '{' to the last '}')
    match = re.search(r"(\{.*\})", cleaned, re.DOTALL)
    if match:
        json_str = match.group(1).strip()
        return json.loads(json_str)
        
    raise ValueError("No JSON object found in response.")

async def upload_image_to_supabase(image_bytes: bytes, filename: str) -> Optional[str]:
    """Uploads scan image to Supabase storage bucket asynchronously"""
    if not supabase:
        return None
    try:
        # Run synchronous supabase storage call in a thread pool
        loop = asyncio.get_event_loop()
        bucket = "leaf-scans"
        
        # Upload file
        res = await loop.run_in_executor(
            None,
            lambda: supabase.storage.from_(bucket).upload(
                filename,
                image_bytes,
                file_options={"content-type": "image/jpeg"}
            )
        )
        
        # Get public URL
        url_res = supabase.storage.from_(bucket).get_public_url(filename)
        return url_res
    except Exception as e:
        print(f"Error uploading image to Supabase: {e}")
        return None

async def save_scan_to_supabase(scan_data: dict):
    """Saves scan record to Supabase database table asynchronously"""
    if not supabase:
        return
    try:
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(
            None,
            lambda: supabase.table("scans").insert(scan_data).execute()
        )
        print("Scan saved successfully to Supabase.")
    except Exception as e:
        print(f"Error saving scan to Supabase DB: {e}")

@app.get("/")
async def root():
    return {
        "status": "online",
        "app": "Crop Doctor AI Backend",
        "message": "AI-powered plant disease detection server is up and running!"
    }

@app.post("/api/detect", response_model=DiseaseDetectionResponse)
async def detect_disease(request: DetectRequest, background_tasks: BackgroundTasks):
    if not NVIDIA_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="NVIDIA API key is not configured on the backend server."
        )

    # 1. Validate and clean base64 image
    cleaned_b64 = clean_base64(request.image_base64)
    
    # 2. Compress image if needed (under 500KB)
    compressed_b64 = compress_image(cleaned_b64)
    image_bytes = base64.b64decode(compressed_b64)

    # 3. Call NVIDIA NIM API
    headers = {
        "Authorization": f"Bearer {NVIDIA_API_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json"
    }

    system_prompt = (
        "You are an expert agricultural pathologist specializing in Indian crops.\n"
        "Analyze the crop leaf image and identify possible disease.\n\n"
        "IMPORTANT RULES:\n"
        "- Return ONLY valid raw JSON\n"
        "- Do NOT use markdown\n"
        "- Do NOT use ```json\n"
        "- Do NOT add explanations\n"
        "- Do NOT add notes before or after JSON\n"
        "- Response must start with {\n"
        "- Response must end with }\n\n"
        "Return this exact JSON structure:\n"
        "{\n"
        '  "disease_name": "string",\n'
        '  "confidence": 0.0,\n'
        '  "severity": 1,\n'
        '  "affected_area_pct": 0.0,\n'
        '  "crop_type": "string",\n'
        '  "symptoms": "string",\n'
        '  "treatment_steps": [\n'
        '    "step 1",\n'
        '    "step 2"\n'
        '  ],\n'
        '  "pesticide_name": "string",\n'
        '  "pesticide_cost_inr": "string",\n'
        '  "prevention_tips": "string",\n'
        '  "is_diseased": true\n'
        "}"
    )

    # Note: Llama 3.2 Vision uses standard data URL syntax for image completions.
    image_data_url = f"data:image/jpeg;base64,{compressed_b64}"
    
    payload = {
        "model": NVIDIA_MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": system_prompt},
                    {"type": "image_url", "image_url": {"url": image_data_url}}
                ]
            }
        ],
        "max_tokens": 1024,
        "temperature": 0.2,
        "top_p": 1.0
    }

    try:
        response = requests.post(NVIDIA_URL, headers=headers, json=payload, timeout=30)
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"NVIDIA API Error: {response.text}"
            )
        
        result_json = response.json()
        ai_content = result_json["choices"][0]["message"]["content"]
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=500,
            detail=f"Failed to communicate with NVIDIA NIM API: {str(e)}"
        )

    # 4. Parse AI response
    try:
        disease_info = parse_nvidia_response(ai_content)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to parse structured response from AI model: {e}. Raw content: {ai_content}"
        )

    # Ensure all required fields exist or have default values
    disease_name = disease_info.get("disease_name", "Unknown Disease")
    confidence = float(disease_info.get("confidence", 0.5))
    severity = int(disease_info.get("severity", 1))
    affected_area_pct = float(disease_info.get("affected_area_pct", 0.0))
    crop_type = disease_info.get("crop_type", "Unknown Crop")
    symptoms = disease_info.get("symptoms", "No symptoms described.")
    treatment_steps = list(disease_info.get("treatment_steps", []))
    pesticide_name = disease_info.get("pesticide_name", "N/A")
    pesticide_cost_inr = disease_info.get("pesticide_cost_inr", "N/A")
    prevention_tips = disease_info.get("prevention_tips", "No prevention tips described.")
    is_diseased = bool(disease_info.get("is_diseased", True))

    # 5. Translate results
    target_lang = request.language.lower()
    
    disease_name_local = translate_text(disease_name, target_lang)
    symptoms_local = translate_text(symptoms, target_lang)
    prevention_tips_local = translate_text(prevention_tips, target_lang)
    
    treatment_steps_local = []
    for step in treatment_steps:
        treatment_steps_local.append(translate_text(step, target_lang))

    import datetime
    created_at_str = datetime.datetime.utcnow().isoformat() + "Z"

    # Set up response object
    response_data = DiseaseDetectionResponse(
        disease_name=disease_name,
        disease_name_local=disease_name_local,
        confidence=confidence,
        severity=severity,
        affected_area_pct=affected_area_pct,
        crop_type=crop_type,
        symptoms=symptoms,
        symptoms_local=symptoms_local,
        treatment_steps=treatment_steps,
        treatment_steps_local=treatment_steps_local,
        pesticide_name=pesticide_name,
        pesticide_cost_inr=pesticide_cost_inr,
        prevention_tips=prevention_tips,
        prevention_tips_local=prevention_tips_local,
        is_diseased=is_diseased,
        created_at=created_at_str
    )

    # 6. Save to Supabase asynchronously if configured
    if supabase:
        # Generate filename
        file_id = str(uuid.uuid4())
        filename = f"{request.farmer_id}/{file_id}.jpg"
        
        # We define a background task to handle uploading and saving
        async def handle_supabase_sync():
            img_url = await upload_image_to_supabase(image_bytes, filename)
            if img_url:
                response_data.image_url = img_url
            
            # Format treatments as serialized JSON or string for DB
            treatment_en_str = "\n".join([f"{i+1}. {s}" for i, s in enumerate(treatment_steps)])
            treatment_local_str = "\n".join([f"{i+1}. {s}" for i, s in enumerate(treatment_steps_local)])

            scan_db_row = {
                "id": file_id,
                "farmer_id": request.farmer_id,
                "image_url": img_url if img_url else "",
                "disease_name_en": disease_name,
                "disease_name_local": disease_name_local,
                "severity": severity,
                "confidence": confidence,
                "affected_area_pct": affected_area_pct,
                "treatment_en": treatment_en_str,
                "treatment_local": treatment_local_str,
                "crop_type": crop_type,
                "language": request.language,
                "gps_lat": request.gps_lat,
                "gps_lng": request.gps_lng,
                "created_at": created_at_str
            }
            await save_scan_to_supabase(scan_db_row)

        background_tasks.add_task(handle_supabase_sync)

    return response_data

# For local direct running
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("detect:app", host="0.0.0.0", port=8000, reload=True)
