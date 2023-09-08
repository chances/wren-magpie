import "wren-package" for WrenPackage, Dependency

class Package is WrenPackage {
  construct new() {}
  name { "wren-test-runner" }
  dependencies {
    return [
      Dependency.new("wren-assert", "v1.1.2", "https://github.com/RobLoach/wren-assert.git")
    ]
  }
}

Package.new().default()
