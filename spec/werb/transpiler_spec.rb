# frozen_string_literal: true

RSpec.describe WERB::Transpiler do
  context 'with only pure html elements' do
    it 'transpiles single element' do
      transpiler = described_class.new('<h1></h1>')
      expect(transpiler.transpile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
)
      )
    end

    it 'transpiles single element with text' do
      transpiler = described_class.new('<h1>Hello World</h1>')
      expect(transpiler.transpile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el1[:innerText] = @el1[:innerText].to_s + "Hello World"
)
      )
    end

    it 'transpiles sibling elements' do
      transpiler = described_class.new('<h1></h1><h2></h2>')
      expect(transpiler.transpile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el2 = document.createElement('h2')
root.appendChild(@el2)
)
      )
    end

    it 'transpiles sibling elements with text' do
      transpiler = described_class.new('<h1>Hello</h1><h2>World</h2>')
      expect(transpiler.transpile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el1[:innerText] = @el1[:innerText].to_s + "Hello"
@el2 = document.createElement('h2')
root.appendChild(@el2)
@el2[:innerText] = @el2[:innerText].to_s + "World"
)
      )
    end

    it 'transpiles nested elements' do
      transpiler = described_class.new('<h1><h2></h2></h1>')
      expect(transpiler.transpile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el2 = document.createElement('h2')
@el1.appendChild(@el2)
)
      )
    end

    it 'transpiles nested elements with text in child' do
      transpiler = described_class.new('<h1><h2>Hello World</h2></h1>')
      expect(transpiler.transpile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el2 = document.createElement('h2')
@el1.appendChild(@el2)
@el2[:innerText] = @el2[:innerText].to_s + "Hello World"
)
      )
    end

    it 'transpiles nested elements with text in child and parent' do
      transpiler = described_class.new('<h1>Hiyo<h2>Hello World</h2></h1>')
      expect(transpiler.transpile).to eq(
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
    it 'transpiles erb expression' do
      transpiler = described_class.new('<%= foo %>')
      expect(transpiler.transpile).to eq("root[:innerText] = root[:innerText].to_s + \"\#{foo}\"\n")
    end

    it 'transpiles nested erb expression' do
      transpiler = described_class.new('<h1><%= foo %></h1>')
      expect(transpiler.transpile).to eq(
        %q(@el1 = document.createElement('h1')
root.appendChild(@el1)
@el1[:innerText] = @el1[:innerText].to_s + "#{foo}"
)
      )
    end

    it 'transpiles erb statement' do
      transpiler = described_class.new('<% if true %>Hello World<% end %>')
      expect(transpiler.transpile).to eq(
        %q(if true
root[:innerText] = root[:innerText].to_s + "Hello World"
end
)
      )
    end
  end

  context 'with html elements containing attributes' do
    it 'transpiles name-value attributes' do
      transpiler = described_class.new('<div class="container"></div>')
      expect(transpiler.transpile).to eq(
        %q(@el1 = document.createElement('div')
@el1.setAttribute('class', 'container')
root.appendChild(@el1)
)
      )
    end
  end
end
