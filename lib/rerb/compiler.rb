# frozen_string_literal: true

require "better_html"
require "better_html/parser"
require "better_html/tree/tag"

require "rerb"
require "rerb/ir"
require "rerb/ir_exporter"

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
      @exporter = IRExporter::DOMOperationExporter.new
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
      @exporter.ir_to_s(node_to_ir(@parser.ast)).strip
    end

    private

    def node_to_ir(node)
      # Unfortunately, this very ugly pattern matching is the only way to
      # pattern match the AST::Nodes from better-html
      case node
      in nil | [:quote, *]
        IR::Ignore[]

      in String
        node.strip.empty? ? IR::Ignore[] : IR::Text[node]

      in [:code, code]
        IR::Text[code]

      in [:erb, nil, _start_trim, code, _end_trim] # ERB statement
        IR::RubyStatement[node_to_ir(code)]

      in [:erb, _ind, _start_trim, code, _end_trim] # ERB expression
        IR::RubyExpr[node_to_ir(code)]

      in [:tag, nil, tag_name, tag_attr, _end_solidus] # Opening tag
        tag_type = tag_name.children[0]
        el_name = generate_el_name(tag_type)
        parent_name = current_frame.name
        @frames << Frame[el_name]
        create = IR::Create[el_name, parent_name, node_to_ir(tag_name), node_to_ir(tag_attr)]
        return create unless SELF_CLOSING_TAGS.include?(tag_type)

        current_frame.elems << create
        IR::Container[@frames.pop]

      in [:tag, _start_solidus, _tag_name, _tag_attr, _end_solidus] # Closing tag
        IR::Container[@frames.pop]

      in [:attribute, attr_name, _eql_token, attr_value] # Attribute
        IR::Attribute[current_frame.name, node_to_ir(attr_name), node_to_ir(attr_value)]

      in [:attribute_value, _start_quote, value, _end_quote]
        node_to_ir(value)

      in [:attribute_name, *] | [:tag_name, *]
        IR::InterpolateContainer[collect_children(node.children)]

      in [:text, *children]
        IR::TextContainer[collect_children(children)]

      in [:document, *] | [:tag_attributes, *]
        IR::Container[collect_children(node.children)]
      end
    end

    def create_parser(source)
      buffer = Parser::Source::Buffer.new("(buffer)", source:)
      BetterHtml::Parser.new(buffer)
    end

    def collect_children(children, interpolate: false)
      @frames << Frame[current_frame.name]

      children.compact.each do |n|
        # node_to_ir must be evaluated BEFORE current_frame because current_frame
        # must be reflective of the current frame after whatever mutations node_to_ir did
        compiled = node_to_ir(n)
        current_frame.elems << compiled
      end

      @frames.pop
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
