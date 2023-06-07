import "../magpie" for Magpie

var test = Fiber.new {
  var result = Magpie.parse(Magpie.str("hello"), "hello world")
  System.print(result)
}
var err = test.try()
if (err != null) System.print(err)
