Gem::Specification.new do |s|
  s.name = %q{screw_server}
  s.version = "0.1.1"
  s.authors = ["Kristian Hanekamp", "Infopark AG"]
  s.description = %q{Screw Server - easy javascript unit tests}
  s.email = %q{kristian.hanekamp@infopark.de}
  s.files =
    Dir.glob("{lib,assets,bin,views}/**/*") +
    ["Gemfile.run", "Gemfile.run.lock", "screw_server.gemspec"]
  s.summary = %q{Screw Server}

  s.add_dependency("json", "=1.4.3")
  s.add_dependency("haml", "= 3.0.13")
  s.add_dependency("bundler", "= 1.0.7")

  # sinatra and dependencies
    s.add_dependency("rack", "= 1.1.0")
  s.add_dependency("sinatra", "= 1.0")

  # thin and dependencies
    s.add_dependency("daemons", "= 1.0.10")
    s.add_dependency("eventmachine", "= 0.12.10")
  s.add_dependency("thin", "= 1.2.7")

  s.executables  = ['screw_server']
end