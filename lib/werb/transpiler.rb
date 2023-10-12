# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'
require 'better_html/tree/tag'

require 'werb'
require 'werb/dom_elem'

module WERB
  # Stack Frame Class
  class Frame
    attr_reader :name, :elems

    def initialize(name)
      @name = name
      @elems = []
    end

    def push!(elem)
      @elems = @elems << elem
      nil
    end
  end

  # Compile ERB into ruby.wasm compatible code
  class Transpiler
    def initialize(source,
                   document_name = 'document',
                   root_elem_name = 'root',
                   el_name_prefix = '@el')
      @counter = 0
      @parser = create_parser(source)
      @document_name = document_name
      @el_name_prefix = el_name_prefix
      @frames = [Frame.new(root_elem_name)]
    end

    def transpile
      transpile_ast(@parser.ast).content
    end

    private

    def create_parser(source)
      buffer = Parser::Source::Buffer.new('(buffer)', source:)
      BetterHtml::Parser.new(buffer)
    end

    def collect_result
      frame = @frames.pop
      raise StandardError, 'No frames to pop' if frame.nil?

      frame.elems.reduce('') do |acc, elem|
        case elem
        in DomElem::Str | DomElem::ERB | DomElem::Code | DomElem::Container
          "#{acc}#{elem.content}"
        in DomElem::Creator(el_name, content)
          "#{acc}#{content}#{current_frame.name}.appendChild(#{el_name})\n"
        else
          raise StandardError, "\n#{elem} cannot be parsed.\nCurrent frame: #{frame}"
        end
      end
    end

    def transpile_ast(node)
      return DomElem::Str[add_to_inner_text(node)] if node.is_a?(String)

      case node.type
      when :tag
        tag_to_dom(node)
      when :text, :document
        container_to_dom(node)
      when :erb
        erb_to_dom(node)
      when :code
        CodeElem["#{unpack_code(node)}\n"]
      else
        raise StandardError, 'Failed to transpile'
      end
    end

    def erb_to_dom(node)
      case node.children
      in [nil, _, _code, _]
        container_to_dom(node)
      in [_indicator, _, code, _]
        DomElem::ERB[add_to_inner_text("\#{#{unpack_code(code)}}")]
      else
        raise StandardError
      end
    end

    def container_to_dom(node)
      @frames = append_new_frame(current_frame.name)
      node.children.filter { |i| !i.nil? }.each do |n|
        transpiled = transpile_ast(n)
        current_frame.push!(transpiled)
      end
      DomElem::Container[collect_result]
    end

    def tag_to_dom(node)
      tag = BetterHtml::Tree::Tag.from_node(node)
      if tag.closing?
        DomElem::Container[collect_result]
      else
        el_name = generate_el_name
        @frames = append_new_frame(el_name)

        attr_list = node.children[2]
        attr_str = extract_attributes(attr_list, el_name)

        DomElem::Creator[el_name, "#{el_name} = #{@document_name}.createElement('#{tag.name}')\n#{attr_str}"]
      end
    end

    def extract_attributes(node, el_name)
      return '' if node.nil?

      node.children.filter { |i| !i.nil? }.reduce('') do |acc, attr|
        # TODO: Instead of using Attribute#from_node, need to manually decompose the value
        # This is needed for proper code interpolation
        attr = BetterHtml::Tree::Attribute.from_node(attr)
        if attr.name[0...2] == 'on'
          "#{acc}#{el_name}.addEventListener('#{attr.name[2...]}', '#{attr.value}')\n"
        else
          "#{acc}#{el_name}.setAttribute('#{attr.name}', '#{attr.value}')\n"
        end
      end
    end

    def append_new_frame(name)
      @frames << Frame.new(name)
    end

    def current_frame
      frame = @frames.last
      raise StandardError, 'Frames list is empty' if frame.nil?

      frame
    end

    def generate_el_name
      @counter += 1
      "#{@el_name_prefix}#{@counter}"
    end

    def unpack_code(block)
      block.children[0].strip
    end

    def add_to_inner_text(elem)
      "#{current_frame.name}[:innerText] = #{current_frame.name}[:innerText].to_s + \"#{elem}\"\n"
    end
  end
end
