import sequtils
import std/algorithm
from std/strutils import join
import pixie

proc encode*(data: string): string =
  var seq = toSeq(data)
  reverse(seq)
  return seq.join("")

proc channelBits(color: uint8): int = 
  var c = color
  var highestBit = 0
  while c > 0:
    c = c div 2'u8
    highestBit += 1
  var useBits = highestBit - 3
  if useBits > 0:
    return useBits
  return 0

proc countBits(img: Image, bits: seq[bool]): int =
  var ret = 0
  var offset = 0
  for y in 0..<img.height:
    for x in 0..<img.width:
      var idx = y * img.width + x
      var px = img.data[idx]

      for channel in [addr px.r, addr px.g, addr px.b]:
        let cb = channelBits(channel[])
        for i in 0..<cb:
          if offset >= bits.len:
            break
          if bits[offset]:
            channel[] = channel[] or (1'u8 shl i)
          else:
            channel[] = channel[] and not (1'u8 shl i)
          inc offset

      img.data[idx] = px

      if offset >= bits.len:
        break

    if offset >= bits.len:
      break
  return offset

proc decodeImage(img: Image): seq[bool] =
  for y in 0..<img.height:
    for x in 0..<img.width:
      var idx = y * img.width + x
      var px = img.data[idx]
      for channel in [addr px.r, addr px.g, addr px.b]:
        let cb = channelBits(channel[])
        for i in 0..<cb:
          result.add((channel[] and (1'u8 shl i)) != 0)

proc stringToBits(s: string): seq[bool] =
  for c in s:
    for i in countdown(7, 0):
      result.add(((c.ord shr i) and 1) == 1)

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
  var bits = stringToBits(contents)
  var totalBits = countBits(image, bits)
  # echo $image.width  & " x " & $image.height
  image.writeFile("output.png")

  var encodedImg = readImage("output.png")
  var bitMessage = decodeImage(encodedImg)
  var stringMessage = toStringMessage(bitMessage)
  echo stringMessage
  echo "Number bits total:" & $totalbits
  


main()

