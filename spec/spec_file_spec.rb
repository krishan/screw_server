require File.join(File.dirname(__FILE__), 'spec_helper')
require "screw_server/spec_file"

module ScrewServer
  describe SpecFile do
    describe "delivering a list of all files the spec uses" do
      let(:example_spec) { SpecFile.new("example") }

      it "should include all required code files" do
        example_spec.used_files.should include(
          fixture_code_file("example.js"),
          fixture_code_file("foo.js")
        )
      end

      it "should include the spec helper" do
        example_spec.used_files.should include(fixture_spec_file("spec_helper.js"))
      end

      it "should include the fixtures that the spec uses" do
        example_spec.used_files.should include(fixture_spec_file("fixtures/example.html"))
      end
    end

    describe "getting a list of all required scripts" do
      it "should deliver a list of all scripts required by the spec" do
        SpecFile.new("example").required_scripts.should include("example.js", "foo.js")
      end

      it "should include the scripts required by the spec helper" do
        SpecFile.new("example").required_scripts.should include("global.js")
      end
    end
  end
end