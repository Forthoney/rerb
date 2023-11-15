# frozen_string_literal: true

RSpec.describe(RERB::Compiler) do
  context 'with only pure html elements' do
    it 'compiles single element' do
      compiler = described_class.new('<h1></h1>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
        EX
      ))
    end

    it 'compiles self-closing element without ending solidus' do
      compiler = described_class.new('<input>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @input_1 = document.createElement('input')
          root.appendChild(@input_1)
        EX
      ))
    end

    it 'compiles self-closing element withending solidus' do
      compiler = described_class.new('<input/>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @input_1 = document.createElement('input')
          root.appendChild(@input_1)
        EX
      ))
    end

    it 'compiles single element with text' do
      compiler = described_class.new('<h1>Hello World</h1>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h1_1.appendChild(document.createTextNode("Hello World"))
        EX
      ))
    end

    it 'compiles sibling elements' do
      compiler = described_class.new('<h1></h1><h2></h2>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h2_1 = document.createElement('h2')
          root.appendChild(@h2_1)
        EX
      ))
    end

    it 'compiles sibling elements with prior being a self-closing tag' do
      compiler = described_class.new('<img><h2></h2>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @img_1 = document.createElement('img')
          root.appendChild(@img_1)
          @h2_1 = document.createElement('h2')
          root.appendChild(@h2_1)
        EX
      ))
    end

    it 'compiles sibling elements with latter being a self-closing tag' do
      compiler = described_class.new('<h1></h1><img>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @img_1 = document.createElement('img')
          root.appendChild(@img_1)
        EX
      ))
    end

    it 'compiles sibling elements with text' do
      compiler = described_class.new('<h1>Hello</h1><h2>World</h2>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h1_1.appendChild(document.createTextNode("Hello"))
          @h2_1 = document.createElement('h2')
          root.appendChild(@h2_1)
          @h2_1.appendChild(document.createTextNode("World"))
        EX
      ))
    end

    it 'compiles nested elements' do
      compiler = described_class.new('<h1><h2></h2></h1>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h2_1 = document.createElement('h2')
          @h1_1.appendChild(@h2_1)
        EX
      ))
    end

    it 'compiles nested elements with self-closing tag as child' do
      compiler = described_class.new('<h1><br/></h1>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @br_1 = document.createElement('br')
          @h1_1.appendChild(@br_1)
        EX
      ))
    end

    it 'compiles nested elements with text in child' do
      compiler = described_class.new('<h1><h2>Hello World</h2></h1>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h2_1 = document.createElement('h2')
          @h1_1.appendChild(@h2_1)
          @h2_1.appendChild(document.createTextNode("Hello World"))
        EX
      ))
    end

    it 'compiles nested elements with text in child and parent' do
      compiler = described_class.new('<h1>Hiyo<h2>Hello World</h2></h1>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h1_1.appendChild(document.createTextNode("Hiyo"))
          @h2_1 = document.createElement('h2')
          @h1_1.appendChild(@h2_1)
          @h2_1.appendChild(document.createTextNode("Hello World"))
        EX
      ))
    end

    it 'compiles nested elements with regular and self-closing tags as children' do
      compiler = described_class.new('<h1><br/><div></div></h1>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @br_1 = document.createElement('br')
          @h1_1.appendChild(@br_1)
          @div_1 = document.createElement('div')
          @h1_1.appendChild(@div_1)
        EX
      ))
    end

    it 'compiles nested elements with regular tag with text and self-closing tag as children' do
      compiler = described_class.new('<h1><br/><h2>Hello World</h2></h1>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @br_1 = document.createElement('br')
          @h1_1.appendChild(@br_1)
          @h2_1 = document.createElement('h2')
          @h1_1.appendChild(@h2_1)
          @h2_1.appendChild(document.createTextNode("Hello World"))
        EX
      ))
    end
  end

  context 'with ERB embeddings' do
    it 'compiles erb expression' do
      compiler = described_class.new('<%= foo %>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          root.appendChild(document.createTextNode("\#{foo}"))
        EX
      ))
    end

    it 'compiles nested erb expression' do
      compiler = described_class.new('<h1><%= foo %></h1>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h1_1.appendChild(document.createTextNode("\#{foo}"))
        EX
      ))
    end

    it 'compiles erb if statement' do
      compiler = described_class.new('<% if true %>Hello World<% end %>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          if true
          root.appendChild(document.createTextNode("Hello World"))
          end
        EX
      ))
    end

    it 'compiles erb loop' do
      compiler = described_class.new('<% [1, 2].each do |_| %>Hello World<% end %>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          [1, 2].each do |_|
          root.appendChild(document.createTextNode("Hello World"))
          end
        EX
      ))
    end

    it 'compiles erb loop with element inside' do
      compiler = described_class.new(
        '<% [1, 2].each do |_| %><div>Hello World</div><% end %>',
        'ViewModel',
      )
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          [1, 2].each do |_|
          @div_1 = document.createElement('div')
          root.appendChild(@div_1)
          @div_1.appendChild(document.createTextNode("Hello World"))
          end
        EX
      ))
    end
  end

  context 'with html elements containing an attribute' do
    it 'compiles name-value attributes' do
      compiler = described_class.new('<div class="container"></div>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @div_1 = document.createElement('div')
          @div_1.setAttribute("class", "container")
          root.appendChild(@div_1)
        EX
      ))
    end

    it 'compiles name-value attributes on self-closing tag' do
      compiler = described_class.new('<input class="danger"/>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @input_1 = document.createElement('input')
          @input_1.setAttribute("class", "danger")
          root.appendChild(@input_1)
        EX
      ))
    end

    it 'compiles event attributes' do
      compiler = described_class.new('<div onclick="<%= lambda { |e| p e } %>"></div>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @div_1 = document.createElement('div')
          @div_1.addEventListener("click", lambda { |e| p e })
          root.appendChild(@div_1)
        EX
      ))
    end

    it 'compiles attribute names with erb' do
      compiler = described_class.new('<div data-<%= value %>="bool"></div>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @div_1 = document.createElement('div')
          @div_1.setAttribute("data-\#{value}", "bool")
          root.appendChild(@div_1)
        EX
      ))
    end

    it 'compiles attribute values with erb' do
      compiler = described_class.new('<div data="<%= value %>"></div>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @div_1 = document.createElement('div')
          @div_1.setAttribute("data", "\#{value}")
          root.appendChild(@div_1)
        EX
      ))
    end

    it 'compiles boolean attributes' do
      compiler = described_class.new('<div hidden></div>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @div_1 = document.createElement('div')
          @div_1.setAttribute("hidden", true)
          root.appendChild(@div_1)
        EX
      ))
    end

    it 'compiles multiple name-value attributes' do
      compiler = described_class.new('<div class="container" id="box"></div>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @div_1 = document.createElement('div')
          @div_1.setAttribute("class", "container")
          @div_1.setAttribute("id", "box")
          root.appendChild(@div_1)
        EX
      ))
    end

    it 'compiles multiple name-value attributes and boolean attribute' do
      compiler = described_class.new('<div class="container" id="box" hidden></div>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @div_1 = document.createElement('div')
          @div_1.setAttribute("class", "container")
          @div_1.setAttribute("id", "box")
          @div_1.setAttribute("hidden", true)
          root.appendChild(@div_1)
        EX
      ))
    end

    it 'compiles multiple name-value attributes and boolean attribute on self-closing tag' do
      compiler = described_class.new('<input class="in" id="form-input" hidden>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @input_1 = document.createElement('input')
          @input_1.setAttribute("class", "in")
          @input_1.setAttribute("id", "form-input")
          @input_1.setAttribute("hidden", true)
          root.appendChild(@input_1)
        EX
      ))
    end
  end

  context 'with html elements containing multiple attributes' do
    it 'compiles name-value attributes' do
      compiler = described_class.new('<div class="container" id="divider"></div>', 'ViewModel')
      expect(compiler.compile_body).to(eq(
        <<~EX.chomp,
          @div_1 = document.createElement('div')
          @div_1.setAttribute("class", "container")
          @div_1.setAttribute("id", "divider")
          root.appendChild(@div_1)
        EX
      ))
    end
  end

  it 'compiles full classes' do
    compiler = described_class.new('<div class="container" id="divider"></div>', 'ViewModel')
    expect(compiler.compile).to(eq(
      <<~EX.chomp,
        class ViewModel
          def initialize
            setup_dom
          end

          private

          def setup_dom
            @div_1 = document.createElement('div')
            @div_1.setAttribute("class", "container")
            @div_1.setAttribute("id", "divider")
            root.appendChild(@div_1)
          end

          def document
            JS.global[:document]
          end

          def root
            document.getElementById("root")
          end
        end

        ViewModel.new
      EX
    ))
  end
end
