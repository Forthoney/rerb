# frozen_string_literal: true

require_relative "lib/rerb/version"

Gem::Specification.new do |spec|
  spec.name = "rerb"
  spec.version = RERB::VERSION
  spec.authors = ["Forthoney"]
  spec.email = ["castlehoneyjung@gmail.com"]

  spec.summary = "Build a DOM for ruby.wasm with ERB"
  spec.description = "RERB is an unopinionated tool for compiling ERB/rhtml into ruby.wasm DOM operations. "\
    "It generates code which, when run on a Ruby VM on WASM, generate the desired DOM."
  spec.homepage = "https://github.com/forthoney/werb"
  spec.license = "MIT"
  spec.required_ruby_version = "~> 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/forthoney/rerb"
  spec.metadata["changelog_uri"] = "https://github.com/Forthoney/rerb/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    %x(git ls-files -z).split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?("bin/", "test/", "spec/", "features/", ".git", ".circleci", "appveyor", "Gemfile")
    end
  end
  spec.bindir = "exe"
  spec.executables << "rerb"
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
