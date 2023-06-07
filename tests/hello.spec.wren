import "../vendor/assert/Assert" for Assert
import "../magpie" for Magpie

Assert.doesNotAbort(Fn.new {
  var result = Magpie.parse(Magpie.str("hello"), "hello world")
  System.print(result)
})
