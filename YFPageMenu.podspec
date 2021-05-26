Pod::Spec.new do |s|
s.name         = "YFPageMenu"
s.version      = "1.0.0"
s.summary      = "Tools for OC"
s.description  = <<-DESC
Tools for OC private.
DESC
s.homepage     = "https://github.com/BigShow1949/YFPageMenu.git"
s.license      = { :type => 'MIT', :file => 'LICENSE' }
s.author       = { "BigShow1949" => "1029883589@qq.com" }
s.source       = { :git => "https://github.com/BigShow1949/YFPageMenu.git", :tag => "#{s.version}" }
s.ios.deployment_target = '9.0'
s.source_files = 'YFPageMenu/**/*.{h,m}'
s.public_header_files = 'YFPageMenu/**/*.{h}'
s.requires_arc = true

end
