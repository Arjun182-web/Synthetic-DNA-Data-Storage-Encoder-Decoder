from Crypto.Cipher import AES

def decrypt_data(ciphertext, key):
    cipher = AES.new(key, AES.MODE_EAX)
    nonce = ciphertext[:16]
    tag = ciphertext[16:32]
    data = ciphertext[32:]

    cipher = AES.new(key, AES.MODE_EAX, nonce=nonce)
    return cipher.decrypt_and_verify(data, tag)
