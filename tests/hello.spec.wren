import "../vendor/assert/Assert" for Assert
import "../magpie" for Magpie

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
