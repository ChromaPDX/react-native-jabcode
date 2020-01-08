require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'react-native-jabcode'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.source         = { :git => package['repository']['url'], :tag => "v#{s.version}" }

  s.requires_arc   = true
  s.platform       = :ios, '9.0'

  s.subspec "core" do |ss|
    ss.source_files = "jabcode/src/jabcode/**/*.{h,c}"
  end

  s.subspec "reader" do |ss|
    ss.source_files = "jabcode/src/jabreader.c"
  end

  s.default_subspecs = "core", "reader"

  s.preserve_paths = 'LICENSE', 'README.md', 'package.json'
end