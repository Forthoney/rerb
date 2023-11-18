# frozen_string_literal: true

require "better_html"
require "better_html/parser"
require "better_html/tree/tag"

require "rerb"
require "rerb/ir"

module RERB
  # Compile ERB into ruby.wasm compatible code
  class Compiler
    SELF_CLOSING_TAGS = [
      "area",
      "base",
      "br",
      "col",
      "embed",
      "hr",
      "img",
      "input",
      "link",
      "meta",
      "param",
      "source",
      "track",
      "wbr",
    ].freeze

    Frame = Data.define(:name, :elems) do
      # Frame is initialized with an empty array for its elems
      def initialize(name:, elems: [])
        super(name:, elems:)
      end
    end

    def initialize(source, viewmodel_name, root_elem_name = "root")
      @counter = 0
      @parser = create_parser(source)
      @viewmodel_name = viewmodel_name
      @name_hash = Hash.new { |h, k| h[k] = 0 }
      @root_elem_name = root_elem_name
      @frames = [Frame[root_elem_name]]
      @exporter = IR::RawDOMOperationExporter.new
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
      export(compile_node(@parser.ast)).strip
    end

    private

    def compile_node(node)
      # Unfortunately, this very ugly pattern matching is the only way to
      # pattern match the AST::Nodes from better-html
      case node
      in nil | [:quote, *]
        IR::Ignore[]

      in String
        node.strip.empty? ? IR::Ignore[] : IR::Content[node.strip]

      in [:erb, nil, _start_trim, code, _end_trim] # ERB statement
        IR::RubyStatement[export(compile_node(code)).strip.to_s]

      in [:erb, _ind, _start_trim, code, _end_trim] # ERB expression
        IR::RubyExpr[export(compile_node(code)).strip.to_s]

      in [:tag, nil, tag_name, tag_attr, _end_solidus] # Opening tag
        tag_type = export(compile_node(tag_name))
        el_name = generate_el_name(tag_type)
        @frames << Frame[el_name]
        attrs = export(compile_node(tag_attr))

        create = IR::Create[el_name, "#{el_name} = document.createElement('#{tag_type}')\n#{attrs}"]
        return create unless SELF_CLOSING_TAGS.include?(tag_type)

        current_frame.elems << create
        IR::Content[collect_frame(@frames.pop)]

      in [:tag, _start_solidus, _tag_name, _tag_attr, _end_solidus] # Closing tag
        IR::Content[collect_frame(@frames.pop)]

      in [:attribute, attr_name, _eql_token, attr_value] # Attribute
        name = export(compile_node(attr_name))
        if name[0...2] == "on" # Event
          value = export(compile_node(attr_value), interpolate: false)
          IR::Content[%(#{current_frame.name}.addEventListener("#{name[2...]}", #{value})\n)]
        elsif attr_value.nil? # Boolean attribute
          IR::Content[%(#{current_frame.name}.setAttribute("#{name}", true)\n)]
        else
          value = export(compile_node(attr_value), interpolate: true)
          IR::Content[%(#{current_frame.name}.setAttribute("#{name}", "#{value}")\n)]
        end

      in [:attribute_value, _start_quote, value, _end_quote]
        compile_node(value)

      in [:code, code]
        IR::Content["#{code.strip}\n"]

      in [:text, *children]
        IR::Content[collect_text_children(children)]

      in [:document, *] | [:tag_attributes, *]
        IR::Content[collect_children(node.children, interpolate: false)]

      in [:attribute_name, *] | [:tag_name, *]
        IR::Content[collect_children(node.children, interpolate: true)]
      end
    end

    def create_parser(source)
      buffer = Parser::Source::Buffer.new("(buffer)", source:)
      BetterHtml::Parser.new(buffer)
    end

    def collect_frame(frame, interpolate: false)
      frame.elems.map { |e| export(e, interpolate:) }.join
    end

    def collect_children(children, interpolate: false)
      @frames << Frame[current_frame.name]

      children.compact.each do |n|
        # compile_node must be evaluated BEFORE current_frame because current_frame
        # must be reflective of the current frame after whatever mutations compile_node did
        compiled = compile_node(n)
        current_frame.elems << compiled
      end

      collect_frame(@frames.pop, interpolate:)
    end

    def collect_text_children(children)
      children.compact.map do |c|
        @exporter.child_ir_to_s(compile_node(c), current_frame.name)
      end.join
    end

    def export(target, interpolate: false)
      @exporter.ir_to_s(target, current_frame.name, interpolate:)
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
