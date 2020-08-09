require "asciidoctor"
require "./lib/html5_converter.rb"

Asciidoctor.convert_file './index.adoc',
  to_file: './build/index.html',
  sourcemap: false,
  mkdirs: 'build',
  safe: 'safe',
  backend: 'html'
