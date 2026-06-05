def binary_to_bytes(binary):
    byte_array = bytearray()
    for i in range(0, len(binary), 8):
        byte = binary[i:i+8]
        byte_array.append(int(byte, 2))
    return bytes(byte_array)
