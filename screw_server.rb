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

def fixtures_used_in(filename)
  scan_for_statement("use_fixture", filename)
end

def required_files_in(filename)
  files = scan_for_statement("require", filename)
  files = files.reject { |file| file == "spec_helper.js" }
  files = files.map { |file| file.gsub("../../public", "/public") }
end

def required_files_for(specs)
  requires = required_files_in($spec_base_path + "spec_helper.js")
  specs.each do |spec|
    requires += required_files_in($spec_base_path + spec + "_spec.js")
  end
  requires.uniq
end

def fixture_hash_for(specs)
  fixture_html = {}
  specs.each do |spec|
    fixtures_used_in($spec_base_path + spec + "_spec.js").each do |fixture|
      fixture_file = "#{$base_dir}/spec/javascripts/fixtures/#{fixture}.html"
      fixture_html[fixture] ||= File.read(fixture_file).match(/<body>(.+)<\/body>/m)[1]
    end
  end
  fixture_html
end

def all_specs
  Dir.glob($spec_base_path + "*_spec.js").map do |file|
    file.gsub($spec_base_path, "").gsub("_spec.js", "")
  end
end

class ScrewServer < Sinatra::Base

  set :public, $base_dir
  set :views, File.dirname(__FILE__) + '/views'

  get "/run/:name" do
    run_specs([params[:name]])
  end

  get "/run" do
    run_specs(all_specs)
  end

  get "/bisect/:victim/:begin/:end" do
    victim = params[:victim]
    suspects = all_specs - [victim]

    subset = suspects[params[:begin].to_i..(params[:end].to_i - 1)]

    puts "suspects: #{subset.length}"

    run_specs(subset + [victim])
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
