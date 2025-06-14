# Nim Steganography: PNG Bit Encoder

This project encodes a **text file into the least significant bits of a PNG image**, using Nim. It modifies the **RGB channels** of each pixel to hide compressed data, and later decodes it with full recovery.

---

## 🖼️ Example

- Input image: [`test.png`](test.png)
- Output image with embedded message: [`output.png`](output.png)
- Hidden text file: [`kafka.txt`](kafka.txt)

--

## ✨ Features

- 🔐 Bit-level steganography (LSB encoding) across R, G, B channels
- 🖼️ Pure image-based storage — no external metadata

---

## 🚀 How It Works

1. **Read message** from `kafka.txt`
1. **Embed** bitstream into `test.png` using pixel RGB least significant bits
1. Save as `output.png`

To decode:
1. Load `output.png`
2. Extract least significant bits from RGB
3. Convert bits -> binary -> string

---

## 🧪 Run

```sh
nim -r main.nim
```

