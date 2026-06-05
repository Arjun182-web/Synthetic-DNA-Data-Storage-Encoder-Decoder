def generate_fasta(oligos: list) -> str:
    fasta = ""
    for index, oligo in enumerate(oligos):
        fasta += f">oligo_{index}\n"
        fasta += oligo + "\n"
    return fasta
