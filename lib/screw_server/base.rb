module ScrewServer
  module Base
    def self.spec_base_dir=(d)
      raise "expected a directory with javascript specs under #{d}" unless File.exists?(d)
      @spec_base_dir = d
    end

    def self.spec_base_dir
      @spec_base_dir
    end

    def self.code_base_dir=(d)
      raise "expected a directory with javascript code under #{d}" unless File.exists?(d)
      @code_base_dir = d
    end

    def self.code_base_dir
      @code_base_dir
    end
  end
end