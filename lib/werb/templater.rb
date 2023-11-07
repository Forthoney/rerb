# frozen_string_literal: true

require 'erb'

require 'werb'
require 'werb/compiler'

module WERB
  class Templater
    TEMPLATE = '<%= content %>'

    def initialize(filename, root_name, el_name_prefix)
      @viewmodel_name = File.basename(filename, '.*').split('_').map(&:capitalize).join
      @root_name = root_name
      @el_name_prefix = el_name_prefix
    end

    def generate(input)
      content = Compiler.new(input, @viewmodel_name, @root_name, @el_name_prefix)
                        .compile
      rhtml = ERB.new(self.class::TEMPLATE)
      rhtml.result(binding)
    end
  end

  class IIFETemplater < Templater
    TEMPLATE = <<~TMPL.chomp
      <html>
        <head>
          <script src="https://cdn.jsdelivr.net/npm/ruby-head-wasm-wasi@2.1.0/dist/browser.script.iife.js"></script>
          <script type="text/ruby">
            require 'js'

      <%= content.gsub(/^(?!$)/, '  ' * 3) %>
          </script>
        </head>
        <body>
          <div id="<%= @root_name %>"></div>
        </body>
      </html>
    TMPL
  end

  class UMDTemplater < Templater
    TEMPLATE = <<~TMPL.chomp
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
              "https://cdn.jsdelivr.net/npm/ruby-3_2-wasm-wasi@latest/dist/ruby+stdlib.wasm"
            );
            const buffer = await response.arrayBuffer();
            const module = await WebAssembly.compile(buffer);
            const { vm } = await DefaultRubyVM(module);

            vm.printVersion();
            vm.eval(`
              require 'js'

      <%= content.gsub(/^(?!$)/, '  ' * 4) %>
            `);
          };

          main();
        </script>
        <body>
          <div id="<%= @root_name %>"></div>
        </body>
      </html>
    TMPL
  end
end
