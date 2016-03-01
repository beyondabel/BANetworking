Pod::Spec.new do |s|


  s.name         = 'BANetworking'
  s.version      = "1.0.0"
  s.summary      = "A delightful iOS and OS X networking framework."

  s.homepage     = "https://github.com/beyondabel/BANetworking"

  s.license      = 'MIT'

  s.author             = { "beyondabel" => "beyondabel@gmail.com" }
  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/beyondabel/BANetworking.git", :tag => s.version, :submodules => true }

  s.source_files  = "BANetworking/BANetworking/Common/BANetworking.h"

  s.public_header_files = "BANetworking/BANetworking/Common/BANetworking.h"

end
