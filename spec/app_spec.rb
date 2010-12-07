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
  end
end