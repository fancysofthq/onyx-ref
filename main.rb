require "asciidoctor"

require "./lib/html5_converter.rb"
require "./lib/conum_macro.rb"

Asciidoctor.convert_file './doc/README.adoc',
  to_file: './build/index.html',
  sourcemap: false,
  mkdirs: 'build',
  safe: 'unsafe',
  backend: 'html'
