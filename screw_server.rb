require "rubygems"
require "json"
require 'haml'
require 'sinatra/base'

$base_dir = File.dirname(__FILE__)+"/../.."
$screw_server_path = File.expand_path(File.dirname(__FILE__))[File.expand_path($base_dir).length..-1]
$spec_path = "/spec/javascripts/"
$spec_base_path = $base_dir + $spec_path

$library_files = %w{
  screw-unit/lib/jquery.fn.js
  screw-unit/lib/jquery.print.js
  screw-unit/lib/screw.builder.js
  screw-unit/lib/screw.matchers.js
  screw-unit/lib/screw.events.js
  screw-unit/lib/screw.behaviors.js
  smoke/lib/smoke.core.js
  smoke/lib/smoke.mock.js
  smoke/lib/smoke.stub.js
  smoke/plugins/screw.mocking.js
  screw-server.js
}

def scan_for_statement(statement, filename)
  File.read(filename).scan(/#{statement}\(["'](.+)['"]\)/).map { |groups| groups[0] }
end

def required_files_in(filename)
  files = scan_for_statement("require", filename)
  files = files.reject { |file| file == "spec_helper.js" }
  files = files.map { |file| file.gsub("../../public", "/public") }
end

def required_files_for(specs)
  requires = []
  specs.each do |spec|
    requires += spec.required_scripts
  end
  requires.uniq
end

def fixture_hash_for(specs)
  fixture_html = {}
  specs.each do |spec|
    spec.used_fixtures.each do |fixture|
      fixture_html[fixture.name] ||= File.read(fixture.filename).match(/<body>(.+)<\/body>/m)[1]
    end
  end
  fixture_html
end

class FixtureFile
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def filename
    "#{$spec_base_path}/fixtures/#{name}.html"
  end
end

class SpecFile
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def filename
    $spec_base_path + name + "_spec.js"
  end

  def url
    $spec_path + name + "_spec.js"
  end

  def used_fixtures
    scan_for_statement("use_fixture", filename).map {|name| FixtureFile.new(name) }
  end

  def required_scripts
    required_files_in($spec_base_path + "spec_helper.js") + required_files_in(filename)
  end
end

def all_specs
  Dir.glob($spec_base_path + "*_spec.js").map do |file|
    SpecFile.new(file.gsub($spec_base_path, "").gsub("_spec.js", ""))
  end
end

class ScrewServer < Sinatra::Base

  set :public, $base_dir
  set :views, File.dirname(__FILE__) + '/views'

  get "/run/:name" do
    run_specs([SpecFile.new(params[:name])])
  end

  get "/run" do
    run_specs(all_specs)
  end

  get "/bisect/:victim/:begin/:end" do
    victim = params[:victim]
    suspects = all_specs - [victim]

    subset = suspects[params[:begin].to_i..(params[:end].to_i - 1)]

    puts "suspects: #{subset.length}"

    specs_to_run = (subset + [victim]).map {|name| SpecFile.new(name) }
    run_specs()
  end

  get "/" do
    @specs = all_specs
    haml :index
  end

  private

  def run_specs(specs)
    @specs = specs
    @requires = required_files_for(@specs)
    @fixture_html = fixture_hash_for(@specs)

    haml :run_spec
  end

end
