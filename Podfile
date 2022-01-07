use_frameworks!
inhibit_all_warnings!
def shared_pods
  pod 'SwiftGen'
end

target 'Swiftfin iOS' do
  platform :ios, '15.0'
  shared_pods
  pod 'google-cast-sdk'
  pod 'MobileVLCKit'
  pod 'SwizzleSwift'
end
target 'Swiftfin tvOS' do
  platform :tvos, '15.0'
  shared_pods
  pod 'TVVLCKit'
end
target 'Swiftfin Widget' do
  platform :ios, '15.0'
  shared_pods
end
