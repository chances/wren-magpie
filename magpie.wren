class Magpie {
  // Primitive Helpers
  static charRangeFrom(string) {
    if (string == null || string.count == 0) Fiber.abort("Expected a non-null and non-empty string.")
    var a = string.codePoints.reduce { |min, n| n < min ? n : min }
    var b = string.codePoints.reduce { |max, n| n > max ? n : max }
    return a..b
  }
  static charRangeFrom(start, end) {
    if (start == null || start.count == 0) Fiber.abort("Expected a non-null and non-empty start string.")
    if (end == null || end.count == 0) Fiber.abort("Expected a non-null and non-empty end string.")
    var a = start[0].codePoints[0]
    var b = end[0].codePoints[0]
    return a..b
  }

  // Primitive Parsers
  static digit { Magpie.digit(0..9) }
  static digit() { Magpie.digit(0..9) }
  static digit(range) {
    if (range.min < 0 || range.max > 9) Fiber.abort("Expected a range between zero and nine, inclusive.")
    return Fn.new { |input|
      var num = Num.fromString(input[0])
      if (num != null && (range.isInclusive ? num >= range.min : num > range.min) && num <= range.max) return input
      Fiber.abort("Expected a number between %(range.min) and %(range.max)")
    }
  }
  static charFrom(range) {
    if (range.min < 0) Fiber.abort("Expected a range between zero and +∞, inclusive.")
    return Fn.new { |input|
      var observedChar = input[0].codePoints[0]
      for (char in range) {
        if (observedChar == char) return input[0]
      }
      Fiber.abort(
        "Expected a char in the range '%(String.fromCodePoint(range.min))' to '%(String.fromCodePoint(range.max))', but saw '%(input[0])' (%(observedChar))"
      )
    }
  }

  static char(codePoint) {
    return Fn.new { |input|
      if (codePoint is String && codePoint.count > 1) Fiber.abort("Expected only a single character.")
      // Convert a string to its first UTF code point
      if (codePoint is String) codePoint = codePoint[0].codePoints[0]
      var observedChar = input[0].codePoints[0]
      if (observedChar == codePoint) return input[0]
      Fiber.abort(
        "Expected '%(String.fromCodePoint(codePoint))' (%(codePoint)), but saw '%(String.fromCodePoint(observedChar))' (%(observedChar))"
      )
    }
  }
  static str(value) {
    return Fn.new { |input|
      if (input.startsWith(value)) return value
      Fiber.abort("Expected \"%(value)\", but saw \"%(input)\"")
    }
  }

  // Combinators
  static one(parser) {
    return Fn.new { |input|
      parser.call(input)
    }
  }
  static or(parserA, parserB) {
    return Magpie.or([parserA, parserB])
  }
  static or(parsers) {
    if (!(parsers is Sequence)) Fiber.abort("Expected a sequence of parsers")
    return Fn.new { |input|
      var result = null
      var error = null
      // Try each parser, returning the first successful result
      for (parser in parsers) {
        var fiber = Fiber.new {
          result = parser.call(input)
        }
        error = fiber.try()
        if (error == null) return result
      }
      if (error != null) Fiber.abort("Expected a choice, but saw \"%(input)\": %(error)")
    }
  }
  static sequence(a, b) {
    return Magpie.sequence([a, b])
  }
  static sequence(parsers) {
    return Fn.new { |input|
      var results = parsers.map { |parser|
        var lexeme = parser.call(input)
        input = input[lexeme.count..-1]
        return lexeme
      }
      return results.reduce { |str,lexeme| str + lexeme }
    }
  }
  static zeroOrMore(parser) {
    return Fn.new { |input|
      var result = ""
      var error = null
      while (error == null && input.count > 0) {
        error = (Fiber.new {
          var lexeme = parser.call(input)
          result = result + lexeme
          input = input[lexeme.count..-1]
        }).try()
      }
      return result
    }
  }

  // Special Combinators
  static whitespace() {
    return Fn.new { |input|
      // See https://en.wikipedia.org/wiki/Whitespace_character#Unicode
      return Magpie.zeroOrMore(
        Magpie.or(Magpie.charFrom(9..13), Magpie.char(32))
      ).call(input)
    }
  }
  static eof { Magpie.eof() }
  static eof() {
    return Fn.new { |input|
      if (input.count > 0) Fiber.abort(
        "Expected end of input, but saw %(input)"
      )
    }
  }

  // Entry point for a parser
  static parse(parser, input) {
    return parser.call(input)
  }
}
