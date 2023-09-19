# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'

buffer = Parser::Source::Buffer.new('(buffer)')
buffer.source = '<div class="container"><%= value -%></div>'
parser = BetterHtml::Parser.new(buffer)

puts parser.inspect
