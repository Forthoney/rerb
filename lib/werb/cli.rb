# frozen_string_literal: true

require 'optparse'

require 'werb'
require 'werb/templater'

module WERB
  # Command Line Interface for invoking WERB
  module CLI
    def parse(args)
      parser = OptionParser.new do |o|
        o.banner = 'Usage: werb [options...] FILE'
        o.on('--template TYPE', %w[umd iife nil],
             'Specify which html template to use to wrap the generated code. ' \
             'Valid options are umd, iife, and nil.',
             'nil will use no template and just output raw ruby.wasm code. ' \
             'Defaults to umd')
        o.on('--root NAME',
             'The html id of the root element to add all other DOM nodes to. ' \
             'Defaults to "root"')
        o.on('-v', '--version', 'Output version information and exit.')
      end
      opts = {
        template: 'umd',
        document: 'document',
        root: 'root',
        el_prefix: 'el'
      }
      parser.parse!(args, into: opts)

      filename = args.shift
      return puts parser.help if filename.nil?

      input = File.read(filename)
      case opts[:template]
      when 'umd'
        res = UMDTemplater.new(filename, opts[:root])
                          .generate(input)
      when 'iife'
        res = IIFETemplater.new(filename, opts[:root])
                           .generate(input)
      when 'nil'
        res = Templater.new(filename, opts[:root])
                       .generate(input)
      else
        raise 'Invalid template option. Choose between umd, iife, nil.'
      end
      puts res
    end

    module_function :parse
  end
end
