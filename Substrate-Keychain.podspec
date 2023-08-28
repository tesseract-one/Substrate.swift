Pod::Spec.new do |s|
  s.name             = 'Substrate-Keychain'
  s.version          = '999.99.9'
  s.summary          = 'Sr25519/Ed25519/ECDSA In-Memory Keychain for Substrate Swift SDK'
  s.homepage         = 'https://github.com/tesseract-one/Substrate.swift'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Substrate.swift.git', :tag => s.version.to_s }
  
  s.module_name      = 'SubstrateKeychain'
  s.swift_version    = '5.7'

  base_platforms     = { :ios => '14.0', :osx => '11.0', :tvos => '14.0' }
  s.platforms        = base_platforms # base_platforms.merge({ :watchos => '7.0' }) # xxHash doesn't support watchOS
  
  s.source_files = 'Sources/Keychain/**/*.swift'

  s.dependency 'Substrate', "#{s.version}"
  s.dependency 'UncommonCrypto', '~> 0.1.0'
  s.dependency 'Bip39.swift', '~> 0.1.0'
  s.dependency 'Sr25519/Sr25519', '~> 0.1.0'
  s.dependency 'Sr25519/Ed25519', '~> 0.1.0'
  s.dependency 'CSecp256k1', '~> 0.1.0'
    
  s.test_spec 'KeychainTests' do |ts|
    ts.platforms = base_platforms
    ts.source_files = 'Tests/KeychainTests/**/*.swift'
  end
end
