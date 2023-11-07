# frozen_string_literal: true

require 'optparse'

require 'werb'
require 'werb/templater'

module WERB
  module CLI
    def parse(args)
      parser = OptionParser.new do |o|
        o.banner = 'Usage: werb [options] FILE'
        o.on('--template [TYPE]', %w[umd iife nil],
             'Specify which html template to use to wrap the generated code.',
             'Valid options are umd, iife, and nil.',
             'nil will use no template and just output raw ruby.wasm code.',
             'Defaults to umd')
        o.on('--document [NAME]',
             'The name to use for the JS document element in the compiled code.',
             'Defaults to "document"')
        o.on('--root [NAME]',
             'The id of the root element in the compiled code.',
             'Defaults to "root"')
        o.on('--el_prefix [PREFIX]',
             'The prefix to use for the element names in the compiled code.',
             'Defaults to "el"')
      end
      opts = {
        template: 'umd',
        document: 'document',
        root: 'root',
        el_prefix: 'el'
      }
      parser.parse!(args, into: opts)
      input_file = args.shift
      case opts[:template]
      when 'umd'
        res = UMDTemplater.new(opts[:document], opts[:root], opts[:el_prefix])
                          .generate(input_file)

      when 'iife'
        res = IIFETemplater.new(opts[:document], opts[:root], opts[:el_prefix])
                           .generate(input_file)

      when 'nil'
        res = Templater.new(opts[:document], opts[:root], opts[:el_prefix])
                       .generate(input_file)
      else
        raise Error
      end
      p res
    end

    module_function :parse
  end
end
