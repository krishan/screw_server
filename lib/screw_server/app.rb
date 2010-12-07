require 'sinatra/base'

require 'screw_server/jslint_suite'
require "screw_server/spec_file"

module ScrewServer
  class App < Sinatra::Base

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
      send_file(file_from_base_dir(Base.spec_base_dir, params[:splat]))
    end

    get "/#{ASSET_BASE_URL}/*" do
      send_file(file_from_base_dir(asset_base_dir, params[:splat]))
    end

    helpers do
      def cache_busting_url(url)
        "#{url}?#{rand}"
      end

      def jslint_suites
        @jslint_suites ||= JslintSuite.suites_from(File.join(Base.spec_base_dir, "jslint.rb")).map do |suite|
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

    def self.run!(*args)
      set(:public, Base.code_base_dir)
      super(*args)
    end

    private

    def file_from_base_dir(base_dir, file)
      File.expand_path(File.join(base_dir, file)).tap do |result|
        unless result.start_with?(base_dir)
          raise Sinatra::NotFound, "Forbidden Access out of base directory"
        end
      end
    end

    def url_for_source_file(filename)
      file = File.expand_path(filename)
      if file.start_with?(Base.code_base_dir)
        file[Base.code_base_dir.length..-1]
      elsif file.start_with?(Base.spec_base_dir)
        url_for_spec(file[(Base.spec_base_dir.length + 1)..-1])
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