# frozen_string_literal: true

module WERB
  class DomElem
    ERB = Data.define(:content)
    Container = Data.define(:content)
    Code = Data.define(:content)
    Str = Data.define(:content)
    Creator = Data.define(:el_name, :content)
  end
end
