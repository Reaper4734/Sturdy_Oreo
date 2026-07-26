import requests
import json
import time

BASE_URL = "http://localhost:8080/api/orchestration"

def wait_for_server():
    print("Waiting for server to start...")
    for _ in range(30):
        try:
            requests.get("http://localhost:8080/actuator/health")
            print("Server is up!")
            return True
        except:
            time.sleep(1)
    print("Server didn't start in time.")
    return False

def test_canvas_explain():
    print("\n--- Testing /canvas-explain ---")
    payload = {
        "userId": "11111111-1111-1111-1111-111111111111",
        "doubt": "Can you explain this part of the code?",
        "videoTimestamp": 10.0,
        "videoId": "pnWINBJ3-yA",
        "language": "en",
        "difficultyLevel": 3,
        "imageBase64": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    }
    
    resp = requests.post(f"{BASE_URL}/canvas-explain", json=payload)
    if resp.status_code == 200:
        data = resp.json()
        print("Success! LLM Response:")
        print(json.dumps(data, indent=2))
        return data
    else:
        print(f"Failed: {resp.status_code}")
        print(resp.text)
        return None

if __name__ == "__main__":
    if wait_for_server():
        test_canvas_explain()
