require File.join(File.dirname(__FILE__), 'spec_helper')
require "screw_server/app"
require 'rack/test'

module ScrewServer
  describe App do
    include Rack::Test::Methods

    before do
      App.set :environment, :test
    end

    def app
      App
    end

    describe "serving spec files" do
      it "should serve the spec files" do
        get "/#{App::SPEC_BASE_URL}/example_spec.js"
        last_response.should be_ok
        last_response.body.should == File.read(fixture_spec_file("example_spec.js"))
      end

      it "should not serve files outside of the given directory" do
        relative_path_to_secret_file = "../do_not_serve.txt"
        get "/#{App::SPEC_BASE_URL}/#{relative_path_to_secret_file}"
        last_response.should_not be_ok
        last_response.body.should_not include(File.read(fixture_spec_file(relative_path_to_secret_file)))
      end
    end

    describe "serving screw server's assets" do
      it "should serve the assets" do
        get "/#{App::ASSET_BASE_URL}/screw.css"
        last_response.should be_ok
        last_response.body.should == File.read(File.join(File.dirname(__FILE__), '..', 'assets', 'screw.css'))
      end

      it "should not serve files outside of the given directory" do
        relative_path_to_secret_file = "../spec/fixtures/do_not_serve.txt"
        secret_file = File.join(File.dirname(__FILE__), "..", "assets", relative_path_to_secret_file)

        get "/#{App::ASSET_BASE_URL}/#{relative_path_to_secret_file}"
        last_response.should_not be_ok
        last_response.body.should_not include(File.read(secret_file))
      end
    end

    describe "start page" do
      it "should show a list of all specs" do
        get "/"
        last_response.should be_ok
        last_response.body.should include("/run/example")
      end

      it "should contain a special notice when no specs are found" do
        ScrewServer::Base.spec_base_dir = File.join(ScrewServer::Base.spec_base_dir, '..', 'spec_empty')
        get "/"
        last_response.should be_ok
        last_response.body.should include("does not contain any specs")
        last_response.body.should include(ScrewServer::Base.spec_base_dir)
        last_response.body.should include("should be simple to write")
      end
    end

    describe "running all specs" do
      it "should ignore a missing jslint.rb" do
        use_spec_directory('spec_without_jslint')
        get "/run"
        last_response.should be_ok
      end

      it "should process a given jslint.rb and include it's data as javascript" do
        get "/run"
        last_response.should be_ok
        last_response.body =~ /Screw\.jslint_suites = (.+);/
        JSON.parse($1).should == [
          {
            "file_list" => ["/example.js"],
            "options" => JslintSuite::DEFAULT_OPTIONS.merge("predef" => ["window"])
          }, {
            "file_list" => ["/___screw_specs___/example_spec.js"],
            "options" => JslintSuite::DEFAULT_OPTIONS
          }
        ]
      end

      it "should show a warning when a spec_helper.js is missing" do
        use_spec_directory('spec_without_spec_helper')
        get "/run"
        last_response.should be_ok
        last_response.body.should include(ScrewServer::Base.spec_base_dir)
        last_response.body.should include("Cannot find")
        last_response.body.should include("adjust the url below")
      end
    end
  end
end