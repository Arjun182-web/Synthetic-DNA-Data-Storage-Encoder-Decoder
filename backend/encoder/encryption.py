from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes

def encrypt_data(data: bytes, key: bytes) -> bytes:
    cipher = AES.new(key, AES.MODE_EAX)
    ciphertext, tag = cipher.encrypt_and_digest(data)
    return cipher.nonce + tag + ciphertext
