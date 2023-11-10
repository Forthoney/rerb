# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'
require 'better_html/tree/tag'

require 'werb'

module WERB
  # Compile ERB into ruby.wasm compatible code
  class Compiler
    Frame = Data.define(:name, :elems) do
      # Frame is initialized with an empty array for its elems
      def initialize(name:, elems: [])
        super(name:, elems:)
      end
    end

    DOMContent = Data.define(:content)
    DOMRubyExpr = Data.define(:content)
    DOMRubyStatement = Data.define(:content)
    DOMCreate = Data.define(:el_name, :content)
    DOMIgnore = Data.define

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
      dom_to_str(compile_ast(@parser.ast)).strip
    end

    private

    def create_parser(source)
      buffer = Parser::Source::Buffer.new('(buffer)', source:)
      BetterHtml::Parser.new(buffer)
    end

    def compile_ast(node)
      case node
      in nil | [:quote, *]
        DOMIgnore[]

      in String
        DOMContent[node]

      in [:erb, nil, start_trim, code, end_trim] # ERB statement
        DOMRubyStatement[dom_to_str(compile_ast(code)).strip.to_s]

      in [:erb, _ind, start_trim, code, end_trim] # ERB expression
        DOMRubyExpr[dom_to_str(compile_ast(code)).strip.to_s]

      in [:tag, nil, tag_name, tag_attr, _solidus] # Opening tag
        el_name = generate_el_name
        @frames.push(Frame[el_name])
        name = dom_to_str(compile_ast(tag_name))
        attrs = dom_to_str(compile_ast(tag_attr))
        DOMCreate[el_name, "#{el_name} = document.createElement('#{name}')\n#{attrs}"]

      in [:tag, _start_solidus, _tag_name, _tag_attr, _solidus] # Closing tag
        DOMContent[collect_frame(@frames.pop)]

      in [:attribute, attr_name, _eql_token, attr_value] # Attribute
        name = dom_to_str(compile_ast(attr_name))
        if name[0...2] == 'on'
          value = dom_to_str(compile_ast(attr_value), interpolate: false)
          DOMContent[%(#{current_frame.name}.addEventListener("#{name[2...]}", #{value})\n)]
        else
          value = dom_to_str(compile_ast(attr_value), interpolate: true)
          DOMContent[%(#{current_frame.name}.setAttribute("#{name}", "#{value}")\n)]
        end

      in [:code, code]
        DOMContent["#{code.strip}\n"]

      in [:text, *children]
        DOMContent[join_text_children(children)]

      in [:document, *] |
         [:attribute_value, *] |
         [:tag_attributes, *]
        DOMContent[collect_children(node.children, interpolate: false)]

      in [:attribute_name, *] |
         [:tag_name, *]
        DOMContent[collect_children(node.children, interpolate: true)]
      end
    end

    def join_text_children(children)
      f_name = current_frame.name
      children.compact.map do |c|
        case compile_ast(c)
        in DOMRubyStatement(content)
          "#{content}\n"
        in DOMIgnore
          ''
        in DOMContent(content)
          %(#{f_name}[:innerText] = #{f_name}[:innerText].to_s + "#{content}"\n)
        in DOMRubyExpr(content)
          %(#{f_name}[:innerText] = #{f_name}[:innerText].to_s + "\#{#{content}}"\n)
        end
      end.join
    end

    def dom_to_str(elem, interpolate: false)
      case elem
      in DOMCreate(el_name, content)
        content.to_s + "#{current_frame.name}.appendChild(#{el_name})\n"
      in DOMContent(content)
        content.to_s
      in DOMRubyStatement(content)
        content.to_s
      in DOMRubyExpr(content)
        interpolate ? "\#{#{content}}" : content.to_s
      in DOMIgnore
        ''
      end
    end

    def collect_frame(frame, interpolate: false)
      frame.elems.map { |e| dom_to_str(e, interpolate:) }.join
    end

    def collect_children(children, interpolate: false)
      @frames.push(Frame[current_frame.name])

      children.compact.each do |n|
        # compile_ast must be evaluated BEFORE current_frame because current_frame
        # must be reflective of the current frame after whatever mutations compile_ast did
        compiled = compile_ast(n)
        current_frame.elems.push(compiled)
      end

      collect_frame(@frames.pop, interpolate:)
    end

    def current_frame
      @frames.last or raise EmptyFrameError
    end

    def generate_el_name
      @counter += 1
      "#{@el_name_prefix}#{@counter}"
    end
  end
end
