# frozen_string_literal: true

RSpec.describe WERB::Compiler do
  context 'with only pure html elements' do
    it 'compiles single element' do
      compiler = described_class.new('<h1></h1>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
        EX
      )
    end

    it 'compiles single element with text' do
      compiler = described_class.new('<h1>Hello World</h1>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h1_1[:innerText] = @h1_1[:innerText].to_s + "Hello World"
        EX
      )
    end

    it 'compiles sibling elements' do
      compiler = described_class.new('<h1></h1><h2></h2>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h2_1 = document.createElement('h2')
          root.appendChild(@h2_1)
        EX
      )
    end

    it 'compiles sibling elements with text' do
      compiler = described_class.new('<h1>Hello</h1><h2>World</h2>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h1_1[:innerText] = @h1_1[:innerText].to_s + "Hello"
          @h2_1 = document.createElement('h2')
          root.appendChild(@h2_1)
          @h2_1[:innerText] = @h2_1[:innerText].to_s + "World"
        EX
      )
    end

    it 'compiles nested elements' do
      compiler = described_class.new('<h1><h2></h2></h1>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h2_1 = document.createElement('h2')
          @h1_1.appendChild(@h2_1)
        EX
      )
    end

    it 'compiles nested elements with text in child' do
      compiler = described_class.new('<h1><h2>Hello World</h2></h1>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h2_1 = document.createElement('h2')
          @h1_1.appendChild(@h2_1)
          @h2_1[:innerText] = @h2_1[:innerText].to_s + "Hello World"
        EX
      )
    end

    it 'compiles nested elements with text in child and parent' do
      compiler = described_class.new('<h1>Hiyo<h2>Hello World</h2></h1>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h1_1[:innerText] = @h1_1[:innerText].to_s + "Hiyo"
          @h2_1 = document.createElement('h2')
          @h1_1.appendChild(@h2_1)
          @h2_1[:innerText] = @h2_1[:innerText].to_s + "Hello World"
        EX
      )
    end
  end

  context 'with ERB embeddings' do
    it 'compiles erb expression' do
      compiler = described_class.new('<%= foo %>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          root[:innerText] = root[:innerText].to_s + "\#{foo}"
        EX
      )
    end

    it 'compiles nested erb expression' do
      compiler = described_class.new('<h1><%= foo %></h1>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @h1_1 = document.createElement('h1')
          root.appendChild(@h1_1)
          @h1_1[:innerText] = @h1_1[:innerText].to_s + "\#{foo}"
        EX
      )
    end

    it 'compiles erb statement' do
      compiler = described_class.new('<% if true %>Hello World<% end %>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          if true
          root[:innerText] = root[:innerText].to_s + "Hello World"
          end
        EX
      )
    end
  end

  context 'with html elements containing an attribute' do
    it 'compiles name-value attributes' do
      compiler = described_class.new('<div class="container"></div>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @div_1 = document.createElement('div')
          @div_1.setAttribute("class", "container")
          root.appendChild(@div_1)
        EX
      )
    end

    it 'compiles event attributes' do
      compiler = described_class.new('<div onclick=<%= lambda { |e| p e } %>></div>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @div_1 = document.createElement('div')
          @div_1.addEventListener("click", lambda { |e| p e })
          root.appendChild(@div_1)
        EX
      )
    end

    it 'compiles attributes with interpolation' do
      compiler = described_class.new('<div data-<%= value %>="bool"></div>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @div_1 = document.createElement('div')
          @div_1.setAttribute("data-\#{value}", "bool")
          root.appendChild(@div_1)
        EX
      )
    end
  end

  context 'with html elements containing multiple attributes' do
    it 'compiles name-value attributes' do
      compiler = described_class.new('<div class="container" id="divider"></div>', 'ViewModel')
      expect(compiler.compile_body).to eq(
        <<~EX.chomp
          @div_1 = document.createElement('div')
          @div_1.setAttribute("class", "container")
          @div_1.setAttribute("id", "divider")
          root.appendChild(@div_1)
        EX
      )
    end
  end

  it 'compiles full classes' do
    compiler = described_class.new('<div class="container" id="divider"></div>', 'ViewModel')
    expect(compiler.compile).to eq(
      <<~EX.chomp
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
    )
  end
end
