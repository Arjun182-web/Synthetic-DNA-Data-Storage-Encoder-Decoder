def read_fasta(file_bytes):
    text = file_bytes.decode()
    lines = text.splitlines()

    sequences = []
    for line in lines:
        if not line.startswith(">"):
            sequences.append(line.strip())

    return "".join(sequences)
