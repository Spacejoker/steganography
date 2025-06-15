import sequtils
import std/algorithm
from std/strutils import join
import pixie
import zippy

# Make interface x bits, y bits offset
# Make a header of x size bits - read it first to know all the details.
# Fixed size header: can contain any data (read first x bits)

proc encode*(data: string): string =
  var seq = toSeq(data)
  reverse(seq)
  return seq.join("")


let channelBits = 4

# Target offset needs divide 12 (pixel * channels * bit)
proc writeToImage(img: Image, bits: seq[bool], targetOffset: int, numBits: int): int =
  var ret = 0
  var srcOffset = 0
  var skippedBits = 0
  for y in 0..<img.height:
    for x in 0..<img.width:
      var idx = y * img.width + x

      var px = img.data[idx]

      for channel in [addr px.r, addr px.g, addr px.b]:
        let cb = 4
        for i in 0..<cb:
          if skippedBits < targetOffset:
            inc skippedBits
            continue
          if srcOffset >= numBits:
            break
          if bits[srcOffset]:
            channel[] = channel[] or (1'u8 shl i)
          else:
            channel[] = channel[] and not (1'u8 shl i)
          inc srcOffset

      img.data[idx] = px

      if srcOffset >= numBits:
        break

    if srcOffset >= numBits:
      break
  return srcOffset

proc intToBits(n: int, width: int = 64): seq[bool] =
  for i in countdown(width - 1, 0):
    result.add(((n shr i) and 1) == 1)

proc bitsToInt(bits: seq[bool]): int =
  for i, b in bits:
    if b:
      result = result or (1 shl (bits.len - 1 - i))

proc decodeImage(img: Image, startOffset: int, numBits: int): seq[bool] =
  var bitIdx = 0
  for y in 0..<img.height:
    for x in 0..<img.width:
      let idx = y * img.width + x
      let px = img.data[idx]

      for channel in [px.r, px.g, px.b]:
        for i in 0..<channelBits:
          if bitIdx < startOffset:
            inc bitIdx
            continue
          result.add((channel and (1'u8 shl i)) != 0)
          inc bitIdx
          if result.len == numBits:
            return

proc stringToBits(s: string): seq[bool] =
  for c in s:
    for i in countdown(7, 0):
      result.add(((c.ord shr i) and 1) == 1)

proc bitsToBytes(bits: seq[bool]): seq[byte] =
  for i in countup(0, bits.len - 1, 8):
    var b: byte = 0
    for j in 0..<8:
      if i + j < bits.len and bits[i + j]:
        b = b or (1.byte shl (7 - j))
    result.add(b)

proc toStringMessage(bits: seq[bool]): string =
  for i in countup(0, bits.len - 1, 8):
    var b: uint8 = 0
    for j in 0..<8:
      if i + j < bits.len and bits[i + j]:
        b = b or (1'u8 shl (7 - j))  # MSB first
    if b == 0:
      return
    result.add(char(b))

proc main(): void =
  var image = readImage("test.png")
  let contents = readFile("kafka.txt")
  let zipContents = compress(contents)
  let contentLen = zipContents.len

  # Num bits in input
  let sizeBitSeq = intToBits(contentLen * 8, 64)
  echo sizeBitSeq
  discard writeToImage(image, sizeBitSeq, 0, 64)
  let contentBits = stringToBits(zipContents)
  discard writeToImage(image, contentBits, 64, contentBits.len)
  image.writeFile("output.png")

  var encodedImg = readImage("output.png")
  var bitMessage = decodeImage(encodedImg, 0, 64)
  var sz = bitsToInt(bitMessage)
  var zipRet = decodeImage(encodedImg, 64, sz)
  var bytes = bitsToBytes(zipRet)
  var ret = uncompress(bytes)
  let s = cast[string](ret)
  echo s

  # var stringMessage = toStringMessage(bitMessage)
  echo sz
  # echo "Number bits total:" & $totalbits

main()

