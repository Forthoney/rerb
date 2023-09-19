# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'
require 'better_html/tree/tag'

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
      transpile_ast(@parser.ast)[1]
    end

    private

    def current_frame
      frame = @frames.last
      raise StandardError, 'No Frames' if frame.nil?

      frame
    end

    def create_parser(source)
      buffer = Parser::Source::Buffer.new('(buffer)', source:)
      BetterHtml::Parser.new(buffer)
    end

    def collect_result
      frame = @frames.pop
      raise StandardError, 'No frames to pop' if frame.nil?

      frame.elems.reduce('') do |acc, elem|
        case elem
        in [:string | :erb | :container | :code, content]
          "#{acc}#{content}"
        in [el_name, content]
          "#{acc}#{content}#{current_frame.name}.appendChild(#{el_name})\n"
        else
          raise StandardError, "\n#{elem} cannot be parsed.\nCurrent frame: #{frame}"
        end
      end
    end

    def transpile_ast(node)
      return [:string, add_to_inner_text(node)] if node.is_a?(String)

      case node.type
      when :tag
        transpile_tag(node)
      when :text, :document
        transpile_container(node)
      when :erb
        transpile_erb(node)
      when :code
        [:code, "#{unpack_code(node)}\n"]
      else
        raise StandardError, 'Failed to transpile'
      end
    end

    def transpile_erb(node)
      case node.children
      in [nil, _, _code, _]
        transpile_container(node)
      in [_indicator, _, code, _]
        [:erb, add_to_inner_text("\#{#{unpack_code(code)}}")]
      else
        raise StandardError
      end
    end

    def transpile_container(node)
      add_new_frame!(current_frame.name)
      node.children.filter { |i| !i.nil? }.each do |n|
        transpiled = transpile_ast(n)
        current_frame.push!(transpiled)
      end
      [:container, collect_result]
    end

    def transpile_tag(node)
      tag = BetterHtml::Tree::Tag.from_node(node)
      if tag.closing?
        [:container, collect_result]
      else
        el_name = generate_el_name
        add_new_frame!(el_name)

        # better_html currently does not support reduce
        tag_str = ''
        tag.attributes.each do |attr|
          tag_str += "#{el_name}.setAttribute('#{attr.name}', '#{attr.value}')\n"
        end

        [el_name, "#{el_name} = #{@document_name}.createElement('#{tag.name}')\n#{tag_str}"]
      end
    end

    def add_new_frame!(name)
      @frames = @frames << Frame.new(name)
      nil
    end

    def generate_el_name
      @counter += 1
      "#{@el_name_prefix}#{@counter}"
    end

    def unpack_code(block)
      block.children[0].strip
    end

    def add_to_inner_text(elem)
      # Hack to get around the inability to do [:innerText] += "new text"
      "#{current_frame.name}[:innerText] = #{current_frame.name}[:innerText].to_s + \"#{elem}\"\n"
    end
  end
end
