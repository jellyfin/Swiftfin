use_frameworks!
inhibit_all_warnings!
def shared_pods
  pod 'SwiftGen'
end

target 'JellyfinPlayer iOS' do
  platform :ios, '15.0'
  shared_pods
  pod 'google-cast-sdk'
  pod 'MobileVLCKit'
  pod 'SwizzleSwift'
end
target 'JellyfinPlayer tvOS' do
  platform :tvos, '15.0'
  shared_pods
  pod 'TVVLCKit'
end
target 'WidgetExtension' do
  shared_pods
end
