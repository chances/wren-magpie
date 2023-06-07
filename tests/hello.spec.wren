import "../vendor/assert/Assert" for Assert
import "../magpie" for Magpie

Assert.equal(Magpie.charRangeFrom("0"), 48..48)
Assert.equal(Magpie.charRangeFrom("09"), 48..57)
Assert.equal(Magpie.charRangeFrom("AZ"), 65..90)
Assert.equal(Magpie.charRangeFrom("az"), 97..122)

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.str("hello"), "hello world")
  Assert.equal(result, "hello")
})

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.or(Magpie.str("hello"), Magpie.str("world")), "world")
  Assert.equal(result, "world")
})

// Assert.doesNotAbort(Fn.new {
//   var result = Magpie.parse(Magpie.discardWhitespace(), " \t\r\n")
//   Assert.equal(result, "")
// })
