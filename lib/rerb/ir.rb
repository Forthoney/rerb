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
        in Create(el_name, parent_name, tag_type, attributes)
          "#{el_name} = document.createElement('#{ir_to_s(tag_type)}')\n" +
            ir_to_s(attributes) + "#{parent_name}.appendChild(#{el_name})\n"
        in Container(frame)
          frame.elems.map { |e| ir_to_s(e, interpolate:) }.join
        in InterpolateContainer(frame)
          frame.elems.map { |e| ir_to_s(e, interpolate: true) }.join
        in TextContainer(frame)
          frame.elems.map do |c|
            child_ir_to_s(c, frame.name)
          end.join
        in RubyStatement(code)
          ir_to_s(code) + "\n"
        in RubyExpr(code)
          interpolate ? "\#{#{ir_to_s(code)}}" : ir_to_s(code)
        in Attribute(target, name, value)
          attr_name = ir_to_s(name)
          if attr_name[0...2] == "on" # Event
            attr_value = ir_to_s(value, interpolate: false)
            %(#{target}.addEventListener("#{attr_name[2...]}", #{attr_value})\n)
          elsif value.is_a?(Ignore) # Boolean attribute
            %(#{target}.setAttribute("#{attr_name}", true)\n)
          else # Standard attribute
            attr_value = ir_to_s(value, interpolate: true)
            %(#{target}.setAttribute("#{attr_name}", "#{attr_value}")\n)
          end
        in Ignore
          +""
        in Text(content)
          content.strip
        end
      end

      def child_ir_to_s(child, frame_name)
        case child
        in RubyStatement(content)
          "#{content.strip}\n"
        in Text(content)
          %(#{frame_name}.appendChild(document.createTextNode("#{content}"))\n)
        in RubyExpr(content)
          %(#{frame_name}.appendChild(document.createTextNode("\#{#{content.strip}}"))\n)
        in Ignore
          ""
        end
      end
    end
  end
end
