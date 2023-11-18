# frozen_string_literal: true

module RERB
  # Collection of export targets for IR
  module IRExporter
    # Export using Data#inspect
    class InspectExporter
      def initialize; end

      def ir_to_s(elem)
        elem.deconstruct.map(&:to_s).join
      end
    end

    # Export into valid ruby.wasm js interop DOM operations
    class DOMOperationExporter < InspectExporter
      def ir_to_s(elem, interpolate: false)
        case elem
        in IR::Create(el_name:, parent_name:, tag_type:, attributes:)
          "#{el_name} = document.createElement('#{ir_to_s(tag_type)}')\n" +
            ir_to_s(attributes) + "#{parent_name}.appendChild(#{el_name})\n"

        in IR::Container(frame:)
          frame.elems.map { |e| ir_to_s(e, interpolate:) }.join

        in IR::InterpolateContainer(frame:)
          frame.elems.map { |e| ir_to_s(e, interpolate: true) }.join

        in IR::TextContainer(frame:)
          frame.elems.map { |e| text_ir_to_s(e, frame.name) }.join

        in IR::RubyStatement(code:)
          ir_to_s(code) + "\n"

        in IR::RubyExpr(code:)
          interpolate ? "\#{#{ir_to_s(code)}}" : ir_to_s(code)

        in IR::Attribute(target:, name:, value: IR::Ignore) # Boolean attribute
          %(#{target}.setAttribute("#{ir_to_s(name)}", true)\n)

        in IR::Attribute(target:, name:, value:)
          attr_ir_to_s(target, name, value)

        in IR::Text(content:)
          content.strip

        in IR::Ignore
          +""
        end
      end

      private

      def text_ir_to_s(ir, frame_name)
        result = ir_to_s(ir, interpolate: true)
        case ir
        when IR::Text, IR::RubyExpr
          %(#{frame_name}.appendChild(document.createTextNode("#{result}"))\n)
        else
          result
        end
      end

      def attr_ir_to_s(target, name, value)
        attr_name = ir_to_s(name)
        if attr_name[0...2] == "on" # Event
          attr_value = ir_to_s(value, interpolate: false)
          %(#{target}.addEventListener("#{attr_name[2...]}", #{attr_value})\n)
        else # Standard attribute
          attr_value = ir_to_s(value, interpolate: true)
          %(#{target}.setAttribute("#{attr_name}", "#{attr_value}")\n)
        end
      end
    end
  end
end
