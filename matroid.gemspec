# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'matroid/version'

Gem::Specification.new do |spec|
  spec.name          = "matroid"
  spec.version       = Matroid::VERSION
  spec.authors       = ["Matroid"]
  spec.email         = ["solutions@matroid.com"]

  spec.summary       = %q{Matroid API Ruby Library}
  spec.description   = %q{Check your account status on Matroid. More features coming soon.}
  spec.homepage      = "http://www.matroid.com"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'omniauth-oauth2', '~> 1.3.1'
  spec.add_dependency 'httpclient'

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "fakeweb"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "rspec"

  spec.add_dependency "dotenv"
  spec.add_dependency "faraday"
  spec.add_dependency "json"
end
