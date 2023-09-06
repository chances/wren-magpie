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
  static advanceInput(input, result) {
    if (result is List) return input[Result.lexemes(result).count..-1]
    return input[result.lexeme.count..-1]
  }

  // Primitive Parsers
  static fail { Magpie.fail("") }
  static fail(message) {
    return Fn.new { |input|
      Fiber.abort(message)
    }
  }

  static alphaLower { Magpie.alphaLower() }
  static alphaLower() {
    return Magpie.charFrom(Magpie.charRangeFrom("a", "z"))
  }
  static alphaUpper { Magpie.alphaUpper() }
  static alphaUpper() {
    return Magpie.charFrom(Magpie.charRangeFrom("A", "Z"))
  }

  static digit { Magpie.digit(0..9) }
  static digit() { Magpie.digit(0..9) }
  static digit(range) {
    if (range.min < 0 || range.max > 9) Fiber.abort("Expected a range between zero and nine, inclusive.")
    return Fn.new { |input|
      var num = Num.fromString(input[0])
      if (num != null && (range.isInclusive ? num >= range.min : num > range.min) && num <= range.max) {
        return Result.new(num, input[0])
      }
      Fiber.abort("Expected a number between %(range.min) and %(range.max)")
    }
  }

  static charFrom(range) {
    if (range.min < 0) Fiber.abort("Expected a range between zero and +∞, inclusive.")
    return Fn.new { |input|
      var observedChar = input[0].codePoints[0]
      for (char in range) {
        if (observedChar == char) return Result.new(input[0])
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
      if (observedChar == codePoint) return Result.new(input[0])
      Fiber.abort(
        "Expected '%(String.fromCodePoint(codePoint))' (%(codePoint)), but saw '%(String.fromCodePoint(observedChar))' (%(observedChar))"
      )
    }
  }
  static str(value) {
    return Fn.new { |input|
      if (input.startsWith(value)) return Result.new(value)
      Fiber.abort("Expected \"%(value)\", but saw \"%(input)\"")
    }
  }

  // Combinators
  static one(parser) {
    return Fn.new { |input|
      return parser.call(input)
    }
  }
  static optional(parser) {
    return Fn.new { |input|
      var result = EmptyResult.new()
      var error = (Fiber.new {
        result = parser.call(input)
      }).try()
      return result
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
        var error = Fiber.new {
          result = parser.call(input)
        }.try()
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
      // Try each parser in sequence
      var results = []
      for (parser in parsers) {
        var result = parser.call(input)
        if (result is EmptyResult) continue
        results.add(result)
        input = Magpie.advanceInput(input, result)
      }
      return Result.flatMap(results)
    }
  }
  static zeroOrMore(parser) {
    return Fn.new { |input|
      var results = []
      var error = null
      while (error == null && input.count > 0) {
        error = (Fiber.new {
          var result = parser.call(input)
          results.add(result)
          input = Magpie.advanceInput(input, result)
        }).try()
      }
      return Result.flatMap(results)
    }
  }
  static oneOrMore(parser) {
    return Fn.new { |input|
      var results = []
      var error = (Fiber.new {
        var result = parser.call(input)
        results.add(result)
        input = Magpie.advanceInput(input, result)
      }).try()
      if (error != null) Fiber.abort(error)
      while (error == null && input.count > 0) {
        error = (Fiber.new {
          var result = parser.call(input)
          results.add(result)
          input = Magpie.advanceInput(input, result)
        }).try()
      }
      return Result.flatMap(results)
    }
  }

  // Special Combinators
  static whitespace { Magpie.whitespace() }
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

// A parse result token and its source lexeme.
class Result {
  construct new(token) {
    _lexeme = _token = token
  }
  construct new(token, lexeme) {
    _lexeme = token
    _token = token
  }

  static lexemes(results) {
    return results.reduce("", Fn.new {|str,token|
      return str + token.lexeme
    })
  }

  static flatMap(list) {
    var results = []
    for (r in list) {
      if (r is Result) results.add(r)
      if (r is List) results.addAll(Result.flatMap(r))
    }
    return results
  }

  lexeme { _lexeme }
  token { _token }
  // TODO: Add source location info

  map(fn) {
    return Result.new(fn.call(this.token), this.lexeme)
  }
}

// See `Magpie.optional`
class EmptyResult is Result {
  construct new() {
    _token = null
    _lexeme = ""
  }
}
