# frozen_string_literal: true

module RERB
  # Intermediate Representation Nodes
  module IR
    Container = Data.define(:frame)
    InterpolateContainer = Data.define(:frame)
    TextContainer = Data.define(:frame)
    Attribute = Data.define(:target, :name, :value)
    # Ruby expression. Analogous to <%= %>
    RubyExpr = Data.define(:code)
    # Ruby statement.  Analogous to <% %>
    RubyStatement = Data.define(:code)
    # Create DOM Node
    Create = Data.define(:el_name, :parent_name, :tag_type, :attributes)
    Text = Data.define(:content)
    Ignore = Data.define

    class RawDOMOperationExporter
      def initialize; end

      def ir_to_s(elem, interpolate: false)
        case elem
        in Create(el_name:, parent_name:, tag_type:, attributes:)
          "#{el_name} = document.createElement('#{ir_to_s(tag_type)}')\n" +
            ir_to_s(attributes) + "#{parent_name}.appendChild(#{el_name})\n"

        in Container(frame:)
          frame.elems.map { |e| ir_to_s(e, interpolate:) }.join

        in InterpolateContainer(frame:)
          frame.elems.map { |e| ir_to_s(e, interpolate: true) }.join

        in TextContainer(frame:)
          frame.elems.map { |e| text_ir_to_s(e, frame.name) }.join

        in RubyStatement(code:)
          ir_to_s(code) + "\n"

        in RubyExpr(code:)
          interpolate ? "\#{#{ir_to_s(code)}}" : ir_to_s(code)

        in Attribute(target:, name:, value: Ignore) # Boolean attribute
          %(#{target}.setAttribute("#{ir_to_s(name)}", true)\n)

        in Attribute(target:, name:, value:)
          attr_ir_to_s(target, name, value)

        in Text(content:)
          content.strip

        in Ignore
          +""
        end
      end

      private

      def text_ir_to_s(ir, frame_name)
        result = ir_to_s(ir, interpolate: true)
        case ir
        when Text, RubyExpr
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
