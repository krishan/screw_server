require 'sinatra/base'

require 'screw_server/jslint_suite'
require "screw_server/spec_file"

module ScrewServer
  class Base < Sinatra::Base

    SPEC_BASE_URL = "___screw_specs___"
    ASSET_BASE_URL = "___screw_assets___"

    set :views, File.join(File.dirname(__FILE__), "..", "..", "views")

    get "/run/:name" do
      run_specs([SpecFile.new(params[:name])])
    end

    get "/run" do
      run_specs(SpecFile.all)
    end

    get "/bisect/:victim/:begin/:end" do
      victim = params[:victim]
      suspects = SpecFile.all.map { |spec| spec.name } - [victim]

      subset = suspects[params[:begin].to_i..(params[:end].to_i - 1)]

      puts "suspects: #{subset.length}"

      specs_to_run = (subset + [victim]).map {|name| SpecFile.new(name) }
      run_specs(specs_to_run)
    end

    get "/" do
      @specs = SpecFile.all
      haml :index
    end

    get "/monitor" do
      spec = SpecFile.latest
      @include_monitor_code = true
      run_specs([spec]);
    end

    get "/has_changes_since/:spec/:timestamp" do
      if SpecFile.latest.name != params[:spec]
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

    get "/#{SPEC_BASE_URL}/*" do
      send_file(File.join(SpecFile.base_dir, params[:splat]))
    end

    get "/#{ASSET_BASE_URL}/*" do
      send_file(File.join(asset_base_dir, params[:splat]))
    end

    helpers do
      def cache_busting_url(url)
        "#{url}?#{rand}"
      end

      def jslint_suites
        @jslint_suites ||= JslintSuite.suites_from(File.join(SpecFile.base_dir, "jslint.rb")).map do |suite|
          {
            :file_list => suite.file_list.map { |file| url_for_source_file(file) },
            :options => suite.options
          }
        end
      end

      def url_for_screw_asset(file)
        "/#{ASSET_BASE_URL}/#{file}"
      end

      def url_for_spec(file)
        "/#{SPEC_BASE_URL}/#{file}"
      end

      def fixture_html
        @specs.inject({}) { |result, spec| result.merge(spec.fixture_hash) }
      end

      def required_files
        @specs.map(&:required_scripts).flatten.uniq
      end

      def monitor_code
      spec = SpecFile.latest
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

      def screw_assets
        %w{
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
      end
    end

    def self.start_serving_specs(spec_dir, code_dir, options)
      ScrewServer::SpecFile.base_dir = File.join(Dir.pwd, "spec/javascripts")
      ScrewServer::Base.code_base_dir = File.join(Dir.pwd, "public")
      ScrewServer::Base.run!(options)
    end

    def self.code_base_dir=(d)
      raise "code directory not found under #{d}" unless File.exists?(d)
      @code_base_dir = d
      set(:public, d)
    end

    def self.code_base_dir
      @code_base_dir
    end

    private

    def url_for_source_file(filename)
      file = File.expand_path(filename)
      if file.start_with?(self.class.code_base_dir)
        file[self.class.code_base_dir.length..-1]
      elsif file.start_with?(SpecFile.base_dir)
        url_for_spec(file[(SpecFile.base_dir.length + 1)..-1])
      else
        raise "file #{file} cannot be checked by jslint since it it not inside the spec or code path"
      end
    end

    def run_specs(specs)
      @specs = specs
      haml :run_spec
    end

    def asset_base_dir
      @assert_base_dir ||= File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "assets"))
    end
  end
end