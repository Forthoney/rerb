# frozen_string_literal: true

require_relative 'werb/version'
require 'werb/compiler'
require 'werb/templated_generator'
require 'werb/cli'

module WERB
  class Error < StandardError; end

  class PatternMatchError < Error; end

  class EmptyFrameError < Error
    def initialize(message = 'Frames list is empty')
      super
      @message = message
    end
  end
end
