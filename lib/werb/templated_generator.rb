# frozen_string_literal: true

require 'erb'

require 'werb'
require 'werb/compiler'

module WERB
  class TemplatedGenerator
    TEMPLATE = '<%= content %>'

    def initialize(doc_name, root_name, el_name_prefix)
      @doc_name = doc_name
      @root_name = root_name
      @el_name_prefix = el_name_prefix
    end

    def generate_html_page(input)
      content = Compiler.new(input, @doc_name, @root_name, @el_name_prefix)
                        .compile
                        .chomp
      rhtml = ERB.new(self.class::TEMPLATE)
      rhtml.result(binding)
    end
  end

  class IIFEGenerator < TemplatedGenerator
    TEMPLATE = %(
    <html>
      <head>
        <script src="https://cdn.jsdelivr.net/npm/ruby-head-wasm-wasi@2.1.0/dist/browser.script.iife.js"></script>
        <script type="text/ruby">
          <%= content %>
        </script>
      </head>
      <body>
        <div id="<%= @root_name %>"></div>
      </body>
    </html>
    ).gsub(/^ /, '')
  end
end
