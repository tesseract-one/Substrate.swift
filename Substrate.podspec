Pod::Spec.new do |s|
  s.name             = 'Substrate'
  s.version          = '0.0.1'
  s.summary          = 'Swift APIs for Polkadot and any Substrate-based chain.'

  s.homepage         = 'https://github.com/tesseract-one/Substrate.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Substrate.swift.git', :tag => s.version.to_s }

  test_platforms = {
    :ios => '13.0',
    :osx => '10.15',
    :tvos => '13.0'
  }

  s.platforms = test_platforms # test_platforms.merge({ :watchos => '6.0' }) # xxHash doesn't support watchOS
  
  s.swift_version = '5.7'
  
  s.module_name = 'Substrate'
  
  s.subspec 'Keychain' do |ss|
    ss.source_files = 'Sources/Keychain/**/*.swift'

    ss.dependency 'Substrate/Substrate'
    ss.dependency 'UncommonCrypto', '~> 0.1.0'
    ss.dependency 'Bip39.swift', '~> 0.1.0'
    ss.dependency 'Sr25519/Sr25519', '~> 0.1.0'
    ss.dependency 'Sr25519/Ed25519', '~> 0.1.0'
    ss.dependency 'CSecp256k1', '~> 0.1.0'
    
    ss.test_spec 'KeychainTests' do |test_spec|
      test_spec.platforms = test_platforms
      test_spec.source_files = 'Tests/KeychainTests/**/*.swift'
    end
  end
  
  s.subspec 'RPC' do |ss|
    ss.source_files = 'Sources/RPC/**/*.swift'

    ss.dependency 'Substrate/Substrate'
    ss.dependency 'JsonRPC.swift', '~> 0.2.0'
    ss.dependency 'Serializable.swift', '~> 0.2.0'
  end
  
  s.subspec 'Substrate' do |ss|
    ss.source_files = 'Sources/Substrate/**/*.swift'
    
    ss.dependency 'Blake2', '~> 0.1.0'
    ss.dependency 'ScaleCodec', '~> 0.3.0'
    ss.dependency 'xxHash-Swift', '~> 1.1.0'
    ss.dependency 'Serializable.swift', '~> 0.2.0'
    
    ss.test_spec 'SubstrateTests' do |test_spec|
      test_spec.dependency 'Substrate/Keychain'
      test_spec.dependency 'Substrate/RPC'
      test_spec.platforms = test_platforms
      test_spec.source_files = 'Tests/SubstrateTests/**/*.swift'
    end
  end

  s.default_subspecs = 'Substrate', 'RPC'
end
