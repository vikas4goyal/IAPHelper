#
# Be sure to run `pod lib lint IAPHelper.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'IAPHelper'
  s.version          = '0.1.1'
  s.summary          = 'IAPHelper is In-App purchage Helper'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
IPAHelper is INAPP PURCHASE Helper for IOS
                       DESC

  s.homepage         = 'https://github.com/vikas4goyal.com/IAPHelper'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'vikas goyal' => 'vikas4goyal@gmail.com' }
  s.source           = { :git => 'https://github.com/vikas4goyal/IAPHelper.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'IAPHelper/Classes/**/*'
  
  # s.resource_bundles = {
  #   'IAPHelper' => ['IAPHelper/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
    s.frameworks = 'UIKit','StoreKit'
    s.dependency 'SwiftyStoreKit','0.9.2'
    s.dependency 'PopupDialog','0.5.4'
end
