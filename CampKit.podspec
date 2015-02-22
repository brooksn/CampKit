Pod::Spec.new do |s|
    s.name = 'CampKit'
    s.version = '0.1'
    s.license = 'MIT'
    s.summary = 'Tent social networking in Swift'
    s.homepage = 'https://github.com/brooksn/CampKit'
    s.social_media_url = 'https://brooks.cupcake.is'
    s.authors = { 'Brooks Newberry' => 'mail@brooks.is' }
    s.source = { :git => 'https://github.com/brooksn/CampKit.git', :tag => s.version }

    s.ios.deployment_target = '8.0'
    s.osx.deployment_target = '10.10.0'

    s.source_files = 'CampKit/*.swift'

    s.requires_arc = true

    s.dependency 'SwiftyJSON', '~> 2.1.3'
    s.dependency 'Alamofire', '~> 1.1'
    s.dependency 'KeychainAccess', '~> 1.1.2'
end