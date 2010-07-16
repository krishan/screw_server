class JslintSuite

  attr_accessor :name, :file_list, :options

  def initialize(n)
    @name = n
  end

  def file_list=(v)
    @file_list = v.map { |file| File.expand_path(file) }
  end

  def self.suites_from(file)
    @suites = []
    eval(IO.read(file), binding, file)
    @suites
  end

  private

  def self.jslint(name)
    suite = JslintSuite.new(name)
    yield suite
    @suites << suite
  end

end