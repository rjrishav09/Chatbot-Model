from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from groq import Groq
import os

app = FastAPI()
templates = Jinja2Templates(directory="templates")
client = Groq(api_key=os.getenv("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"))

@app.get("/", response_class=HTMLResponse)
async def root(request: Request):
    return templates.get_template("index.html").render({"request": request})

@app.post("/chat")
async def chat(request: Request):
    data = await request.json()
    messages = data["messages"]
    
    response = client.chat.completions.create(
        model="llama-3.1-70b-instant",  # or any uncensored-leaning model
        messages=messages,
        temperature=0.8,
        max_tokens=2048
    )
    return {"reply": response.choices[0].message.content}
