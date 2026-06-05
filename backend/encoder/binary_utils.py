def bytes_to_binary(data: bytes) -> str:
    """
    Convert bytes to binary string
    """
    return ''.join(format(byte, '08b') for byte in data)
