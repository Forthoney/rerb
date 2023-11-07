# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'
require 'better_html/tree/tag'

require 'werb'
require 'werb/dom_elem'

module WERB
  Frame = Data.define(:name, :elems) do
    # Frame is initialized with an empty array for its elems
    def initialize(name:, elems: [])
      super(name:, elems:)
    end
  end

  # Compile ERB into ruby.wasm compatible code
  class Compiler
    def initialize(source, viewmodel_name,
                   root_elem_name = 'root',
                   el_name_prefix = 'el')
      @counter = 0
      @parser = create_parser(source)
      @viewmodel_name = viewmodel_name
      @el_name_prefix = "@#{el_name_prefix}"
      @root_elem_name = root_elem_name
      @frames = [Frame[root_elem_name]]
    end

    def compile
      <<~RESULT.chomp
        class #{@viewmodel_name}
          def initialize
            setup_dom
          end

          private

          def setup_dom
        #{compile_body.gsub(/^/, "  " * 2)}
          end

          def document
            JS.global[:document]
          end

          def root
            document.getElementById("#{@root_elem_name}")
          end
        end
      RESULT
    end

    def compile_body
      compile_ast(@parser.ast).content.strip
    end

    private

    def create_parser(source)
      buffer = Parser::Source::Buffer.new('(buffer)', source:)
      BetterHtml::Parser.new(buffer)
    end

    def compile_ast(node)
      if node.is_a?(String)
        return node.strip.empty? ? DomElem::Ignore[] : DomElem::Str[add_to_inner_text(node)]
      end

      case node.type
      when :tag, :erb, :code, :attribute
        send("#{node.type}_to_dom", node)
      when :text, :document, :tag_attributes
        container_to_dom(node)
      when :tag_name
        # tag_name is handled by better_html library call
        DomElem::Ignore[]
      else
        raise PatternMatchError, "#{node} has unexpected type :#{node.type}"
      end
    end

    def compile_dom_elem(frame)
      raise EmptyFrameError if frame.nil?

      frame.elems.reduce('') do |acc, elem|
        case elem
        when DomElem::Str, DomElem::ERB, DomElem::Code, DomElem::Container, DomElem::Attr
          acc + elem.content.to_s
        when DomElem::Creator
          acc + elem.content.to_s + "#{current_frame.name}.appendChild(#{elem.el_name})\n"
        when DomElem::Ignore
          acc
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

        attributes = container_to_dom(node).content
        DomElem::Creator[el_name, "#{el_name} = document.createElement('#{tag.name}')\n#{attributes}"]
      end
    end

    def attribute_to_dom(node)
      attr_name, _equal, attr_val = node.children
      attr_name = attr_name.children[0]
      case attr_val.children
      in [_quote, text, _quote]
        attr_val = "'#{text}'"
      in [erb]
        attr_val = compile_ast(erb.children[2]).content.strip
      else
        raise PatternMatchError, "Unexpected attribute values #{attr_val.children}"
      end

      if attr_name[0...2] == 'on'
        DomElem::Attr["#{current_frame.name}.addEventListener('#{attr_name[2...]}', #{attr_val})\n"]
      else
        DomElem::Attr["#{current_frame.name}.setAttribute('#{attr_name}', #{attr_val})\n"]
      end
    end

    def code_to_dom(node)
      code_block = node.children[0]
      raise Error, "Code block contains unexpected child #{code_block}" unless code_block.is_a? String

      DomElem::Code["#{code_block.strip}\n"]
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
