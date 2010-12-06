require "rubygems"
require "json"
require 'haml'
require 'sinatra/base'
require File.dirname(__FILE__)+'/jslint_suite'

$asset_base_dir = File.expand_path(File.join(File.dirname(__FILE__), "../assets"))

$fixture_base_dir ||= File.join($spec_base_dir, "fixtures")

$screw_assets = %w{
  vendor/fulljslint.js
  vendor/screw-unit/lib/jquery.fn.js
  vendor/screw-unit/lib/jquery.print.js
  vendor/screw-unit/lib/screw.builder.js
  vendor/screw-unit/lib/screw.matchers.js
  vendor/screw-unit/lib/screw.events.js
  vendor/screw-unit/lib/screw.behaviors.js
  vendor/smoke/lib/smoke.core.js
  vendor/smoke/lib/smoke.mock.js
  vendor/smoke/lib/smoke.stub.js
  vendor/smoke/plugins/screw.mocking.js
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
    "#{$spec_base_dir}/fixtures/#{name}.html"
  end
end

class SpecFile
  attr_reader :name

  def self.url_for(file)
    File.join("/specs", file)
  end

  def initialize(name)
    @name = name
  end

  def filename
    File.join($spec_base_dir, name + "_spec.js")
  end

  def url
    SpecFile.url_for(name + "_spec.js")
  end

  def used_fixtures
    scan_for_statement("use_fixture", filename).map {|name| FixtureFile.new(name) }
  end

  def required_scripts
    required_files_in(File.join($spec_base_dir, "spec_helper.js")) + required_files_in(filename)
  end

  def last_dependency_change
    used_files.map do |file|
      File.mtime(file).to_i rescue 0
    end.max
  end

  def last_changed
    @last_changed ||= File.mtime(filename).to_i
  end

  def used_files
    [filename] +
      used_fixtures.map {|fixture| fixture.filename } +
      required_scripts.map {|script| $code_base_dir + script}
  end

  protected

  def scan_for_statement(statement, filename)
    File.read(filename).scan(/#{statement}\(["'](.+)['"]\)/).map { |groups| groups[0] }
  end

  def required_files_in(filename)
    files = scan_for_statement("require", filename)
    files = files.reject { |file| file == "spec_helper.js" }
    files = files.map { |file| file.gsub("../../public", "") }
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
  Dir.glob(File.join($spec_base_dir, "*_spec.js")).sort.map do |file|
    SpecFile.new(file.gsub("#{$spec_base_dir}/", "").gsub("_spec.js", ""))
  end
end

def current_spec
  all_specs.sort{ |a, b| a.last_changed <=> b.last_changed }.last
end

class ScrewServer < Sinatra::Base

  set :public, $code_base_dir
  set :views, File.join(File.dirname(__FILE__), '../views')

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

  get "/specs/*" do
    send_file(File.join($spec_base_dir, params[:splat]))
  end

  get "/fixtures/*" do
    send_file(File.join($fixture_base_dir, params[:splat]))
  end

  get "/screw/*" do
    send_file(File.join($asset_base_dir, params[:splat]))
  end

  helpers do
    def cache_busting_url(url)
      "#{url}?#{rand}"
    end

    def jslint_suites
      @jslint_suites ||= JslintSuite.suites_from(File.join($spec_base_dir, "jslint.rb")).map do |suite|
        {
          :file_list => suite.file_list.map { |file| url_for_source_file(file) },
          :options => suite.options
        }
      end
    end

    def url_for_screw_asset(asset_name)
      "/screw/#{asset_name}"
    end
  end

  private

  def url_for_source_file(filename)
    file = File.expand_path(filename)
    if file.start_with?($code_base_dir)
      file[$code_base_dir.length..-1]
    elsif file.start_with?($spec_base_dir)
      SpecFile.url_for(file[$spec_base_dir.length..-1])
    else
      raise "file #{file} cannot be checked by jslint since it it not inside the spec or code path"
    end
  end

  def run_specs(specs)
    @specs = specs
    @requires = required_files_for(@specs)
    @fixture_html = fixture_hash_for(@specs)

    haml :run_spec
  end

end
