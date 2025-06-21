import requests

# For Ollama
def get_ollama_embedding(text):
    response = requests.post(
        "http://localhost:11434/api/embeddings",
        json={"model": "nomic-embed-text", "prompt": text}
    )
    data = response.json()
    print(f"Ollama API response: {data}")
    if "embedding" not in data:
        raise ValueError("'embedding' key not found in Ollama API response.")
    return data["embedding"]

# Test
embedding = get_ollama_embedding("This is a test sentence")
print(f"Embedding dimension: {len(embedding)}")