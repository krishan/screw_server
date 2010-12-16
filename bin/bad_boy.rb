# use this script to test if screw_server can outwit "bundle exec"
require "rubygems"
require "bundler/setup"

load(File.join(File.dirname(__FILE__), "screw_server"))