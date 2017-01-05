$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "columbo_rails_client/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "columbo-rails-client"
  s.version     = Columbo::ResourcePublisher::VERSION
  s.authors     = ["Wifirst"]

  s.homepage    = 'https://github.com/wifirst-lab/columbo-ruby-client'
  s.summary     = "A simple Rails client for Columbo, easely plugable to ActiveRecord"
  s.description = "A simple Rails client for Columbo, easely plugable to ActiveRecord"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_development_dependency "bundler", "~> 1.13"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec", "~> 3.0"

  s.add_dependency 'columbo-client'
end
