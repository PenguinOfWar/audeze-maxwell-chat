# audeze-maxwell-chat

Exposes the Audeze Maxwell Game and Chat outputs as separate PipeWire
sinks on Linux, replicating the split available on Windows without requiring
Audeze software or sacrificing microphone support.

## Background

The Maxwell Dongle exposes two USB audio playback interfaces. On Windows, these
appear automatically as separate "Game" and "Chat" devices. On Linux, PipeWire
selects the standard stereo profile which only activates the first interface
(Chat), leaving the second (Game) unused.

This configuration adds a WirePlumber Lua script that watches for the Maxwell
Dongle to appear, then creates a proper node for the Game interface.

The standard profile remains active so the microphone and volume controls work 
normally (there is a "Pro Audio" option that activates both interfaces by 
default, but when using this I had low volume issues and frequent microphone
cutouts - the standard profile seems to the most reliable). 

Both sinks are renamed to match Windows behaviour.

The chat mix knob on the headset blends the two streams within the headset - turn it
toward the chat icon to reduce game volume relative to chat.

The device number is resolved from device properties, so the config survives 
reboots, USB port changes, and other devices being added or removed.

## Requirements (i.e. what I have on my systems when I tested this out)

- PipeWire with WirePlumber 0.5.x
- Audeze Maxwell ver. 1 headset with USB dongle

Hardware IDs:

```bash
VENDOR_ID="0x3329"
PRODUCT_ID="0x4b19"
```

## Installation

```bash
git clone https://github.com/yourname/audeze-maxwell-chat
cd audeze-maxwell-chat
chmod +x install-maxwell-chat.sh
./install-maxwell-chat.sh
```

The script is safe to run multiple times. It does not modify any system files. 
Everything goes into:

- `~/.config/wireplumber/wireplumber.conf.d/`
- `~/.local/share/wireplumber/scripts/`

The Game sink has no hardware volume control on the Audeze Maxwell, so the
install script sets the mixer level to maximum and saves the state via `alsactl`. 
Volume on each sink can then be adjusted in software via your system's volume 
control panel.

## What it installs

```
~/.config/wireplumber/
├── wireplumber.conf.d/
    └── 51-audeze-maxwell-chat.conf   # loads the script, locks profile, renames sinks

~/.local/share/wireplumber/
└── scripts/
    └── audeze-maxwell-chat.lua       # creates the Game sink on device plug
```

## Usage

After installation you will see two Audeze sinks in your audio settings:

| Sink | Use for |
|------|---------|
| Audeze Maxwell Chat | Matrix, Discord, any chat application |
| Audeze Maxwell Game | Game audio, music, etc. |

Point applications at the appropriate sink.

The chat mix knob on the headset controls the... mix.

## Uninstalling

```bash
rm ~/.config/wireplumber/wireplumber.conf.d/51-audeze-maxwell-chat.conf
rm ~/.local/share/wireplumber/scripts/audeze-maxwell-chat.lua
systemctl --user restart wireplumber
```

## Tested on

- Bazzite with PipeWire 1.6.4 / WirePlumber 0.5.12

## Known issues

- None, but I'm keen to hear of any issues you encounter.

## Disclaimer

This script is provided as-is, without any warranty. Use at your own risk.

*For more information, please reread this readme.*

*&copy; 1973 Scarfolk Council*
