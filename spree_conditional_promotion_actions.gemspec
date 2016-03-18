# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_conditional_promotion_actions'
  s.version     = '0.0.2'
  s.summary     = 'A parent class and examples for Spree promotion actions that activate different methods when eligible and ineligible. A typical use case would be to add a promotional item to the cart if an order is eligible and remove it again if the order changes to become ineligible.'
  s.description = 'A parent class and examples for Spree promotion actions that activate different methods when eligible and ineligible. A typical use case would be to add a promotional item to the cart if an order is eligible and remove it again if the order changes to become ineligible.'
  s.required_ruby_version = '>= 2.0.0'

  s.author    = 'Isaac Freeman'
  s.email     = 'isaac@resolvedigital.co.nz'
  s.homepage  = 'http://resolve.digital'

  #s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'


  s.add_dependency 'spree_core', '~> 3.0.0'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sass-rails'
  #s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
end
