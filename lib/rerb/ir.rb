# frozen_string_literal: true

module RERB
  # Intermediate Representation Nodes
  module IR
    # Generic HTML Content
    Content = Data.define(:content)
    # Ruby expression. Analogous to <%= %>
    RubyExpr = Data.define(:content)
    # Ruby statement.  Analogous to <% %>
    RubyStatement = Data.define(:content)
    # Create DOM Node
    Create = Data.define(:el_name, :content)
    Ignore = Data.define

    class RawDOMOperationExporter
      def initialize; end

      def ir_to_s(elem, frame_name, interpolate: false)
        case elem
        in IR::Create(el_name, content)
          content.to_s + "#{frame_name}.appendChild(#{el_name})\n"
        in IR::Content(content)
          content.to_s
        in IR::RubyStatement(content)
          content.to_s
        in IR::RubyExpr(content)
          interpolate ? "\#{#{content}}" : content.to_s
        in IR::Ignore
          ""
        end
      end

      def child_ir_to_s(child, frame_name)
        case child
        in IR::RubyStatement(content)
          "#{content}\n"
        in IR::Ignore
          ""
        in IR::Content(content)
          %(#{frame_name}.appendChild(document.createTextNode("#{content}"))\n)
        in IR::RubyExpr(content)
          %(#{frame_name}.appendChild(document.createTextNode("\#{#{content}}"))\n)
        end
      end
    end
  end
end
