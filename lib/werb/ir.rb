# frozen_string_literal: true

module WERB
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
  end
end
