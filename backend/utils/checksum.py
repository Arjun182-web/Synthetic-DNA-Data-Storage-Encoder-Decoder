import hashlib

def generate_checksum(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()
