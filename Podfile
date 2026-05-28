# Uncomment the next line to define a global platform for your project
platform :osx, '11.5'

target 'cie-pkcs11' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for cie-pkcs11

  #pod 'OpenSSL-Static', '1.0.2.c1'
pod 'OpenSSL-Universal'
  #pod 'OpenSSL-Static', :git => 'https://github.com/bruceyibin/OpenSSL.git', :branch => :master

end

target 'CIE ID' do
    # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
    use_frameworks!
    
    #pod 'FlatButton'
    pod 'SSZipArchive'
    
end

# Fix for CocoaPods <= 1.11.x: readlink returns a relative path during Archive,
# causing rsync to fail. Replace with realpath to get the absolute path.
post_install do |installer|
  Dir.glob(File.join(installer.sandbox.root, "Target Support Files", "**", "*-frameworks.sh")).each do |script|
    content = File.read(script)
    patched = content.gsub(
      'source="$(readlink "${source}")"',
      'source="$(realpath "${source}")"'
    )
    File.write(script, patched) if patched != content
  end
end


