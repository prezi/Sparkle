Pod::Spec.new do |s|
  s.name        = "Sparkle"
  s.version     = "1.21.2"
  s.summary     = "A software update framework for macOS"
  s.description = "Sparkle is an easy-to-use software update framework for Cocoa developers."
  s.homepage    = "https://prezi.com"
  s.license     = { :type => "Commercial", :text => "See https://prezi.com/terms-of-use/" }
  s.authors     = "Prezi"

  s.platform = :osx, '10.13'

  s.source   = { :git => "https://github.com/prezi/Sparkle.git", :tag => "#{s.version}"}
  s.source_files = 'Sparkle.framework/Versions/A/Headers/*.h'

  s.preserve_paths = 'bin/*'
  s.public_header_files = 'Sparkle.framework/Versions/A/Headers/*.h'
  s.vendored_frameworks  = 'Sparkle.framework'
  s.xcconfig            = {
    'FRAMEWORK_SEARCH_PATHS' => '"${PODS_ROOT}/Sparkle"',
    'LD_RUNPATH_SEARCH_PATHS' => '@loader_path/../Frameworks'
  }
  s.requires_arc        = true
end
