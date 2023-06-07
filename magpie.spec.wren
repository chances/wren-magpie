import "../vendor/assert/Assert" for Assert
import "../magpie" for Magpie

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

Assert.aborts(Fn.new {
  Magpie.parse(Magpie.eof, "a")
})

Assert.doesNotAbort(Fn.new {
  Magpie.parse(Magpie.eof, "")
})

Assert.aborts(Fn.new {
  Magpie.parse(Magpie.digit, "a")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.digit(), "0")
  Assert.equal(result, "0")
})

Assert.doesNotAbort(Fn.new {
  Assert.equal(Magpie.parse(Magpie.char("0"), "0"), "0")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.str("hello"), "hello world")
  Assert.equal(result, "hello")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.or(Magpie.str("hello"), Magpie.str("world")), "world")
  Assert.equal(result, "world")
})

Assert.aborts(Fn.new {
  Assert.equal(Magpie.parse(Magpie.or(Magpie.digit, Magpie.charRangeFrom("a", "z")), "aA"), "a")
  Assert.equal(Magpie.parse(Magpie.or(Magpie.digit, Magpie.charRangeFrom("a", "z")), "abdzA"), "abdz")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.zeroOrMore(Magpie.charFrom(Magpie.charRangeFrom("a", "z"))), "aaaB")
  Assert.equal(result, "aaa")
})

Assert.doesNotAbort(Fn.new {
  var lower = Magpie.charFrom(Magpie.charRangeFrom("a", "z"))
  var upper = Magpie.charFrom(Magpie.charRangeFrom("A", "Z"))
  Assert.equal(Magpie.parse(Magpie.sequence(lower, upper), "aB"), "aB")
  Assert.equal(Magpie.parse(Magpie.sequence(lower, upper), "qT"), "qT")
  Assert.equal(Magpie.parse(Magpie.zeroOrMore(Magpie.sequence(lower, upper)), "aBaB"), "aBaB")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.whitespace(), " \t\r\n")
  Assert.equal(result, " \t\r\n")
})
