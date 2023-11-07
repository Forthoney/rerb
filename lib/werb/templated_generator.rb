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
    ).gsub(/^    /, '')
  end

  class UMDGenerator < TemplatedGenerator
    TEMPLATE = %(
    <html>
      <script src="https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@latest/dist/browser.umd.js"></script>
      <script>
        const { DefaultRubyVM } = window["ruby-wasm-wasi"];
        const main = async () => {
          // Fetch and instantiate WebAssembly binary
          const response = await fetch(
            //      Tips: Replace the binary with debug info if you want symbolicated stack trace.
            //      (only nightly release for now)
            //      "https://cdn.jsdelivr.net/npm/ruby-3_2-wasm-wasi@next/dist/ruby.debug+stdlib.wasm"
            "https://cdn.jsdelivr.net/npm/ruby-3_2-wasm-wasi@latest/dist/ruby.wasm"
          );
          const buffer = await response.arrayBuffer();
          const module = await WebAssembly.compile(buffer);
          const { vm } = await DefaultRubyVM(module);

          vm.printVersion();
          vm.eval(`
            <%= content %>
          `);
        };

        main();
      </script>
      <body></body>
    </html>
    ).gsub(/^    /, '')
  end
end
