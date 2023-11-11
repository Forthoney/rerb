# frozen_string_literal: true

require_relative 'werb/version'
require 'werb/compiler'
require 'werb/templater'
require 'werb/cli'
require 'werb/ir'

module WERB
  class Error < StandardError; end

  class EmptyFrameError < Error
    def initialize(message = 'Frames list is empty')
      super
      @message = message
    end
  end
end
