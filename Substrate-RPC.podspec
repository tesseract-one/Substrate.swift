Pod::Spec.new do |s|
  s.name             = 'Substrate-RPC'
  s.version          = '999.99.9'
  s.summary          = 'JsonRPC Client for Substrate Swift SDK'
  s.homepage         = 'https://github.com/tesseract-one/Substrate.swift'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Substrate.swift.git', :tag => s.version.to_s }
  
  s.module_name      = 'SubstrateRPC'
  s.swift_version    = '5.7'

  base_platforms     = { :ios => '14.0', :osx => '11.0', :tvos => '14.0' }
  s.platforms        = base_platforms.merge({ :watchos => '7.0' })

  s.source_files     = 'Sources/RPC/**/*.swift'

  s.dependency 'Substrate', "#{s.version}"
  s.dependency 'JsonRPC.swift', '~> 0.2.3'
  s.dependency 'Serializable.swift', '~> 0.3.1'
  
  s.test_spec 'IntegrationTests' do |ts|
    ts.platforms = base_platforms
    ts.dependency 'Substrate-Keychain', "#{s.version}"
    ts.source_files = 'Tests/IntegrationTests/**/*.swift'
  end
end
