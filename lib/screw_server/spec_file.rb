require "screw_server/fixture_file"

module ScrewServer
  class SpecFile
    def self.base_dir=(d)
      raise "spec directory not found under #{d}" unless File.exists?(d)
      @base_dir = d
    end

    def self.base_dir
      @base_dir
    end

    def self.all
      Dir.glob(File.join(SpecFile.base_dir, "*_spec.js")).sort.map do |file|
        SpecFile.new(file.gsub("#{SpecFile.base_dir}/", "").gsub("_spec.js", ""))
      end
    end

    def self.latest
      SpecFile.all.sort{ |a, b| a.last_changed <=> b.last_changed }.last
    end

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def filename
      File.join(SpecFile.base_dir, full_name)
    end

    def full_name
      name + "_spec.js"
    end

    def used_fixtures
      scan_for_statement("use_fixture", filename).map {|name| FixtureFile.new(name) }
    end

    def fixture_hash
      used_fixtures.inject({}) do |result, fixture|
        result.merge(fixture.name => File.read(fixture.filename))
      end
    end

    def required_scripts
      required_files_in(File.join(SpecFile.base_dir, "spec_helper.js")) + required_files_in(filename)
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
        required_scripts.map {|script| Base.code_base_dir + script}
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
end