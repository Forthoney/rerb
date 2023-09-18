# frozen_string_literal: true

RSpec.describe WERB::Transpiler do
  it 'transpiles single element' do
    transpiler = described_class.new('<h1></h1>')
    expect(transpiler.transpile).to eq(
      %q(@el1 = document.createElement('h1')
document.appendChild(@el1)
)
    )
  end

  it 'transpiles single element with text' do
    transpiler = described_class.new('<h1>Hello World</h1>')
    expect(transpiler.transpile).to eq(
      %q(@el1 = document.createElement('h1')
document.appendChild(@el1)
@el1[:innerHTML] += "Hello World"
)
    )
  end

  it 'transpiles sibling elements' do
    transpiler = described_class.new('<h1></h1><h2></h2>')
    expect(transpiler.transpile).to eq(
%q(@el1 = document.createElement('h1')
document.appendChild(@el1)
@el2 = document.createElement('h2')
document.appendChild(@el2)
)
)
  end

  it 'transpiles sibling elements with text' do
    transpiler = described_class.new('<h1>Hello</h1><h2>World</h2>')
    expect(transpiler.transpile).to eq(
%q(@el1 = document.createElement('h1')
document.appendChild(@el1)
@el1[:innerHTML] += "Hello"
@el2 = document.createElement('h2')
document.appendChild(@el2)
@el2[:innerHTML] += "World"
)
)
  end

  it 'transpiles nested elements' do
    transpiler = described_class.new('<h1><h2></h2></h1>')
    expect(transpiler.transpile).to eq(
%q(@el1 = document.createElement('h1')
document.appendChild(@el1)
@el2 = document.createElement('h2')
@el1.appendChild(@el2)
)
)
  end

  it 'transpiles nested elements with text in child' do
    transpiler = described_class.new('<h1><h2>Hello World</h2></h1>')
    expect(transpiler.transpile).to eq(
%q(@el1 = document.createElement('h1')
document.appendChild(@el1)
@el2 = document.createElement('h2')
@el1.appendChild(@el2)
@el2[:innerHTML] += "Hello World"
)
)
  end

  it 'transpiles nested elements with text in child and parent' do
    transpiler = described_class.new('<h1>Hiyo<h2>Hello World</h2></h1>')
    expect(transpiler.transpile).to eq(
%q(@el1 = document.createElement('h1')
document.appendChild(@el1)
@el1[:innerHTML] += "Hiyo"
@el2 = document.createElement('h2')
@el1.appendChild(@el2)
@el2[:innerHTML] += "Hello World"
)
)
  end
end
