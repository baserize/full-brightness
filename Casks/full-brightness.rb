cask "full-brightness" do
  version "2026.05.08.001"
  sha256 "516c8faacc89e967abc5c65b0f35ac99da567b1b4fa4e560957c8b52a38002c7"

  url "https://github.com/baserize/full-brightness/releases/download/#{version}/Full-Brightness-#{version}.zip"
  name "Full Brightness"
  desc "Set supported displays to a chosen brightness level"
  homepage "https://github.com/baserize/full-brightness"

  app "Full Brightness.app"

  zap trash: [
    "~/Library/Group Containers/group.com.baserize.fullbrightness",
    "~/Library/Preferences/com.baserize.fullbrightness.plist",
  ]
end
