# frozen_string_literal: true

RSpec.describe WERB::Compiler do
  context 'with only pure html elements' do
    it 'compiles single element' do
      compiler = described_class.new('<h1></h1>')
      expect(compiler.compile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
)
      )
    end

    it 'compiles single element with text' do
      compiler = described_class.new('<h1>Hello World</h1>')
      expect(compiler.compile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el1[:innerText] = @el1[:innerText].to_s + "Hello World"
)
      )
    end

    it 'compiles sibling elements' do
      compiler = described_class.new('<h1></h1><h2></h2>')
      expect(compiler.compile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el2 = document.createElement('h2')
root.appendChild(@el2)
)
      )
    end

    it 'compiles sibling elements with text' do
      compiler = described_class.new('<h1>Hello</h1><h2>World</h2>')
      expect(compiler.compile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el1[:innerText] = @el1[:innerText].to_s + "Hello"
@el2 = document.createElement('h2')
root.appendChild(@el2)
@el2[:innerText] = @el2[:innerText].to_s + "World"
)
      )
    end

    it 'compiles nested elements' do
      compiler = described_class.new('<h1><h2></h2></h1>')
      expect(compiler.compile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el2 = document.createElement('h2')
@el1.appendChild(@el2)
)
      )
    end

    it 'compiles nested elements with text in child' do
      compiler = described_class.new('<h1><h2>Hello World</h2></h1>')
      expect(compiler.compile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el2 = document.createElement('h2')
@el1.appendChild(@el2)
@el2[:innerText] = @el2[:innerText].to_s + "Hello World"
)
      )
    end

    it 'compiles nested elements with text in child and parent' do
      compiler = described_class.new('<h1>Hiyo<h2>Hello World</h2></h1>')
      expect(compiler.compile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el1[:innerText] = @el1[:innerText].to_s + "Hiyo"
@el2 = document.createElement('h2')
@el1.appendChild(@el2)
@el2[:innerText] = @el2[:innerText].to_s + "Hello World"
)
      )
    end
  end

  context 'with ERB embeddings' do
    it 'compiles erb expression' do
      compiler = described_class.new('<%= foo %>')
      expect(compiler.compile).to eq("root[:innerText] = root[:innerText].to_s + \"\#{foo}\"\n")
    end

    it 'compiles nested erb expression' do
      compiler = described_class.new('<h1><%= foo %></h1>')
      expect(compiler.compile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el1[:innerText] = @el1[:innerText].to_s + "#{foo}"
)
      )
    end

    it 'compiles erb statement' do
      compiler = described_class.new('<% if true %>Hello World<% end %>')
      expect(compiler.compile).to eq(
        %q(if true
root[:innerText] = root[:innerText].to_s + "Hello World"
end
)
      )
    end
  end

  context 'with html elements containing an attribute' do
    it 'compiles name-value attributes' do
      compiler = described_class.new('<div class="container"></div>')
      expect(compiler.compile).to eq(
        %q(@el1 = document.createElement('div')
@el1.setAttribute('class', 'container')
root.appendChild(@el1)
)
      )
    end

    it 'compiles event attributes' do
      compiler = described_class.new('<div onclick=<%= lambda { |e| p e } %>></div>')
      expect(compiler.compile).to eq(
        %q(@el1 = document.createElement('div')
@el1.addEventListener('click', lambda { |e| p e })
root.appendChild(@el1)
)
      )
    end
  end

  context 'with html elements containing multiple attributes' do
    it 'compiles name-value attributes' do
      compiler = described_class.new('<div class="container" id="divider"></div>')
      expect(compiler.compile).to eq(
        %q(@el1 = document.createElement('div')
@el1.setAttribute('class', 'container')
@el1.setAttribute('id', 'divider')
root.appendChild(@el1)
)
      )
    end
  end
end
