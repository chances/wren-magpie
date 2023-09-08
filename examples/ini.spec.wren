import "wren-assert/assert" for Assert
import "io" for File

import "./ini" for Ini
import "./../magpie" for Char, Magpie, Result

Assert.doesNotAbort {
  Assert.equal(Ini.whitespace.call("  ").lexeme, "  ")
}

Assert.doesNotAbort {
  Assert.equal(Magpie.parse(Ini.comment, "; Something to say").token, "Something to say")
}

Assert.doesNotAbort {
  Assert.deepEqual(Magpie.parse(Ini.sectionName, "foo").token, "foo")
}

Assert.doesNotAbort {
  var ini = File.read("examples/example.ini")
  var document = Ini.parse(ini)
  Assert.typeOf(document, Ini)
  Assert.countOf(document.sections, 1)
  Assert.countOf(document.sections[0].properties, 1)
}
