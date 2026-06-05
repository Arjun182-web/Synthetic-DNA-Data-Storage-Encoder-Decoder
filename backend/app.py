from flask import Flask, request, jsonify, send_file
import os
import tempfile

# ---------- ENCODER IMPORTS ----------
from encoder.compression import compress_data
from encoder.encryption import encrypt_data
from encoder.binary_utils import bytes_to_binary
from encoder.dna_encoder import binary_to_dna
from encoder.oligo_utils import split_into_oligos
from encoder.fasta_utils import generate_fasta
from utils.checksum import generate_checksum

# ---------- DECODER IMPORTS ----------
from decoder.fasta_reader import read_fasta
from decoder.dna_decoder import dna_to_binary
from decoder.binary_utils import binary_to_bytes
from decoder.decryption import decrypt_data
from decoder.decompression import decompress_data

app = Flask(__name__)

# ================= ENCODE =================
@app.route("/encode", methods=["POST"])
def encode():
    file = request.files.get("file")
    user_key = request.form.get("key")

    if not file:
        return jsonify({"error": "No file uploaded"}), 400

    if not user_key or len(user_key) != 16:
        return jsonify({"error": "Encryption key must be exactly 16 characters"}), 400

    SECRET_KEY = user_key.encode()

    original_filename = file.filename
    file_bytes = file.read()

    checksum = generate_checksum(file_bytes)
    compressed = compress_data(file_bytes)

    print("Original size:", len(file_bytes))
    print("Compressed size:", len(compressed))

    encrypted = encrypt_data(compressed, SECRET_KEY)
    binary = bytes_to_binary(encrypted)
    dna = binary_to_dna(binary)
    oligos = split_into_oligos(dna)

    fasta_content = f">FILENAME:{original_filename}\n"
    fasta_content += f">CHECKSUM:{checksum}\n"
    fasta_content += generate_fasta(oligos)

    fasta_path = os.path.join(tempfile.gettempdir(), "encoded_output.fasta")

    with open(fasta_path, "w") as f:
        f.write(fasta_content)

    return send_file(
        fasta_path,
        as_attachment=True,
        download_name="encoded_output.fasta",
        mimetype="text/plain"
    )


# ================= DECODE =================
@app.route("/decode", methods=["POST"])
def decode():
    file = request.files.get("file")
    user_key = request.form.get("key")

    if not file:
        return jsonify({"error": "No FASTA file uploaded"}), 400

    if not user_key or len(user_key) != 16:
        return jsonify({"error": "Decryption key must be exactly 16 characters"}), 400

    SECRET_KEY = user_key.encode()

    fasta_text = file.read().decode()
    lines = fasta_text.splitlines()

    original_filename = "decoded_output"
    stored_checksum = None
    dna_start_index = 0

    for i, line in enumerate(lines):
        if line.startswith(">FILENAME:"):
            original_filename = line.replace(">FILENAME:", "").strip()
        elif line.startswith(">CHECKSUM:"):
            stored_checksum = line.replace(">CHECKSUM:", "").strip()
        elif not line.startswith(">"):
            dna_start_index = i
            break

    dna_data = "\n".join(lines[dna_start_index:])

    try:
        dna = read_fasta(dna_data.encode())
        binary = dna_to_binary(dna)
        encrypted_bytes = binary_to_bytes(binary)
        decrypted = decrypt_data(encrypted_bytes, SECRET_KEY)
        original_data = decompress_data(decrypted)
    except:
        return jsonify({"error": "Wrong decryption key or corrupted file!"}), 400

    calculated_checksum = generate_checksum(original_data)

    if stored_checksum and calculated_checksum != stored_checksum:
        return jsonify({"error": "Checksum mismatch! File corrupted."}), 400

    output_path = os.path.join(tempfile.gettempdir(), original_filename)

    with open(output_path, "wb") as f:
        f.write(original_data)

    return send_file(
        output_path,
        as_attachment=True,
        download_name=original_filename
    )


if __name__ == "__main__":
    app.run(debug=True)
