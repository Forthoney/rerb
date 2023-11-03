# frozen_string_literal: true

RSpec.describe WERB::TemplatedGenerator do
  it 'Generates HTML file using browser.script.iife.js' do
    res = WERB::IIFEGenerator.new('document', 'root', 'el').generate_html_page('<h1></h1>')
    expect(res).to eq(
      %(
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
    ).gsub(/^ /, '')
    )
  end
end
