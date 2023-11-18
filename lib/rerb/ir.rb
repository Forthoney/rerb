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
  end
end
