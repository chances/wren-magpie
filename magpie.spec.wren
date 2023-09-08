import "wren-assert/assert" for Assert
import "./magpie" for Char, EmptyResult, Magpie, ParserFn, Result

Assert.exists(Char)
Assert.exists(EmptyResult)
Assert.exists(Magpie)
Assert.exists(ParserFn)
Assert.exists(Result)

// Results

var result = Result.new("token")
Assert.equal(result.token, "token")
Assert.equal(result.lexeme, "token")
Assert.equal(result.tag, null)
Assert.equal(result.nested, false)

Assert.aborts { Assert.deepEqual(Result.flatMap(result), result) }
Assert.deepEqual(Result.flatMap([result]), [result])
Assert.deepEqual(Result.flatMap([result, [result]]), [result, result])
Assert.deepEqual(Result.flatMap([result, [result, result]]), [result, result, result])

// Parsers

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
  var result = Magpie.parse(Magpie.sequence(Magpie.alphaLower, Magpie.alphaUpper).join, "aB")
  Assert.equal(result.lexeme, "aB")
  Assert.equal(result.token, "aB")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.sequence(Magpie.alphaLower, Magpie.alphaUpper).join, "qT")
  Assert.equal(result.lexeme, "qT")
  Assert.equal(result.token, "qT")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.zeroOrMore(Magpie.sequence(Magpie.alphaLower, Magpie.alphaUpper)).join, "aBaB")
  Assert.equal(result.lexeme, "aBaB")
  Assert.equal(result.token, "aBaB")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.oneOrMore(Magpie.alphaLower).join, "aaaB")
  Assert.equal(result.lexeme, "aaa")
  Assert.equal(result.token, "aaa")
})

Assert.aborts(Fn.new {
  Magpie.parse(Magpie.oneOrMore(Magpie.alphaLower), "CAPS")
})

Assert.aborts(Fn.new {
  Magpie.parse(Magpie.oneOrMore(Magpie.alphaUpper), "lower")
})

// Tab Character
Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.whitespace.join, "\t")
  Assert.equal(result.lexeme, "\t")
})

// Tab Character (32)
Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.whitespace.join, "  ")
  Assert.equal(result.lexeme[0].codePoints[0], 32)
})

// Spaces
Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.whitespace.join, " ")
  Assert.equal(result.lexeme, " ")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.oneOrMore(Magpie.whitespace).join.tag("linefeed"), "\r\n")
  Assert.equal(result.tag, "linefeed")
  Assert.deepEqual(result.token, "\r\n")
  Assert.equal(result.lexeme, "\r\n")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.oneOrMore(Magpie.whitespace).join, "\t\r\n")
  Assert.deepEqual(result.token, "\t\r\n")
  Assert.deepEqual(result.lexeme, "\t\r\n")
})

Assert.doesNotAbort(Fn.new {
  Magpie.zeroOrMore(Magpie.whitespace(Char.lineEndings)).join.call("")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.zeroOrMore(Magpie.whitespace(Char.lineEndings)).join.call("  ")
  Assert.equal(result.token, "  ")
})

Assert.aborts(Fn.new {
  Magpie.parse(Magpie.whitespace, "foo")
})

// Result Modifiers

Assert.doesNotAbort(Fn.new {
  Assert.ok(Magpie.whitespace.discard.call(" ") is EmptyResult)
})

Assert.doesNotAbort(Fn.new {
  Assert.countOf(Magpie.oneOrMore(Magpie.whitespace.discard).call("\t "), 0)
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.sequence(Magpie.whitespace, Magpie.whitespace.discard).call("\t ")
  Assert.countOf(result, 1)
  Assert.typeOf(result[0], Result)
})

Assert.doesNotAbort(Fn.new {
  var result = Result.new(0, "0")
  result.tag("number")
  Assert.equal(result.tag, "number")
  result.tag = "zero"
  Assert.equal(result.tag, "zero")
})
