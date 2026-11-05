cask "mactethering" do
  version "1.5"
  sha256 "586d7a4b6471ae10354045aeb83a723f3c45922a14dc940b1722b57d192a42aa"

  url "https://github.com/2Bro-Dev/MacTethering/releases/download/v#{version}/MacTethering.dmg"
  name "MacTethering"
  desc "Android USB tethering without kernel extensions"
  homepage "https://mactethering.com/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "MacTethering.app"

  # The app installs a passwordless sudo rule for its privileged CLI on first
  # launch; uninstalling the app has to take that rule with it. usb-modem is
  # the pre-rename name, still present on machines that ran older builds.
  uninstall quit:   "dev.2bro.MacTethering",
            delete: [
              "/etc/sudoers.d/mactethering",
              "/etc/sudoers.d/usb-modem",
            ]

  zap trash: [
    "~/Library/Application Support/MacTethering",
    "~/Library/Preferences/dev.2bro.MacTethering.plist",
  ]
end
