require_relative 'lib/random_color/version'

Gem::Specification.new do |spec|
  spec.name          = "random_color"
  spec.version       = RandomColor::VERSION
  spec.authors       = ["Khash Sajadi"]
  spec.email         = ["khash@sajadi.co.uk"]

  spec.summary       = "A Ruby port of Random Color JS library"
  spec.description   = "This is a one to one copy of the above library"
  spec.homepage      = "https://github.com/khash"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
