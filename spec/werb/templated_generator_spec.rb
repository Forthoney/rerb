# frozen_string_literal: true

RSpec.describe WERB::TemplatedGenerator do
  it 'generates HTML file using browser.script.iife.js' do
    res = WERB::IIFEGenerator.new('document', 'root', 'el')
                             .generate_html_page('<h1></h1>')
    expect(res).to eq(
      <<~EX.chomp
        <html>
          <head>
            <script src="https://cdn.jsdelivr.net/npm/ruby-head-wasm-wasi@2.1.0/dist/browser.script.iife.js"></script>
            <script type="text/ruby">
              @el1 = document.createElement('h1')
              root.appendChild(@el1)
            </script>
          </head>
          <body>
            <div id="root"></div>
          </body>
        </html>
      EX
    )
  end

  it 'generates HTML file using browser.umd.js' do
    res = WERB::UMDGenerator.new('document', 'root', 'el')
                            .generate_html_page('<h1></h1>')
    expect(res).to eq(
      <<~EX.chomp
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
                @el1 = document.createElement('h1')
                root.appendChild(@el1)
              `);
            };

            main();
          </script>
          <body></body>
        </html>
      EX
    )
  end
end