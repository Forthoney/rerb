# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'

buffer = Parser::Source::Buffer.new('(buffer)')
buffer.source = '<div class="container"><%= value -%></div>'
parser = BetterHtml::Parser.new(buffer)

puts parser.inspect
# => #<BetterHtml::Parser ast=s(:document,
#   s(:tag, nil,
#     s(:tag_name, "div"), nil, nil),
#   s(:text,
#     s(:erb,
#       s(:indicator, "="), nil,
#       s(:code, " value "),
#       s(:trim))),
#   s(:tag,
#     s(:solidus),
#     s(:tag_name, "div"), nil, nil))>
