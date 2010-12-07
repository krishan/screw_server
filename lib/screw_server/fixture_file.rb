module ScrewServer
  class FixtureFile
    attr_reader :name

    def self.base_dir
      File.join(SpecFile.base_dir, "fixtures")
    end

    def initialize(name)
      @name = name
    end

    def filename
      "#{SpecFile.base_dir}/fixtures/#{name}.html"
    end
  end
end