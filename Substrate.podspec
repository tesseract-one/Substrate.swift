Pod::Spec.new do |s|
  s.name             = 'Substrate'
  s.version          = '0.0.1'
  s.summary          = 'Swift APIs for Polkadot and any Substrate-based chain.'

  s.description      = <<-DESC
Swift APIs for Polkadot and any Substrate-based chain.
                       DESC

  s.homepage         = 'https://github.com/tesseract-one/Substrate.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Substrate.swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  
  s.swift_versions = ['5', '5.1', '5.2']
  
  s.module_name = 'Substrate'

  s.subspec 'Polkadot' do |ss|
    ss.source_files = 'Sources/Polkadot/**/*.swift'

    ss.dependency 'Substrate/Primitives'
  end

  s.subspec 'Primitives' do |ss|
    ss.source_files = 'Sources/Primitives/**/*.swift'

    ss.dependency 'Substrate/CBlake2b'
    ss.dependency 'ScaleCodec', '~> 0.1'
  end
  
  s.subspec 'CBlake2b' do |ss|
    ss.source_files = 'Sources/CBlake2b/**/*.c'
    ss.public_header_files = 'Sources/CBlake2b/inclide/*.h'
  end

  s.default_subspecs = 'Polkadot'
end
