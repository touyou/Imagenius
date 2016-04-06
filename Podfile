# Uncomment this line to define a global platform for your project
platform :ios, '8.0'
# Uncomment this line if you're using Swift
use_frameworks!

target 'Imagenius' do
    pod 'DZNEmptyDataSet'
    pod 'SWTableViewCell', '~> 0.3.7'
    pod 'TTTAttributedLabel'
    pod 'Google-Mobile-Ads-SDK', '~> 7.0'
    pod 'KTCenterFlowLayout'
    pod 'RegExCategories', '~> 1.0'
    pod 'SDWebImage'
    pod 'RxSwift'
    pod 'RxCocoa'
    pod 'RxBlocking'
#    pod 'RxTests'
end

target 'ImageniusTests' do

end

target 'ImageniusUITests' do

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end

