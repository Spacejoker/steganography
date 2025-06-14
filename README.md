# Nim Steganography: PNG Bit Encoder

This project encodes a **text file into the least significant bits of a PNG image**, using Nim. It modifies the **RGB channels** of each pixel to hide compressed data, and later decodes it with full recovery.

---

## 🖼️ Example
Hidden data is first ~50 pages of the metamorphois by Kafka.

### Input: `test.png`
<img src="test.png" width="300" alt="Input image">

### Output: `output.png` (with hidden text)
<img src="output.png" width="300" alt="Output image with encoded message">


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

