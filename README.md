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
brew tap 2Bro-Dev/tap
brew trust 2Bro-Dev/tap
brew install mactethering
```

Homebrew asks for that `brew trust` line before it will load a cask from any
third-party tap; without it the install stops with a refusal.

Or download the disk image from [Releases](../../releases/latest) and drag
MacTethering to Applications.

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

## License

MacTethering is free to use. A one-time $9 license at
[mactethering.com](https://mactethering.com/buy/) is a thank-you, not a paywall.
