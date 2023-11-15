# frozen_string_literal: true

require_relative "rerb/version"
require "rerb/compiler"
require "rerb/templater"
require "rerb/cli"
require "rerb/ir"

module RERB
  class Error < StandardError; end

  class EmptyFrameError < Error
    def initialize(message = "Frames list is empty")
      super
      @message = message
    end
  end
end
