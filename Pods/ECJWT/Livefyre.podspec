Pod::Spec.new do |s|
  s.name     = 'Livefyre'
  s.version  = '1.0.0'
  s.license  = 'MIT'
  s.summary  = "A client library for Livefyre's API"
  s.homepage = 'https://github.com/splap/lf-client'
  s.author   = { '' => '' }

  s.source   = { :git => 'http://github.com/splap/lf-client.git' }
  s.description = 'An optional longer description of Livefyre.'

  s.platform = :ios

  s.source_files = 'LivefyreClient', 'ECJWT'

  # header_mappings_dir was added after 0.5.1 was released
  # s.header_mappings_dir = 'LivefyreClient'
  def s.copy_header_mapping(from)
    "LivefyreClient/#{from.basename}"
  end

  s.frameworks = 'MobileCoreServices', 'SystemConfiguration', 'CFNetwork', 'Foundation'

  s.requires_arc = true

  s.dependency 'ASIHTTPRequest', '~> 1.8'
  s.dependency 'JSONKit', '~> 1.4'
end
