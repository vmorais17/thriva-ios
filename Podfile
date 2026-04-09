platform :ios, '16.0'
use_frameworks!

target 'Cooking App' do
  pod 'MediaPipeTasksGenAI', '0.10.24'
  pod 'MediaPipeTasksGenAIC', '0.10.24'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
