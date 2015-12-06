Pod::Spec.new do |s|
    s.name        = "Dynamo"
    s.version     = "4.0"
    s.summary     = "High Performance 100% Swift Web server supporting dynamic content"
    s.homepage    = "https://github.com/johnno1962/Dynamo"
    s.social_media_url = "https://twitter.com/Injection4Xcode"
    s.documentation_url = "http://johnholdsworth.com/dynamo/docs/"
    s.license     = { :type => "MIT" }
    s.authors     = { "johnno1962" => "dynamo@johnholdsworth.com" }

    s.osx.deployment_target = "10.9"
    s.ios.deployment_target = "8.0"
    s.source   = { :git => "https://github.com/johnno1962/Dynamo.git", :tag => s.version }
    s.source_files = "Sources/*.swift"
end
