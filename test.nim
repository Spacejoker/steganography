import unittest
import ./main

suite "Encoder Tests":
  test "Reverses":
    check encode("foo") == "oof"