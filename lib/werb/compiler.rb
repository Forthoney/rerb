# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'
require 'better_html/tree/tag'

require 'werb'
require 'werb/ir'

module WERB
  # Compile ERB into ruby.wasm compatible code
  class Compiler
    SELF_CLOSING_TAGS = %w[area base br col
                           embed hr img input
                           link meta param
                           source track wbr].freeze

    Frame = Data.define(:name, :elems) do
      # Frame is initialized with an empty array for its elems
      def initialize(name:, elems: [])
        super(name:, elems:)
      end
    end

    def initialize(source, viewmodel_name, root_elem_name = 'root')
      @counter = 0
      @parser = create_parser(source)
      @viewmodel_name = viewmodel_name
      @name_hash = Hash.new { |h, k| h[k] = 0 }
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

        #{@viewmodel_name}.new
      RESULT
    end

    def compile_body
      dom_to_str(compile_ast(@parser.ast)).strip
    end

    private

    def create_parser(source)
      buffer = Parser::Source::Buffer.new('(buffer)', source:)
      BetterHtml::Parser.new(buffer)
    end

    # Unfortunately, this very ugly pattern matching is the only way to
    # pattern match the AST::Nodes from better-html
    def compile_ast(node)
      case node
      in nil | [:quote, *]
        IR::Ignore[]

      in String
        node.strip.empty? ? IR::Ignore[] : IR::Content[node.strip]

      in [:erb, nil, start_trim, code, end_trim] # ERB statement
        IR::RubyStatement[dom_to_str(compile_ast(code)).strip.to_s]

      in [:erb, _ind, start_trim, code, end_trim] # ERB expression
        IR::RubyExpr[dom_to_str(compile_ast(code)).strip.to_s]

      in [:tag, nil, tag_name, tag_attr, _solidus] # Opening tag
        tag_type = dom_to_str(compile_ast(tag_name))
        el_name = generate_el_name(tag_type)
        @frames << Frame[el_name]
        attrs = dom_to_str(compile_ast(tag_attr))

        create = IR::Create[el_name, "#{el_name} = document.createElement('#{tag_type}')\n#{attrs}"]
        return create unless SELF_CLOSING_TAGS.include? tag_type

        current_frame.elems << create
        IR::Content[collect_frame(@frames.pop)]

      in [:tag, _start_solidus, _tag_name, _tag_attr, _solidus] # Closing tag
        IR::Content[collect_frame(@frames.pop)]

      in [:attribute, attr_name, _eql_token, attr_value] # Attribute
        name = dom_to_str(compile_ast(attr_name))
        if name[0...2] == 'on' # Event
          value = dom_to_str(compile_ast(attr_value), interpolate: false)
          IR::Content[%(#{current_frame.name}.addEventListener("#{name[2...]}", #{value})\n)]
        elsif attr_value.nil? # Boolean attribute
          IR::Content[%(#{current_frame.name}.setAttribute("#{name}", true)\n)]
        else
          value = dom_to_str(compile_ast(attr_value), interpolate: true)
          IR::Content[%(#{current_frame.name}.setAttribute("#{name}", "#{value}")\n)]
        end

      in [:code, code]
        IR::Content["#{code.strip}\n"]

      in [:text, *children]
        IR::Content[join_text_children(children)]

      in [:document, *] |
         [:attribute_value, *] |
         [:tag_attributes, *]
        IR::Content[collect_children(node.children, interpolate: false)]

      in [:attribute_name, *] |
         [:tag_name, *]
        IR::Content[collect_children(node.children, interpolate: true)]
      end
    end

    def join_text_children(children)
      f_name = current_frame.name
      children.compact.map do |c|
        case compile_ast(c)
        in IR::RubyStatement(content)
          "#{content}\n"
        in IR::Ignore
          ''
        in IR::Content(content)
          %(#{f_name}.appendChild(document.createTextNode("#{content}"))\n)
        in IR::RubyExpr(content)
          %(#{f_name}.appendChild(document.createTextNode("\#{#{content}}"))\n)
        end
      end.join
    end

    def dom_to_str(elem, interpolate: false)
      case elem
      in IR::Create(el_name, content)
        content.to_s + "#{current_frame.name}.appendChild(#{el_name})\n"
      in IR::Content(content)
        content.to_s
      in IR::RubyStatement(content)
        content.to_s
      in IR::RubyExpr(content)
        interpolate ? "\#{#{content}}" : content.to_s
      in IR::Ignore
        ''
      end
    end

    def collect_frame(frame, interpolate: false)
      frame.elems.map { |e| dom_to_str(e, interpolate:) }.join
    end

    def collect_children(children, interpolate: false)
      @frames << Frame[current_frame.name]

      children.compact.each do |n|
        # compile_ast must be evaluated BEFORE current_frame because current_frame
        # must be reflective of the current frame after whatever mutations compile_ast did
        compiled = compile_ast(n)
        current_frame.elems << compiled
      end

      collect_frame(@frames.pop, interpolate:)
    end

    def current_frame
      @frames.last or raise EmptyFrameError
    end

    def generate_el_name(tag_type)
      @name_hash[tag_type] += 1
      "@#{tag_type}_#{@name_hash[tag_type]}"
    end
  end
end
