cask "displayfit" do
  version "2026.05.13.001"
  sha256 "1ada542a4a086a438eb3b7cc5ad925b7df0099d420c731e7e5d0966b79f56e54"

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
