// Unicode constants.
class Char {
  // Section: ASCII
  static asciiMin { 0 }
  static asciiMax { 0x7F }
  static space { 0x20 }
  static asciiLineEndings { Char.lineEndings.where {|x| x <= Char.asciiMax } }

  // Section: Line Endings
  // See: https://en.wikipedia.org/wiki/Newline#Unicode

  // Carriage Return
  static carriageReturn { "\r".codePoints[0] }
  // Line Feed
  static lineFeed { "\n".codePoints[0] }
  // Vertical tab
  static verticalTab { 0xB }
  // Form feed
  static formFeed { 0xC }
  // Next Line
  static nextLine { 0x0085 }
  // Line Separator
  static lineSeparator { 0x2028 }
  // Paragraph Separator
  static paragraphSeparator { 0x2029 }
  static lineEndings {
    return [
      Char.carriageReturn,
      Char.lineFeed,
      Char.verticalTab,
      Char.formFeed,
      Char.nextLine,
      Char.lineSeparator,
      Char.paragraphSeparator
    ]
  }

  // Section: Whitespace
  static nonBreakingSpace { 160 }
  // Note: Ideographic Space (`0x3000`) is purposefully excluded.
  // See: https://en.wikipedia.org/wiki/Whitespace_character#Unicode
  static whitespace {
    var chars = [
      9,
      Char.space,
      Char.nonBreakingSpace,
      0x1680,
    ]
    chars.addAll([0x2000..0x200A].toList)
    chars.addAll([0x202F, 0x205F])
    chars.addAll(Char.lineEndings)
    return chars
  }
}

class Magpie {
  // Entry point for a parser
  static parse(parser, input) {
    var result = parser.call(input)
    if (result is ParserFn) {
      Fiber.abort("Unexpected `ParserFn` result. Did you forget to use `.call(input)` in your custom `ParserFn`?")
    }
    return result
  }

  // Section: Primitive Helpers
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

  // Section: Primitive Parsers
  static fail { Magpie.fail("") }
  static fail(message) {
    return ParserFn.new { |input|
      Fiber.abort(message)
    }
  }

  // Section: Common Parsers
  static eof { Magpie.eof() }
  static eof() {
    return ParserFn.new { |input|
      if (input.count > 0) Fiber.abort(
        "Expected end of input, but saw %(input)"
      )
    }
  }

  // Parse a line ending.
  // See: https://en.wikipedia.org/wiki/Newline#Unicode
  static linefeed { Magpie.linefeed() }
  // ditto
  static linefeed() {
    return Magpie.or(
      // CR + LF
      Magpie.str("\r\n"),
      Magpie.or(Char.lineEndings.map {|char| Magpie.char(char) })
    )
  }

  // Parse Unicode whitespace.
  // See: https://en.wikipedia.org/wiki/Whitespace_character#Unicode
  static whitespace { Magpie.whitespace() }
  // ditto
  static whitespace() {
    return Magpie.or(Magpie.charFrom(9..13), Magpie.char(32))
  }
  // ditto
  // Exclude the given `range` of code points.
  // Params: range: Num|List<Num>|Range
  // Throws: When the given `range` exceeds the set of ASCII code points.
  static whitespace(range) {
    if (range is Num) range = [range..range]
    if (range is List && range.any {|x| !(x is Num) }) Fiber.abort("Expected a list of Num.")

    var chars = Char.whitespace.where {|x| x < range.min && x > range.max }
    return Magpie.or(chars.map {|char| Magpie.char(char) })
  }

  static alphaLower { Magpie.alphaLower() }
  static alphaLower() {
    return Magpie.charFrom(Magpie.charRangeFrom("a", "z"))
  }
  static alphaUpper { Magpie.alphaUpper() }
  static alphaUpper() {
    return Magpie.charFrom(Magpie.charRangeFrom("A", "Z"))
  }

  // Parse an ASCII character.
  // See: https://en.wikipedia.org/wiki/Basic_Latin_(Unicode_block)
  static ascii { Magpie.ascii() }
  // ditto
  static ascii() { Magpie.charFrom(0..Char.asciiMax) }
  // ditto
  // Exclude the given `range` of code points.
  // Params: range: Num|List<Num>|Range Code points to exclude.
  // Throws: When the given `range` is a `List` and any of its items are not in the set of ASCII code points.
  // Throws: When the given `range` exceeds the set of ASCII code points.
  static ascii(range) {
    if (range is Num) range = [range..range]
    if (range is List && range.any {|x| !(x is Num) }) Fiber.abort("Expected a list of Num.")
    if (range is List && range.any {|x| x < 0 || x > Char.asciiMax }) {
      Fiber.abort("Expected only Num elements in the range of `0` to `%(Char.asciiMax)`, inclusive.")
    }
    if (range is Range && (range.min < 0 || range.max > Char.asciiMax)) {
      Fiber.abort("Expected a range between `0` and `%(Char.asciiMax)`, inclusive.")
    }
    if (range is Range) range = range.toList

    var chars = (0..Char.asciiMax).toList.where {|x| !range.contains(x) }.toList
    return Magpie.or(chars.map {|char| Magpie.char(char) }.toList)
  }

  // Parse an Arabic numeral digit, i.e. any number between zero and nine.
  static digit { Magpie.digit(0..9) }
  // ditto
  static digit() { Magpie.digit(0..9) }
  // Parse an Arabic numeral digit, i.e. any number between zero and nine, in the given `range`.
  // Params: range: Range
  // Throws: When the given `range` is less than zero or greater than nine.
  static digit(range) {
    if (range.min < 0 || range.max > 9) Fiber.abort("Expected a range between zero and nine, inclusive.")
    return ParserFn.new { |input|
      var num = Num.fromString(input[0])
      if (num != null && (range.isInclusive ? num >= range.min : num > range.min) && num <= range.max) {
        return Result.new(num, input[0])
      }
      Fiber.abort("Expected a number between %(range.min) and %(range.max)")
    }
  }

  // Parse a `range` of characters.
  // Params: range: Range of Unicode code points.
  static charFrom(range) {
    if (range.min < 0) Fiber.abort("Expected a range between zero and +∞, inclusive.")
    return ParserFn.new { |input|
      var observedChar = input[0].codePoints[0]
      for (char in range) {
        if (observedChar == char) return Result.new(input[0])
      }
      Fiber.abort(
        "Expected a char in the range '%(String.fromCodePoint(range.min))' to '%(String.fromCodePoint(range.max))', but saw '%(input[0])' (%(observedChar))"
      )
    }
  }
  // Parse a single Unicode code point
  static char(codePoint) {
    return ParserFn.new { |input|
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
  // Parse a literal string.
  // Params: value: String
  static str(value) {
    return ParserFn.new { |input|
      if (input.startsWith(value)) return Result.new(value)
      Fiber.abort("Expected \"%(value)\", but saw \"%(input)\"")
    }
  }

  // Section: Combinators
  // Params: parser: ParserFn|Fn
  // Throws: When `parser`'s arity is not one.
  static one(parser) {
    if (parser.arity != 1) Fiber.abort("Expected a Fn with one parameter.")
    if (parser is ParserFn) return parser
    return ParserFn.new { |input|
      return parser.call(input)
    }
  }
  static optional(parser) {
    return ParserFn.new { |input|
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
    return ParserFn.new { |input|
      var result = null
      var error = null
      // Try each parser, returning the first successful result
      for (parser in parsers) {
        var error = Fiber.new {
          result = parser.call(input)
        }.try()
        if (error == null) return result
      }
      Fiber.abort("Expected a choice, but saw \"%(input)\": %(error)")
    }
  }
  static sequence(a, b) {
    return Magpie.sequence([a, b])
  }
  static sequence(parsers) {
    return ParserFn.new { |input|
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
    return ParserFn.new { |input|
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
    return ParserFn.new { |input|
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
}

// A parser `Fn`.
class ParserFn {
  // Params:
  // fn: Fn
  construct new(fn) {
    _fn = fn
  }

  arity { _fn.arity }

  // Params:
  // input: String
  call(input) {
    return _fn.call(input)
  }

  // Section: Result Modifiers

  // Tag the result of this parser with the given `value`.
  // Params:
  // value: String
  tag(value) {
    return this.map {|result|
      if (result is List) return result.map {|r| r.tag(value)}.toList
      return result.tag(value)
    }
  }

  // Join all of the tokens that result from this parser together.
  join { join() }
  // ditto
  join() {
    return this.map {|result|
      if (result is List) return result[0].rewrite(
        result.map {|r| r.token }.join(),
        result.map {|r| r.lexeme }.join()
      )
      return result.rewrite(result.token)
    }
  }

  // Map the results of this parser to the result given by `fn`.
  // Params:
  // fn: Fn
  map(fn) {
    return ParserFn.new { |input|
      var result = this.call(input)
      var token = fn.call(result)
      if (token is Result) return token
      if (result is List) return result.map {|r| r.rewrite(token) }.toList
      return result.rewrite(token)
    }
  }
}

// Section: Parser Results
// A parse result token and its source lexeme.
class Result {
  construct new(token) {
    if (token is Result) Fiber.abort("Tokens should not be Result values.")
    _lexeme = _token = token
  }
  construct new(token, lexeme) {
    if (token is Result) Fiber.abort("Tokens should not be Result values.")
    _lexeme = token
    _token = token
  }

  // Params: results: Result|List<Result>
  static lexemes(results) {
    if (results is Result) return results.lexeme
    return results.reduce("", Fn.new {|str,token|
      return str + token.lexeme
    })
  }

  // Params: results: Result|List<Result>
  static tokens(results) {
    if (results is Result) return results.token
    return results.map {|r| r.token }.toList
  }

  // Params: results: Result|List<Result>
  static tags(results) {
    if (results is Result) return results.tag
    return results.map {|token| token.tag }.toList
  }

  // Params: list: List
  // Returns: List<Result>
  static flatMap(list) {
    if (list is List == false) Fiber.abort("Expected a List of `Result`s.")
    var results = []
    for (result in list) {
      if (result is EmptyResult) continue
      if (result is Result) results.add(result)
      if (result is List) results.addAll(Result.flatMap(result))
    }
    return results
  }

  lexeme { _lexeme }
  token { _token }
  // Type: String
  tag { _tag }
  // ditto
  tag=(value) { _tag = value }
  // TODO: Add source location info

  // Whether this result's `token` is a nested list of `Result`'s.
  nested { token is List && token[0] is Result }

  map(fn) {
    return Result.new(fn.call(_token), _lexeme)
  }

  rewrite(token) {
    return this.rewrite(token, lexeme)
  }
  rewrite(token, lexeme) {
    _token = token
    _lexeme = lexeme
    return this
  }

  tag(value) {
    _tag = value
    return this
  }
}

// See: `Magpie.optional`
class EmptyResult is Result {
  construct new() {
    _token = null
    _lexeme = ""
  }
}
