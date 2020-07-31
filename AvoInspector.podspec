#
# Be sure to run `pod lib lint AvoInspector.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AvoInspector'
  s.version          = '1.2.2'
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

  s.dependency 'IosAnalyticsDebugger', '~> 1.2.1'
end
