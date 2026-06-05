def dna_to_binary(dna):
    mapping = {
        "A": "00",
        "C": "01",
        "G": "10",
        "T": "11"
    }
    return "".join(mapping[base] for base in dna)
