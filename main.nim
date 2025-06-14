import sequtils
import std/algorithm
from std/strutils import join
import pixie

proc encode*(data: string): string =
  var seq = toSeq(data)
  reverse(seq)
  return seq.join("")

proc main(): void =
  let image = readImage("test.png")
  let pixel = image[10, 10]
  for y in 0..10:
    for x in 0..10:
      image.data[x + y*image.width] = rgba(255, 0, 0, 255)
  
  image.writeFile("output.png")

main()