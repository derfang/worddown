import os
import base64
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.backends import default_backend

def get_random_bytes(length):
    return os.urandom(length)

key = get_random_bytes(32)
iv = get_random_bytes(16)

key_b64 = base64.b64encode(key).decode('utf-8')
iv_b64 = base64.b64encode(iv).decode('utf-8')

print(f"MASTER_KEY = '{key_b64}'")
print(f"MASTER_IV = '{iv_b64}'")

def encrypt_string(plaintext):
    padder = padding.PKCS7(128).padder()
    padded_data = padder.update(plaintext.encode()) + padder.finalize()
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
    encryptor = cipher.encryptor()
    ciphertext = encryptor.update(padded_data) + encryptor.finalize()
    return base64.b64encode(ciphertext).decode('utf-8')

def encrypt_file(in_path, out_path):
    if not os.path.exists(in_path):
        print(f"File {in_path} not found.")
        return
    with open(in_path, 'rb') as f:
        data = f.read()
    padder = padding.PKCS7(128).padder()
    padded_data = padder.update(data) + padder.finalize()
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
    encryptor = cipher.encryptor()
    ciphertext = encryptor.update(padded_data) + encryptor.finalize()
    with open(out_path, 'wb') as f:
        f.write(ciphertext)
    print(f"Encrypted {in_path} -> {out_path}")

encrypt_file('assets/word_dictionary.json', 'assets/word_dictionary.json.enc')
encrypt_file('assets/data/frequency_ranking.json', 'assets/data/frequency_ranking.json.enc')

strings_to_encrypt = [
    "058daa1c-96cf-4b55-b016-115dd35136e1",
    "https://cdn-wordup.com/Contents/v2025-10-23/",
    "https://www.zann.app/dictionary/",
    "https://web.wordupapp.co",
    "https://web.wordupapp.co/",
    "wordup_full",
    "web",
    "https://translate.google.com/translate_tts?ie=UTF-8&tl=",
    "https://dict.youdao.com/dictvoice?audio="
]

print('\nEncrypted Strings:')
for s in strings_to_encrypt:
    print(f"'{s}' -> '{encrypt_string(s)}'")

