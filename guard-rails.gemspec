$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "guard-rails"
  s.version     = File.open('VERSION') { |f| f.read }
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["John Bintz", "Wanzhang Sheng"]
  s.email       = ["john@coswellproductions.com", "Ranmocy@gmail.com"]
  s.homepage    = "https://github.com/ranmocy/guard-rails"
  s.summary     = %q{Guard your Rails to always be there.}
  s.description = %q{Restart Rails when things change in your app}
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 2.2.3'

  s.add_dependency 'guard', '~> 2.14'
  s.add_dependency('guard-compat', '~> 1.0')
end
