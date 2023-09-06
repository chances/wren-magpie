import "./vendor/assert/Assert" for Assert
import "./magpie" for Magpie, Result

Assert.exists(Magpie)

Assert.equal(Magpie.charRangeFrom("0"), 48..48)
Assert.equal(Magpie.charRangeFrom("0", "0"), 48..48)
Assert.equal(Magpie.charRangeFrom("09"), 48..57)
Assert.equal(Magpie.charRangeFrom("0", "9"), 48..57)
Assert.equal(Magpie.charRangeFrom("AZ"), 65..90)
Assert.equal(Magpie.charRangeFrom("A", "Z"), 65..90)
Assert.equal(Magpie.charRangeFrom("az"), 97..122)
Assert.equal(Magpie.charRangeFrom("a", "z"), 97..122)

Assert.doesNotAbort(Fn.new {
  Magpie.parse(Magpie.charFrom(Magpie.charRangeFrom("a", "z")), "a")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(
    Magpie.charFrom(Magpie.charRangeFrom("a", "z")).map {|result|
      return result.token[0].codePoints[0]
    },
    "a"
  )
  Assert.equal(result.token, 97)
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.alphaLower.tag("letter"), "a")
  Assert.equal(result.token, "a")
  Assert.equal(result.lexeme, "a")
  Assert.equal(result.tag, "letter")
})

Assert.doesNotAbort(Fn.new {
  Magpie.parse(Magpie.eof, "")
})

Assert.aborts(Fn.new {
  Magpie.parse(Magpie.eof, "a")
})

Assert.doesNotAbort(Fn.new {
  Magpie.parse(Magpie.alphaLower, "c")
})

Assert.aborts(Fn.new {
  Magpie.parse(Magpie.alphaLower, "C")
})

Assert.doesNotAbort(Fn.new {
  Magpie.parse(Magpie.alphaUpper, "A")
})

Assert.aborts(Fn.new {
  Magpie.parse(Magpie.alphaUpper, "b")
})

Assert.aborts(Fn.new {
  Magpie.parse(Magpie.digit, "a")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.digit(), "0")
  Assert.equal(result.token, 0)
})

Assert.doesNotAbort(Fn.new {
  Assert.equal(Magpie.parse(Magpie.char("0"), "0").token, "0")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.str("hello"), "hello world")
  Assert.equal(result.token, "hello")
})

Assert.doesNotAbort(Fn.new {
  var parser = Magpie.sequence(Magpie.str("hello"), Magpie.optional(Magpie.str(" world")))
  var result = Magpie.parse(parser, "hello world")
  Assert.equal(Result.lexemes(result), "hello world")
})

Assert.doesNotAbort(Fn.new {
  var parser = Magpie.sequence(Magpie.str("hello"), Magpie.optional(Magpie.str(" world")))
  Assert.equal(Magpie.parse(parser.join, "hello world").token, "hello world")
})

Assert.aborts(Fn.new {
  Magpie.parse(
    Magpie.sequence(Magpie.str("hello").discard, Magpie.str(" world")),
    "hello world"
  )
})

Assert.doesNotAbort(Fn.new {
  var parser = Magpie.sequence(Magpie.str("hello"), Magpie.optional(Magpie.str(" world")))
  var result = Magpie.parse(parser, "hello")
  Assert.equal(Result.lexemes(result), "hello")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.or(Magpie.str("hello"), Magpie.str("world")), "world")
  Assert.equal(result.lexeme, "world")
})

Assert.doesNotAbort(Fn.new {
  var parser = Magpie.or(Magpie.digit, Magpie.alphaLower)
  Assert.equal(Magpie.parse(parser, "3").token, 3)
})

Assert.doesNotAbort(Fn.new {
  var parser = Magpie.or(Magpie.digit, Magpie.alphaLower)
  Assert.equal(Magpie.parse(parser, "abba").token, "a")
})

Assert.doesNotAbort(Fn.new {
  var parser = Magpie.or(Magpie.digit, Magpie.alphaLower)
  Assert.equal(Magpie.parse(parser, "62").token, 6)
})

Assert.aborts(Fn.new { Magpie.parse(Magpie.or(Magpie.digit, Magpie.alphaLower), "A") })

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.or([Magpie.char("a"), Magpie.str("b"), Magpie.str("c")]), "c")
  Assert.equal(result.lexeme, "c")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(
    Magpie.or(
      Magpie.char("a").map {|result| "A" },
      Magpie.str("b").map {|result| "B" }
    ),
    "b"
  )
  Assert.equal(result.token, "B")
  Assert.equal(result.lexeme, "b")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.zeroOrMore(Magpie.charFrom(Magpie.charRangeFrom("a", "z"))), "aaaB")
  Assert.equal(Result.lexemes(result), "aaa")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.sequence(Magpie.alphaLower, Magpie.alphaUpper), "aB")
  Assert.equal(result.count, 2)
  Assert.equal(Result.lexemes(result), "aB")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.sequence(Magpie.alphaLower, Magpie.alphaUpper), "qT")
  Assert.equal(result.count, 2)
  Assert.equal(Result.lexemes(result), "qT")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.zeroOrMore(Magpie.sequence(Magpie.alphaLower, Magpie.alphaUpper)), "aBaB")
  Assert.equal(result.count, 4)
  Assert.equal(Result.lexemes(result), "aBaB")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.oneOrMore(Magpie.alphaLower), "aaaB")
  Assert.equal(result.count, 3)
  Assert.equal(Result.lexemes(result), "aaa")
})

Assert.aborts(Fn.new {
  Magpie.parse(Magpie.oneOrMore(Magpie.alphaLower), "CAPS")
})

Assert.aborts(Fn.new {
  Magpie.parse(Magpie.oneOrMore(Magpie.alphaUpper), "lower")
})

// Tab Character
Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.whitespace, "\t")
  Assert.equal(Result.lexemes(result), "\t")
})

// Tab Character (32)
Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.whitespace, "  ")
  Assert.equal(Result.lexemes(result)[0].codePoints[0], 32)
})

// Spaces
Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.whitespace, " ")
  Assert.equal(Result.lexemes(result), " ")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.whitespace.tag("linefeed"), "\r\n")
  Assert.equal(Result.tags(result).count, 2)
  Assert.equal(Result.tags(result)[0], "linefeed")
  Assert.equal(Result.lexemes(result), "\r\n")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.whitespace, "\t\r\n")
  Assert.equal(result.count, 3)
  Assert.equal(Result.lexemes(result), "\t\r\n")
})

Assert.doesNotAbort(Fn.new {
  var result = Result.new(0, "0")
  result.tag("number")
  Assert.equal(result.tag, "number")
  result.tag = "zero"
  Assert.equal(result.tag, "zero")
})
