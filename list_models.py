import os
import requests

api_key = os.getenv("GEMINI_API_KEY", "")
# if not found, we read from .env
if not api_key:
    with open('docs/.env') as f:
        for line in f:
            if line.startswith("GEMINI_KEY_1="):
                api_key = line.split('=', 1)[1].strip()

url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
response = requests.get(url)
if response.status_code == 200:
    models = response.json().get('models', [])
    for m in models:
        print(f"Name: {m['name']} | Display: {m.get('displayName', '')}")
else:
    print(f"Error {response.status_code}: {response.text}")
