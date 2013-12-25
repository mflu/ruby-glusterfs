Gem::Specification.new do |s|
  s.name = "ruby_glusterfs"
  s.version = "0.0.1"
  s.platform = Gem::Platform::RUBY
  s.summary = "Glusterfs Admin Cli Wrapper for Miaoyun Agent"
  s.description = "Glusterfs Admin Cli Wrapper for Miaoyun Agent"
  s.homepage = "http://www.iqiyi.com"
  s.files = Dir.glob("lib/**/*")
  s.require_path = [ "lib" ]
  s.author = "IQIYI Cloud Storage Team"
  s.email = "lumingfan@qiyi.com"

  s.add_dependency 'subexec'
end
