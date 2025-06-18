import requests
#import numpy as np

# For Ollama
def get_ollama_embedding(text):
    response = requests.post(
        "http://localhost:11434/api/embeddings",
        json={"model": "nomic-embed-text", "prompt": text}
    )
    return response.json()["embedding"]

# For TEI API
def get_tei_embedding(text):
    response = requests.post(
        "http://localhost:8080/embed",
        json={"inputs": text}
    )
    return response.json()[0]

# Test
embedding = get_ollama_embedding("This is a test sentence")
print(f"Embedding dimension: {len(embedding)}")