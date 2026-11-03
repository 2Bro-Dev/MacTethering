# MacTethering

Android USB tethering for macOS, in userspace. No kernel extension, and System
Integrity Protection stays on.

macOS does not speak RNDIS, the protocol most Android phones use for USB
tethering. MacTethering supplies that missing piece: it talks to the phone over
libusb and creates a `utun` interface, with the RNDIS handling, DHCP client and
ARP all in userspace. A menu bar app shows the phone, the assigned IP, live
throughput and ping.

## Install

```bash
brew tap 2Bro-Dev/mactethering https://github.com/2Bro-Dev/MacTethering
brew trust 2Bro-Dev/mactethering
brew install mactethering
```

This repository is the Homebrew tap: the cask lives in
[`Casks/mactethering.rb`](Casks/mactethering.rb). The URL in the first line is
needed because the repository is not named `homebrew-*`. Homebrew asks for the
`brew trust` line before it will load a cask from any third-party tap; without
it the install stops with a refusal.

Or download the disk image from [Releases](../../releases/latest) and drag
MacTethering to Applications.

Installed from the old `2Bro-Dev/tap`? Switch once and future updates arrive
here:

```bash
brew untap 2Bro-Dev/tap
brew tap 2Bro-Dev/mactethering https://github.com/2Bro-Dev/MacTethering
brew trust 2Bro-Dev/mactethering
```

## Requirements

- macOS 13 Ventura or later
- An Android phone that exposes USB tethering over RNDIS (the common case)

## Using it

1. Connect the phone by USB and turn on USB tethering
   (Settings → Connections → Mobile Hotspot → USB tethering).
2. Open MacTethering from the menu bar and press Connect.

The first launch asks for your administrator password once. The app itself stays
unprivileged; the password installs a `sudoers` rule so the networking helper can
run without prompting on every connection. `brew uninstall mactethering` removes
that rule again.

Full tethering mode also sets the default route and DNS, so all Mac traffic goes
through the phone.

## Releasing

Publish the notarised DMG as a release asset named `MacTethering.dmg` and let
the tag carry the version (`v1.4`). The cask pins
`releases/download/v<version>/MacTethering.dmg`, so it keeps a real `version`
and `sha256` and `brew upgrade` sees new releases. The website's Download
button is a permanent redirect onto `releases/latest/download/MacTethering.dmg`
and never needs touching.

After publishing, point the cask at the new release:

```bash
bin/bump-cask.sh                               # reads the latest release asset
bin/bump-cask.sh path/to/MacTethering.dmg      # or checks a build before upload
```

It takes the version from the app bundle and the checksum from the file, and
refuses what `brew install` would refuse: an HTML error page posing as an
image, or a build that is not notarised. Notarisation changes the file, so bump
from the DMG you actually uploaded. CI runs `brew style` and `brew audit` on
every push.

## License

MacTethering is free to use. A one-time $9 license at
[mactethering.com](https://mactethering.com/buy/) is a thank-you, not a paywall.
