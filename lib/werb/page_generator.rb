# frozen_string_literal: true

require 'erb'

require 'werb'
require 'werb/compiler'

module WERB
  module PageGenerator
    TEMPLATE = %(
    <html>
      <head>
        <script src="https://cdn.jsdelivr.net/npm/ruby-head-wasm-wasi@2.1.0/dist/browser.script.iife.js"></script>
        <script type="text/ruby">
          <%= content %>
        </script>
      </head>
      <body>
        <div id=<%= root_name %>></div>
      </body>
    </html>
    ).gsub(/^ /, '')

    def self.generate_html_page(input_file, doc_name, root_name, el_name_prefix)
      content = WERB::Compiler.new(File.read(input_file), doc_name, root_name, el_name_prefix)
      rhtml = ERB.new(PageGenerator::TEMPLATE)
      p rhtml.run(binding)
    end
  end
end
