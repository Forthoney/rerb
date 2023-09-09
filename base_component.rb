# frozen_string_literal: true

require 'nokogiri'

class BassComponent
  def initialize(target_id)
    setup(target_id)
    render
  end

  def setup(target_id)
    @target = doc.getElementById(target_id)
  end

  protected

  def doc
    JS.global[:document]
  end

  def generate_dom_element(string)
    fragment = Nokogiri::HTML5.fragment(string)
    fragment.children.map do |el|
      helper(el)
    end
  end

  def helper(elem)
    html_elem = doc.createElement(elem.name)
    html_elem.children.each do |child|
      if child.children.empty?
        html_elem[:innerText] = child.text
      else
        child_el = helper(child)
        html_elem.appendChild(child_el)
      end
    end
    el
  end
end
