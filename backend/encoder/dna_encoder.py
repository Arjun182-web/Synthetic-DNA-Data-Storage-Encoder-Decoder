def binary_to_dna(binary: str) -> str:
    mapping = {
        "00": "A",
        "01": "C",
        "10": "G",
        "11": "T"
    }

    dna = ""
    for i in range(0, len(binary), 2):
        dna += mapping[binary[i:i+2]]

    return dna
