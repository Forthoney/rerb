# frozen_string_literal: true

require_relative 'werb/version'
require 'werb/compiler'

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
