# frozen_string_literal: true

RSpec.describe WERB::Transpiler do
  it 'transpiles single element' do
    transpiler = WERB::Transpiler.new('<h1></h1>')
    expect(transpiler.transpile).to eq(
      %q(@el1 = document.createElement('h1')
document.appendChild(@el1)
)
    )
  end

  it 'transpiles single element with text' do
    transpiler = WERB::Transpiler.new('<h1>Hello World</h1>')
    expect(transpiler.transpile).to eq(
      %q(@el1 = document.createElement('h1')
document.appendChild(@el1)
@el1[:innerHTML] += "Hello World"
)
    )
  end

  it 'transpiles sibling elements' do
    transpiler = WERB::Transpiler.new('<h1></h1><h2></h2>')
    expect(transpiler.transpile).to eq(
%q(@el1 = document.createElement('h1')
document.appendChild(@el1)
@el2 = document.createElement('h2')
document.appendChild(@el2)
)
    )
  end
end
