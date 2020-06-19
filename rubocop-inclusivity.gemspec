require_relative "lib/rubocop/inclusivity/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-inclusivity"
  spec.version = RuboCop::Inclusivity::VERSION
  spec.authors = ["Chris Fung"]
  spec.email = ["aergonaut@gmail.com"]

  spec.summary = "A RuboCop extension to promote inclusive language"
  spec.homepage = "https://github.com/aergonaut/rubocop-inclusivity"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aergonaut/rubocop-inclusivity"
  spec.metadata["changelog_uri"] = "https://github.com/aergonaut/rubocop-inclusivity/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rubocop"
end
