Gem::Specification.new do |spec|
  spec.name          = "jekyll-apple-maps"
  spec.version       = "1.0.2"
  spec.authors       = ["Zeke Snider"]
  spec.email         = ["zekesnider@me.com"]

  spec.summary       = %q{Apple Maps plugin for Jekyll}
  spec.description   = %q{Provides tags for the Jekyll blogging engine to generate Apple Maps content for your site.}
  spec.homepage      = "https://github.com/zekesnider/jekyll-apple-maps"
  spec.license       = "Apache-2.0"

  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/zekesnider/jekyll-apple-maps/issues",
    "changelog_uri"     => "https://github.com/ZekeSnider/jekyll-apple-maps/releases",
    "documentation_uri" => "https://github.com/ZekeSnider/jekyll-apple-maps/",
    "homepage_uri"      => "https://github.com/ZekeSnider/jekyll-apple-maps/",
    "source_code_uri"   => "https://github.com/ZekeSnider/jekyll-apple-maps/",
  }

  spec.files         = Dir.glob("{bin,lib}/**/*") + %w(README.md)
  spec.require_paths = ["lib"]

  spec.add_development_dependency "jekyll", "~> 4.0"
  spec.add_development_dependency "simplecov", "~> 0.17"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "liquid", "~> 4.0"
  spec.add_development_dependency "webmock", "~> 3.23.1"
  spec.add_development_dependency "fakefs", "~> 2.5"
end
