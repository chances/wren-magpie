class Magpie {
  // Primitive Helpers
  static charRangeFrom(string) {
    if (string == null || string.count == 0) Fiber.abort("Expected a non-null and non-empty string.")
    var a = string[0].codePoints.reduce { |min, n| n < min ? n : min }
    var b = string[0].codePoints.reduce { |max, n| n > max ? n : max }
    return a..b
  }
  static charRangeFrom(start, end) {
    if (start == null || start.count == 0) Fiber.abort("Expected a non-null and non-empty start string.")
    if (end == null || end.count == 0) Fiber.abort("Expected a non-null and non-empty end string.")
    var a = string[0].codePoints[0]
    var b = string[0].codePoints[0]
    return a..b
  }

  // Primitive Parsers
  static digit() { Magpie.digit(0..9) }
  static digit(range) {
    if (range.min < 0 || range.max > 9) Fiber.abort("Expected a range between zero and nine, inclusive.")
    return Fn.new { |input|
      var num = Num.fromString(input[0])
      if ((range.isInclusive ? num >= range.min : num > range.min) && num <= range.max) return input
      Fiber.abort("Expected a number between %(range.min) and %(range.max)")
    }
  }
  static charFrom(range) {
    if (range.min < 0) Fiber.abort("Expected a range between zero and +∞, inclusive.")
    return Fn.new { |input|
      for (char in range) {
        if (input[0].codePoints[0] == String.fromCodePoint(char)) return input[0]
      }
      Fiber.abort(
        "Expected a char in the range %(String.fromCodePoint(range.min)) to %(String.fromCodePoint(range.max))"
      )
    }
  }

  static char(codePoint) {
    return Fn.new { |input|
      if (input[0].codePoints[0] == codePoint) return input[0]
      Fiber.abort(
        "Expected a '%(codePoint)' char, but got '%(input[0].codePoints[0])'"
      )
    }
  }
  static str(value) {
    return Fn.new { |input|
      if (input.startsWith(value)) return value
      Fiber.abort("Expected \"%(value)\", but got\"%(input)\"")
    }
  }

  // Combinators
  static one(parser) {
    return Fn.new { |input|
      parser.call(input)
    }
  }
  static or(parserA, parserB) {
    return Fn.new { |input|
      // Try parser A
      var result = null
      var fiber = Fiber.new {
        result = parserA.call(input)
      }
      var error = fiber.try()
      if (error == null) return result
      // Try parser B
      fiber = Fiber.new {
        result = parserB.call(input)
      }
      error = fiber.try()
      if (error != null) Fiber.abort("Expected a choice, but got \"%(input)\": %(error)")
      return result
    }
  }
  static zeroOrMore(parser) {
    return Fn.new { |input|
      var result = ""
      var fiber = Fiber.new {
        result = result + parser.call(input)
      }
      var error = fiber.try()
      if (error != null) return result
      while (error == null) {
        fiber = Fiber.new {
          result = result + parser.call(input)
        }
        error = fiber.try()
      }
      return result
    }
  }

  // Special Combinators
  // FIXME: This could be infinitely recursive?
  static discardWhitespace() {
    return Fn.new { |input|
      // See https://en.wikipedia.org/wiki/Whitespace_character#Unicode
      var eatWhitespace = Magpie.zeroOrMore(
        Magpie.or(Magpie.charFrom(9..13), Magpie.char(32))
      )
      eatWhitespace.call(input)
      return ""
    }
  }

  // Entry point for a parser
  static parse(parser, input) {
    return parser.call(input)
  }
}
