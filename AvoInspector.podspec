#
# Be sure to run `pod lib lint AvoInspector.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AvoInspector'
  s.version          = '0.9.5'
  s.summary          = 'Avo Inspector iOS SDK'

  s.description      = <<-DESC
A powerful suite of features that analyze your current state of tracking and guide you from your current, messy taxonomy to a more consistent and reliable tracking process across your teams, products, and platforms.
                       DESC

  s.homepage         = 'https://github.com/avohq/ios-datascope'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Avo (https://www.avo.app)' => 'friends@avo.app' }
  s.source           = { :git => 'https://github.com/avohq/ios-datascope.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'AvoInspector/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AvoInspector' => ['AvoInspector/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  
  s.dependency 'IosAnalyticsDebugger', '~> 1.1.2'
end
