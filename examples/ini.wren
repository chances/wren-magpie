import "./../magpie" for Magpie, Result

var comment = Magpie.sequence([
  Magpie.optional(Magpie.linefeed),
  Magpie.str(";"),
  Magpie.charFrom(Magpie.ascii),
  Magpie.optional(Magpie.linefeed),
])

static var Parser = Magpie.zeroOrMore(Magpie.sequence([
  Magpie.zeroOrMore(comment),
  // Section
  Magpie.one(Magpie.sequence([
    Magpie.str("["),
    Magpie.ascii("]"),
    Magpie.str("]")
  ])),
  Magpie.zeroOrMore(comment),
  // Properties
  // TODO: Implement parameter parser
]))

// See https://en.wikipedia.org/wiki/INI_file#Format
class Ini {
  static parse(input) {

  }
}

class Section {
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
