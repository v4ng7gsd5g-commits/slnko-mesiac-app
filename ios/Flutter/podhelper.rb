def flutter_install_all_ios_pods(ios_application_path = nil)
  flutter_application_path = ios_application_path || File.join('..', '..')
  podfile_path = File.expand_path(File.join(flutter_application_path, 'ios', 'Podfile'))
  podfile_dir = File.dirname(podfile_path)

  generated_xcode_build_settings_path = File.join(podfile_dir, 'Flutter', 'Generated.xcconfig')
  unless File.exist?(generated_xcode_build_settings_path)
    raise "Generated.xcconfig not found. Run 'flutter pub get' first."
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/\AFLUTTER_ROOT=(.*)\z/)
    if matches
      flutter_root = matches[1]
      podhelper_path = File.join(flutter_root, 'packages', 'flutter_tools', 'bin', 'podhelper.rb')
      load podhelper_path
      flutter_additional_ios_build_settings(target) if defined? flutter_additional_ios_build_settings
      return
    end
  end
end