# frozen_string_literal: true

require 'thor'

require 'werb'
require 'werb/page_generator'

module WERB
  class CLI < Thor
    desc 'compile FILE', 'Compile ERB file into HTML'
    option :body_only, type: :boolean, desc: 'Output compiled code without the html boilerplate'
    def parse(input_file, output_file = nil)
      output_file ||= "#{input_file}.html"
      WERB::PageGenerator.generate_html_page(options[:input_file], 'document', 'root', '@el')
    end
  end
end
