cask "displayfit" do
  version "2026.05.13.001"
  sha256 "52b4d27c623b85e44b1fcb36f904f49908eecd02e8f6394723695017a6b3ff98"

  url "https://github.com/baserize/displayfit/releases/download/#{version}/DisplayFit-#{version}.dmg"
  name "DisplayFit"
  desc "Fit display brightness and monitor layouts for connected screens"
  homepage "https://github.com/baserize/displayfit"

  depends_on macos: :tahoe

  app "DisplayFit.app"

  zap trash: [
    "~/Library/Group Containers/group.com.baserize.displayfit",
    "~/Library/Preferences/com.baserize.displayfit.plist",
  ]
end
