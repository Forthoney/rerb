# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "lib" # Directory name
  # library "better_html" # better_html does not have RBS yet

  configure_code_diagnostics(D::Ruby.default) # `default` diagnostics setting (applies by default)
end

# target :test do
#   signature "sig", "sig-private"
#
#   check "test"
#
#   # library "pathname"              # Standard libraries
# end
