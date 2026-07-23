import requests
import json
import time
import sys

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

def test_generate():
    print("\n--- Testing /challenge/generate ---")
    payload = {
        "videoId": "pnWINBJ3-yA",
        "videoTimestamp": 120.0,
        "doubtContext": "I don't understand how to write a simple print statement in Python.",
        "language": "Python"
    }
    resp = requests.post(f"{BASE_URL}/challenge/generate", json=payload)
    if resp.status_code == 200:
        data = resp.json()
        print("Success! Generated Problem:")
        print(json.dumps(data, indent=2))
        return data
    else:
        print(f"Failed: {resp.status_code}")
        print(resp.text)
        return None

def test_grade(problem_statement):
    print("\n--- Testing /challenge/grade (CORRECT CODE) ---")
    code = "print('Hello World')\n"
    payload = {
        "problemStatement": problem_statement,
        "language": "Python",
        "code": code
    }
    resp = requests.post(f"{BASE_URL}/challenge/grade", json=payload)
    if resp.status_code == 200:
        print("Success! Grading Result:")
        print(json.dumps(resp.json(), indent=2))
    else:
        print(f"Failed: {resp.status_code} - {resp.text}")

    print("\n--- Testing /challenge/grade (SYNTAX ERROR) ---")
    code_wrong = "pritn('Hello World')"
    payload_wrong = {
        "problemStatement": problem_statement,
        "language": "Python",
        "code": code_wrong
    }
    resp_wrong = requests.post(f"{BASE_URL}/challenge/grade", json=payload_wrong)
    if resp_wrong.status_code == 200:
        print("Success! Grading Result (Expected Failure):")
        print(json.dumps(resp_wrong.json(), indent=2))
    else:
        print(f"Failed: {resp_wrong.status_code} - {resp_wrong.text}")

if __name__ == "__main__":
    if wait_for_server():
        challenge = test_generate()
        if challenge:
            prob = challenge.get('problemStatement', 'Write a Python program that prints Hello World.')
            test_grade(prob)
