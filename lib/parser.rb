# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'
require 'better_html/tree/tag'

class Transpiler
  def initialize(source)
    @counter = 0
    @parser = create_parser(source)
  end

  def transpile
    parse_ast(@parser.ast)
  end

  private

  def create_parser(source)
    template = File.open(source).read
    buffer = Parser::Source::Buffer.new('(buffer)')
    buffer.source = template
    BetterHtml::Parser.new(buffer)
  end

  def parse_ast(ast)
    content = []
    result = ''
    ast.children.each do |node|
      case extract_node_type(node)
      when :string
        result += "#{html_el_name}[:innerText] += #{node}\n"
      when :closing_tag
        result += content.reduce('') { |acc, c| acc + parse_ast(c) }
        content = []
      when :opening_tag
        @counter += 1
        tag = BetterHtml::Tree::Tag.from_node(node)
        result += "#{html_el_name} = doc.createElement('#{tag.name}')\n"
      else
        content << node
      end
    end
    result
  end

  def extract_node_type(node)
    if node.is_a? String
      :string
    elsif node.type == :tag
      tag = BetterHtml::Tree::Tag.from_node(node)
      tag.closing? ? :closing_tag : :opening_tag
    else
      :generic
    end
  end

  def html_el_name
    "@el#{@counter}"
  end
end

transpiler = Transpiler.new('todo_small.rhtml')
puts transpiler.transpile
