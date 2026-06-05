def split_into_oligos(dna: str, oligo_size: int = 100):
    """
    Split DNA sequence into fixed-size oligos
    """
    return [dna[i:i+oligo_size] for i in range(0, len(dna), oligo_size)]
