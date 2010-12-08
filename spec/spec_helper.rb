require "rubygems"
gem "bundler", "= 1.0.7"
require "bundler"
ENV["BUNDLE_GEMFILE"] = File.expand_path("../../Gemfile.test", __FILE__)
Bundler.require

RSpec.configure do |config|
  config.before(:each) do
    ScrewServer::Base.code_base_dir = File.join(File.dirname(__FILE__), 'fixtures', 'code')
    use_spec_directory("spec")
  end
end

def use_spec_directory(name)
  ScrewServer::Base.spec_base_dir = File.join(File.dirname(__FILE__), 'fixtures', name)
end

def fixture_code_file(name)
  "#{ScrewServer::Base.code_base_dir}/#{name}"
end

def fixture_spec_file(name)
  "#{ScrewServer::Base.spec_base_dir}/#{name}"
end
