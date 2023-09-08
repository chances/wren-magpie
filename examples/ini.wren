import "./../magpie" for Char, Magpie, ParserFn, Result

var comment = Magpie.sequence([
  Magpie.optional(Magpie.linefeed),
  Magpie.str(";"),
  // Read any ASCII character until an ASCII line ending
  Magpie.ascii(Char.asciiLineEndings).tag("comment"),
  Magpie.linefeed,
])

var sectionName = ParserFn.new {|input|
  var closingSquareBracket = "]".codePoints[0]
  var chars = (0..Char.asciiMax).toList.where {|x| x != closingSquareBracket }
  return Magpie.oneOrMore(Magpie.or(chars.map {|char| Magpie.char(char) }))
}

var parser = Magpie.zeroOrMore(Magpie.sequence([
  Magpie.zeroOrMore(comment),
  // Section
  Magpie.one(Magpie.sequence([
    Magpie.str("["),
    sectionName.tag("name"),
    Magpie.str("]")
  ])).map {|r|
    return Section.new(r.where {|token| token.tag == "name" }[0])
  },
  Magpie.zeroOrMore(comment),
  // Properties
  Magpie.sequence([
    Magpie.whitespace(Char.lineEndings),
    Magpie.ascii(Char.asciiLineEndings).tag("name"),
    Magpie.whitespace(Char.lineEndings),
    Magpie.char("="),
    Magpie.whitespace(Char.lineEndings),
    Magpie.ascii(Char.asciiLineEndings).tag("value"),
    Magpie.zeroOrMore(comment)
  ]).tag("property").map {|r|
    return Property.new(
      r.where {|token| token.tag == "name" }[0],
      r.where {|token| token.tag == "value" }[0]
    )
  }
]))

// See https://en.wikipedia.org/wiki/INI_file#Format
class Ini {
  static parse(input) {

  }
}

class Section {
  // Params:
  // name: String
  construct new(name) {
    _name = name
    _properties = []
  }
  // Params:
  // name: String
  // properties: List<Property>
  construct new(name, properties) {
    _name = name
    _properties = properties
  }

  name { _name }
  name=(value) { _name = value }
  properties { _properties }
  properties=(value) { _properties = value }
}

class Property {
  // Params:
  // name: String
  // value: String
  construct new(name, value) {
    _name = name
    _value = value
  }

  // Type: String
  name { _name }
  // ditto
  name=(v) { _name = v }
  // Type: String
  value { _value }
  // ditto
  value=(v) { _value = v }
}
