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


# Target offset needs divide 12 (pixel * channels * bit)
proc writeToImage(img: Image, bits: seq[bool], targetOffset: int, numBits: int, channelBits: int): int =
  var ret = 0
  var srcOffset = 0
  var skippedBits = 0
  for y in 0..<img.height:
    for x in 0..<img.width:
      var idx = y * img.width + x

      var px = img.data[idx]

      for channel in [addr px.r, addr px.g, addr px.b]:
        let cb = channelBits
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

proc decodeImage(img: Image, startOffset: int, numBits: int, channelBits: int): seq[bool] =
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


let depthBitFootprint = 2

proc encodeToFile(filePath: string, contents: string) = 
  var image = readImage(filePath)
  let zipContents = compress(contents)
  let contentLen = zipContents.len
  let numChannels = image.width * image.height * 3
  let channelBits = ((contentLen * 8 + 64 + 4) div numChannels) + 1
  echo "Storing using bit depth " & $channelBits

  # Num bits in input
  let sizeBitSeq = intToBits(contentLen * 8, 64)

  discard writeToImage(image, intToBits(channelBits, 4), 0, 4, depthBitFootprint)
  discard writeToImage(image, sizeBitSeq, 4, 64, channelBits)
  let contentBits = stringToBits(zipContents)
  discard writeToImage(image, contentBits, 68, contentBits.len, channelBits)
  image.writeFile("output.png")

proc decodeImage(filePath: string): string =
  var encodedImg = readImage(filePath)
  var channelBits = bitsToInt(decodeImage(encodedImg, 0, 4, depthBitFootprint))

  echo "Decoding using bit depth " & $channelBits
  var bitMessage = decodeImage(encodedImg, 4, 64, channelBits)

  var sz = bitsToInt(bitMessage)
  var zipRet = decodeImage(encodedImg, 68, sz, channelBits)
  var bytes = bitsToBytes(zipRet)
  var ret = uncompress(bytes)
  return cast[string](ret)


proc main(): void =
  let contents = readFile("kafka.txt")
  encodeToFile("output.png", contents)
  discard decodeImage("output.png")

main()

