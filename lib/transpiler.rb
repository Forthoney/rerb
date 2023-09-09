# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'
require 'better_html/tree/tag'

class Transpiler
  def initialize(source)
    @counter = 0
    @parser = create_parser(source)
    @frames = [{ name: '@document', elems: [] }]
  end

  def transpile
    transpile_ast(@parser.ast)
  end

  private

  def create_parser(source)
    template = File.open(source).read
    buffer = Parser::Source::Buffer.new('(buffer)')
    buffer.source = template
    BetterHtml::Parser.new(buffer)
  end

  def transpile_ast(ast)
    case extract_node_info(ast)
    in [:string, nil]
      ast
    in [:erb, _]
      transpile_erb(ast)
    in [:opening_tag, tag]
      "#{generate_frame} = doc.createElement('#{tag.name}')\n"
    in [:closing_tag, _]
      frame = pop_frame
      frame[:elems].reduce('') do |acc, elem|
        "#{acc}#{frame[:name]}.appendChild(#{elem})\n"
      end
    in [:container, _]
      content = ast.children.reduce('') { |acc, node| "#{acc}#{transpile_ast(node)}\n" }
      insert_into_frame(content)
    end
  end

  def extract_node_info(node)
    return [:string, nil] if node.is_a?(String)

    case node.type
    when :tag
      tag = BetterHtml::Tree::Tag.from_node(node)
      type = tag.closing? ? :closing_tag : :opening_tag
      [type, tag]
    when :text, :document
      [:container, nil]
    when :erb
      [:erb, nil]
    else
      raise ArgumentError
    end
  end

  def collect_child_result(content)
    content.reduce('') { |acc, c| acc + transpile_ast(c) }
  end

  def generate_frame
    @counter += 1
    frame = { name: "@el#{@counter}", elems: [] }
    @frames << frame
    frame[:name]
  end

  def pop_frame
    @frames.pop
  end

  def insert_into_frame(content)
    @frames.last[:elems] << content
  end

  def transpile_erb(erb)
    'erb'
  end
end

transpiler = Transpiler.new('todo_small.rhtml')
puts transpiler.transpile
