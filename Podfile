use_frameworks!
inhibit_all_warnings!
def shared_pods
  pod 'R.swift'
end

target 'JellyfinPlayer iOS' do
  platform :ios, '14.0'
  shared_pods
  pod 'google-cast-sdk'
  pod 'MobileVLCKit'
end
target 'JellyfinPlayer tvOS' do
  platform :tvos, '14.0'
  shared_pods
  pod 'TVVLCKit'
end