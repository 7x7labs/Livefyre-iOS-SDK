Pod::Spec.new do |s|
  s.name     = 'ECJWT'
  s.version  = '1.0.0'
  s.license  = 'MIT'
  s.summary  = 'Implementation of JSON Web Token (JWT)'
  s.homepage = 'https://github.com/edgecase/ECJWT'
  s.author   = { '' => '' }

  s.source   = { :git => '.git' }

  s.description = 'An optional longer description of ECJWT.'
  s.source_files = 'ECJWT/*.{h,m}'

  s.requires_arc = true

  s.dependency 'JSONKit', '1.5pre'
end
