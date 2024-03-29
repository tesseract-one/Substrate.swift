Pod::Spec.new do |s|
  s.name             = 'Substrate'
  s.version          = '999.99.9'
  s.summary          = 'Swift SDK for Polkadot and other Substrate-based chains'
  s.homepage         = 'https://github.com/tesseract-one/Substrate.swift'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Substrate.swift.git', :tag => s.version.to_s }
  
  s.module_name      = 'Substrate'
  s.swift_version    = '5.7'

  base_platforms     = { :ios => '14.0', :osx => '11.0', :tvos => '14.0' }
  s.platforms        = base_platforms.merge({ :watchos => '7.0' })
  
  s.source_files     = 'Sources/Substrate/**/*.swift'
    
  s.dependency 'Blake2', '~> 0.2.0'
  s.dependency 'ScaleCodec', '~> 0.3.1'
  s.dependency 'Tuples', '~> 0.1.0'
  s.dependency 'ContextCodable.swift', '~> 0.1.0'
  s.dependency 'xxHash', '~> 0.1.0'
  s.dependency 'Serializable.swift', '~> 0.3.1'
  s.dependency 'Numberick', '~> 0.16.0'

  s.test_spec 'SubstrateTests' do |ts|
    ts.platforms = base_platforms
    ts.source_files = 'Tests/SubstrateTests/**/*.swift'
    ts.resource = 'Tests/SubstrateTests/Resources'
  end
end
