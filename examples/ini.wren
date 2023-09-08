import "./../magpie" for Char, Magpie, ParserFn, Result

// See https://en.wikipedia.org/wiki/INI_file#Format
class Ini {
  construct new() {
    _sections = []
  }
  construct new(sections) {
    _sections = sections
  }

  sections { _sections }

  static parse(input) {
    return Ini.new(Magpie.parse(Ini.parser, input).token)
  }

  static whitespace { Magpie.zeroOrMore(Magpie.whitespace(Char.lineEndings)).join }

  static comment {
    return Magpie.sequence([
      Ini.whitespace,
      Magpie.char(";").discard,
      Ini.whitespace,
      // Read any ASCII character until an ASCII line ending
      Magpie.zeroOrMore(Magpie.ascii(Char.asciiLineEndings)).join.tag("comment"),
      Magpie.optional(Magpie.linefeed).discard
    ]).map {|result| result.where {|token| token.tag == "comment" }.toList[0] }.map {|result|
      return result.token.trim()
    }
  }

  static sectionName {
    var closingSquareBracket = "]".codePoints[0]
    var chars = (0..Char.asciiMax).toList.where {|x| x != closingSquareBracket }
    return Magpie.oneOrMore(Magpie.or(chars.map {|char| Magpie.char(char) }.toList)).join
  }

  static propertyName {
    var exclusions = Char.asciiLineEndings
    exclusions.addAll("=".codePoints)
    return Magpie.oneOrMore(Magpie.ascii(exclusions)).join
  }

  static parser {
    return Magpie.sequence([
      Magpie.zeroOrMore(comment),
      // Section
      Magpie.sequence([
        Magpie.char("["),
        sectionName,
        Magpie.char("]")
      ]).rewrite {|results| Section.new(results[1].token)}.tag("section"),
      Ini.whitespace.discard,
      Magpie.optional(comment.discard),
      Magpie.linefeed.discard,
      Magpie.optional(comment.discard),
      // Properties
      Magpie.zeroOrMore(Magpie.sequence([
        Ini.whitespace,
        Ini.propertyName.tag("name"),
        Ini.whitespace,
        Magpie.char("="),
        Ini.whitespace,
        Magpie.oneOrMore(Magpie.ascii(Char.asciiLineEndings)).join.tag("value"),
        Magpie.zeroOrMore(comment)
      ])).rewrite {|results|
        // FIXME: This only ever reads one property
        results = results.where {|token| token.tag != null }.toList
        return Property.new(results[0].lexeme, results[1].lexeme)
      }
    ]).rewrite {|results|
      var sectionsAndProps = results.map {|result| result.token }.toList
      var sections = []
      for (it in sectionsAndProps) {
        if (it is Section) sections.add(it)
        if (it is Property) sections[-1].properties.add(it)
      }
      return sections
    }
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
  construct new(name) {
    _name = name
  }
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
