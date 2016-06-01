Pod::Spec.new do |s|

  s.name      = "BANetworking"
  s.version   = "1.0.1"
  s.summary   = "MIT"
  s.homepage  = "https://github.com/beyondabel/BANetworking"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = {
    "beyondabel" => "beyondabel@gmail.com"
  }
  
  s.ios.deployment_target = '7.0'

  s.source = { :git => "https://github.com/beyondabel/BANetworking.git", :tag => "1.0.1" }
  s.source_files = "BANetworking/BANetworking/**/*.{m,h}"
end
