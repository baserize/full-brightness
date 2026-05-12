cask "displayfit" do
  version "2026.05.08.001"
  sha256 "20b919b8bcdb86dabab8106d49f27a46b6ffd4f73e9aab94a73bd396771e05e8"

  url "https://github.com/baserize/displayfit/releases/download/#{version}/DisplayFit-#{version}.dmg"
  name "DisplayFit"
  desc "Fit display brightness and monitor layouts for connected screens"
  homepage "https://github.com/baserize/displayfit"

  depends_on macos: ">= :tahoe"

  app "DisplayFit.app"

  zap trash: [
    "~/Library/Group Containers/group.com.baserize.displayfit",
    "~/Library/Preferences/com.baserize.displayfit.plist",
  ]
end
