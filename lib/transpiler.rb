# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'
require 'better_html/tree/tag'

class Frame
  attr_reader :name, :elems

  def initialize(name)
    @name = name
    @elems = []
  end

  def push!(elem)
    @elems = @elems.push(elem)
    return
  end
end

class Transpiler
  def initialize(source)
    @counter = 0
    @parser = create_parser(source)
    @frames = [Frame.new('document')]
  end

  def transpile
    transpile_ast(@parser.ast)
  end

  private

  def current_frame
    @frames.last
  end

  def create_parser(source)
    template = File.open(source).read.delete("\n")
    buffer = Parser::Source::Buffer.new('(buffer)')
    buffer.source = template
    BetterHtml::Parser.new(buffer)
  end

  def transpile_ast(ast)
    case extract_node_info(ast)
    in [:string, nil]
      [:string, "#{current_frame.name}[:innerHTML] = #{ast}\n"]
    in [:erb, _]
      transpile_erb(ast)
    in [:opening_tag, tag]
      el_name = generate_el_name
      current_frame.push!([el_name, "#{el_name} = doc.createElement('#{tag.name}')\n"])
      add_new_frame(el_name)
      return
    in [:closing_tag, _]
      frame = @frames.pop
      collect_child_result(frame)
    in [:container, _]
      add_new_frame(current_frame.name)
      ast.children.each do |node|
        transpiled = transpile_ast(node)
        current_frame.push!(transpiled) unless transpiled.nil?
      end
      frame = @frames.pop
      collect_child_result(frame)
    else
      raise StandardError, "Failed to transpile"
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

  def collect_child_result(frame)
    result = frame.elems.reduce('') do |acc, elem|
      case elem
      in [:string, content]
        "#{acc}#{content}"
      in [:erb, content]
        "#{acc}#{content}"
      in [:container, content]
        "#{acc}#{content}"
      in [el_name, content]
        "#{acc}#{content}#{frame.name}.appendChild(#{el_name})\n"
      else
        raise StandardError, "\n#{elem} cannot be parsed.\nCurrent frames: #{@frames}"
      end
    end
    [:container, result]
  end

  def add_new_frame(name)
    @frames = @frames << Frame.new(name)
    return
  end

  def generate_el_name
    @counter += 1
    "@el#{@counter}"
  end

  def transpile_erb(erb)
    [:erb, "erb\n"]
  end
end

transpiler = Transpiler.new('todo_small.rhtml')
puts transpiler.transpile
