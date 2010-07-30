require "rubygems"
require "json"
require 'haml'
require 'sinatra/base'
require File.dirname(__FILE__)+'/jslint_suite'

def url_for(file)
  File.expand_path(file)[$base_dir.length..-1]
end

$base_dir = File.expand_path(File.dirname(__FILE__)+"/../..")
$screw_server_path = url_for(File.dirname(__FILE__))
$spec_path = "/spec/javascripts/"
$spec_base_path = $base_dir + $spec_path

$library_files = %w{
  fulljslint.js
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
      fixture_html[fixture.name] ||= File.read(fixture.filename)
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
    required_files_in($spec_base_path + "spec_helper.js") +
    [$spec_path + "spec_helper.js"] +
      required_files_in(filename)
  end

  def last_dependency_change
    used_files.map do |file|
      File.mtime(file).to_i
    end.max
  end

  def last_changed
    @last_changed ||= File.mtime(filename).to_i
  end

  def used_files
    [filename] +
      used_fixtures.map {|fixture| fixture.filename } +
      required_scripts.map {|script| $base_dir + script}
  end

  protected

  def scan_for_statement(statement, filename)
    File.read(filename).scan(/#{statement}\(["'](.+)['"]\)/).map { |groups| groups[0] }
  end

  def required_files_in(filename)
    files = scan_for_statement("require", filename)
    files = files.reject { |file| file == "spec_helper.js" }
    files = files.map { |file| file.gsub("../../public", "/public") }
  end
end

def monitor_code(spec)
<<-EOS
  Screw.check_for_change = function() {
    Screw.ajax({
      url: "/has_changes_since/#{spec.name}/#{spec.last_dependency_change}",
      cache: false,
      success: function(answer) {
        if (answer === "true") {
          location.reload();
        }
        else {
          setTimeout(Screw.check_for_change, 1000);
        }
      }
    });
  };
  Screw.check_for_change();
EOS
end

def all_specs
  Dir.glob($spec_base_path + "*_spec.js").map do |file|
    SpecFile.new(file.gsub($spec_base_path, "").gsub("_spec.js", ""))
  end
end

def current_spec
  all_specs.sort{ |a, b| a.last_changed <=> b.last_changed }.last
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
    suspects = all_specs.map { |spec| spec.name } - [victim]

    subset = suspects[params[:begin].to_i..(params[:end].to_i - 1)]

    puts "suspects: #{subset.length}"

    specs_to_run = (subset + [victim]).map {|name| SpecFile.new(name) }
    run_specs(specs_to_run)
  end

  get "/" do
    @specs = all_specs
    haml :index
  end

  get "/monitor" do
    spec = current_spec
    @monitor_code = monitor_code(spec)
    run_specs([spec]);
  end

  get "/has_changes_since/:spec/:timestamp" do
    if current_spec.name != params[:spec]
      "true"
    else
      spec = SpecFile.new(params[:spec])
      if spec.last_dependency_change > params[:timestamp].to_i
        "true"
      else
        "false"
      end
    end
  end

  helpers do
    def cache_busting_url(url)
      "#{url}?#{rand}"
    end

    def jslint_suites
      @jslint_suites ||= JslintSuite.suites_from($spec_base_path + "jslint.rb").map do |suite|
        {
          :file_list => suite.file_list.map { |file| url_for(file) },
          :options => suite.options
        }
      end
    end
  end

  private

  def run_specs(specs)
    @specs = specs
    @requires = required_files_for(@specs)
    @fixture_html = fixture_hash_for(@specs)

    haml :run_spec
  end

end
