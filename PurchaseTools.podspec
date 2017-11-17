Pod::Spec.new do |s|
s.name           = 'PurchaseTools'
s.version        = '0.2.1'
s.summary        = "Purchase helper to make your life easier."
s.homepage       = "https://github.com/VladasZ/PurchaseTools"
s.author         = { 'Vladas Zakrevskis' => '146100@gmail.com' }
s.source         = { :git => 'https://github.com/VladasZ/PurchaseTools.git', :tag => s.version }
s.ios.deployment_target = '9.0'
s.source_files   = 'Sources/**/*.swift'
s.license        = 'MIT'
end
