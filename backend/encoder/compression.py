import gzip

def compress_data(data: bytes) -> bytes:
    """
    Lossless compression using GZIP
    """
    return gzip.compress(data)
