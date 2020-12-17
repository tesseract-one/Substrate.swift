Pod::Spec.new do |s|
  s.name             = 'Substrate'
  s.version          = '0.0.1'
  s.summary          = 'Swift APIs for Polkadot and any Substrate-based chain.'

  s.homepage         = 'https://github.com/tesseract-one/Substrate.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Substrate.swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '12.0'
  
  s.swift_versions = ['5', '5.1', '5.2']
  
  s.module_name = 'Substrate'

  s.subspec 'Polkadot' do |ss|
    ss.source_files = 'Sources/Polkadot/**/*.swift'

    ss.dependency 'Substrate/Primitives'
    ss.dependency 'Substrate/RPC'
    
    ss.test_spec 'PolkadotTests' do |test_spec|
      test_spec.source_files = 'Tests/PolkadotTests/**/*.swift'
    end
  end

  s.subspec 'Primitives' do |ss|
    ss.source_files = 'Sources/Primitives/**/*.swift'

    ss.dependency 'Substrate/CBlake2b'
    ss.dependency 'ScaleCodec', '~> 0.1'
    ss.dependency 'xxHash-Swift', '~> 1.1'
    
    ss.test_spec 'PrimitivesTests' do |test_spec|
      test_spec.source_files = 'Tests/PrimitivesTests/**/*.swift'
    end
  end
  
  s.subspec 'RPC' do |ss|
    ss.source_files = 'Sources/RPC/**/*.swift'

    ss.dependency 'TesseractWebSocket', '~> 0.0.1'
    
    ss.test_spec 'RPCTests' do |test_spec|
      test_spec.dependency 'Serializable.swift', '~> 0.2'
      test_spec.source_files = 'Tests/RPCTests/**/*.swift'
    end
  end
  
  s.subspec 'CBlake2b' do |ss|
    ss.source_files = 'Sources/CBlake2b/**/*.{h,c}'
    ss.public_header_files = 'Sources/CBlake2b/include/*.h'
  end

  s.default_subspecs = 'Polkadot'
end
