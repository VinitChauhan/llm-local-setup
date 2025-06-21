import requests

def get_ollama_prompt_response(text):
    response = requests.post(
        "http://localhost:11434/api/generate",
        json={"model": "llama3.2:3b-instruct-q4_0", "prompt": text, "stream": False}
    )
    data = response.json()
    print(f"Ollama API response: {data}")
    if "response" not in data:
        raise ValueError("'response' key not found in Ollama API response.")
    return data["response"]

if __name__ == "__main__":
    prompt = "Hello, how are you?"
    result = get_ollama_prompt_response(prompt)
    print(f"Model response: {result}")
