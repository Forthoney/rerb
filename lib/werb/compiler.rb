# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'
require 'better_html/tree/tag'

require 'werb'
require 'werb/dom_elem'

module WERB
  Frame = Data.define(:name, :elems) do
    def initialize(name:, elems: [])
      super(name:, elems:)
    end
  end

  # Compile ERB into ruby.wasm compatible code
  class Compiler
    def initialize(source,
                   document_name = 'document',
                   root_elem_name = 'root',
                   el_name_prefix = '@el')
      @counter = 0
      @parser = create_parser(source)
      @document_name = document_name
      @el_name_prefix = el_name_prefix
      @frames = [Frame[root_elem_name]]
    end

    def compile
      compile_ast(@parser.ast).content
    end

    private

    def create_parser(source)
      buffer = Parser::Source::Buffer.new('(buffer)', source:)
      BetterHtml::Parser.new(buffer)
    end

    def compile_ast(node)
      return DomElem::Str[add_to_inner_text(node)] if node.is_a?(String)

      case node.type
      when :tag, :erb, :code, :attribute
        send("#{node.type}_to_dom", node)
      when :text, :document
        container_to_dom(node)
      else
        raise PatternMatchError, "#{node} has unexpected type :#{node.type}"
      end
    end

    def compile_dom_elem(frame)
      raise EmptyFrameError if frame.nil?

      frame.elems.reduce('') do |acc, elem|
        case elem
        in DomElem::Str | DomElem::ERB | DomElem::Code | DomElem::Container
          acc + elem.content.to_s
        in DomElem::Creator(el_name, content)
          acc + content.to_s + "#{current_frame.name}.appendChild(#{el_name})\n"
        else
          raise PatternMatchError, "Element #{elem} cannot be parsed in current frame #{frame}"
        end
      end
    end

    def erb_to_dom(node)
      case node.children
      in [nil, nil, _code, nil]
        container_to_dom(node)
      in [_indicator, nil, code, nil]
        DomElem::ERB[add_to_inner_text("\#{#{compile_ast(code).content.strip}}")]
      else
        raise PatternMatchError, "#{node.children} has unexpected patter for ERB"
      end
    end

    def container_to_dom(node)
      @frames.push(Frame[current_frame.name])

      node.children.compact.each do |n|
        # compile_ast must be evaluated BEFORE current_frame because current_frame
        # must be reflective of the current frame after whatever mutations compile_ast did
        compiled = compile_ast(n)
        current_frame.elems.push(compiled)
      end

      DomElem::Container[compile_dom_elem(@frames.pop)]
    end

    def tag_to_dom(node)
      tag = BetterHtml::Tree::Tag.from_node(node)
      if tag.closing?
        DomElem::Container[compile_dom_elem(@frames.pop)]
      else
        el_name = generate_el_name
        @frames.push(Frame[el_name])

        attr_list = node.children[2]
        attr_str = extract_attributes(attr_list, el_name)

        DomElem::Creator[el_name, "#{el_name} = #{@document_name}.createElement('#{tag.name}')\n#{attr_str}"]
      end
    end

    def code_to_dom(node)
      code_block = node.children[0]
      raise Error, "Code block contains unexpected child #{code_block}" unless code_block.is_a? String

      DomElem::Code["#{code_block.strip}\n"]
    end

    def parse_attribute(node)
      attr_name, _equal, attr_val = node.children
      attr_name = attr_name.children[0]
      case attr_val.children
      in [_quote, text, _quote]
        attr_value = "'#{text}'"
      in [erb]
        attr_value = compile_ast(erb.children[2]).content.strip
      else
        raise PatternMatchError
      end

      if attr_name[0...2] == 'on'
        ".addEventListener('#{attr_name[2...]}', #{attr_value})\n"
      else
        ".setAttribute('#{attr_name}', #{attr_value})\n"
      end
    end

    def extract_attributes(node, el_name)
      return '' if node.nil?

      node.children.compact.reduce('') do |acc, attr|
        # TODO: Instead of using Attribute#from_node, need to manually decompose the value
        # This is needed for proper code interpolation
        acc + el_name + parse_attribute(attr)
      end
    end

    def current_frame
      @frames.last or raise EmptyFrameError
    end

    def generate_el_name
      @counter += 1
      "#{@el_name_prefix}#{@counter}"
    end

    def add_to_inner_text(elem)
      "#{current_frame.name}[:innerText] = #{current_frame.name}[:innerText].to_s + \"#{elem}\"\n"
    end
  end
end

WERB::Compiler.new("<h1>Hello World</h1>").compile
