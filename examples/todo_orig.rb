require 'js'

class Todo
  def initialize(target)
    @active_items = []
    @completed_items = []

    setup_target(target)
    render
  end

  private

  # Do one time setup
  def setup_target(target)
    @el = doc.getElementById(target)
    @el[:innerHTML] = ''
    @header = doc.createElement('h1')

    @active_header = doc.createElement('h2')
    @active = doc.createElement('ul')

    @completed_header = doc.createElement('h2')
    @completed = doc.createElement('ul')

    @input = doc.createElement('input')
    @button = doc.createElement('button')
    @button[:innerText] = 'Add'

    @button.addEventListener 'click', lambda { |_e|
      @active_items << @input[:value]
      @input[:value] = ''
      render(changed: :active)
    }

    @el.appendChild(@header)

    @el.appendChild(@active_header)
    @el.appendChild(@active)

    @el.appendChild(@completed_header)
    @el.appendChild(@completed)

    @el.appendChild(@input)
    @el.appendChild(@button)
  end

  def list_item(id, text, checked, onclick)
    li = doc.createElement('li')
    checkbox = doc.createElement('input')
    checkbox[:type] = 'checkbox'
    checkbox[:checked] = checked
    checkbox[:id] = id
    checkbox.addEventListener 'change', onclick

    li.appendChild(checkbox)
    li.appendChild(doc.createTextNode(text))
    li
  end

  def render(changed: :all)
    @header[:innerText] = "Todo (#{@active_items.size + @completed_items.size})"
    @active_header[:innerText] = "Active (#{@active_items.size})"
    @completed_header[:innerText] = "Completed (#{@completed_items.size})"

    @active[:innerHTML] = ''
    @active_items.each_with_index do |active_item, index|
      callback = lambda { |e|
        index = e[:currentTarget][:id].to_i
        @completed_items << @active_items[index]
        @active_items.delete_at(index)
        render
      }
      li = list_item(index, active_item, false, callback)
      @active.appendChild(li)
    end

    return unless changed == :all

    @completed[:innerHTML] = ''
    @completed_items.each_with_index do |active_item, index|
      callback = lambda { |e|
        index = e[:currentTarget][:id].to_i
        @active_items << @completed_items[index]
        @completed_items.delete_at(index)
        render
      }
      @completed.appendChild(list_item(index, active_item, true, callback))
    end
  end

  def doc
    JS.global[:document]
  end
end

Todo.new('todo-list')
