# Cow Anti-Cheat
This plugin is designed to be a drag and drop anti-cheat. While making and testing this plugin I have had multiple users who spent hours on end trying to cause false positives, I also have the plugin running on around 5 1v1 arena servers and a couple of retake servers with no false positives. Through this testing we can assert that ban false positives are nearly impossible to produce.

# Dependencies
- Sourcebans++ (optional)

# Detections
    Aimbot
    Triggerbot
    Silent-Strafe
    Bhop
    Macro/Hyperscroll
    AutoShoot
    Instant Defuse
    Perfect Strafe
    Backtrack Elimination
    AHK/MSL Strafe

# ConVars
There is a config generated (/cfg/CowAntiCheat/CowAntiCheat.cfg) \n
I highly recommend leaving ban/log thresholds at their current values to further avoid false positives.

# Commands
- sm_bhopcheck / !bhopcheck

# Installation
    Install CowAntiCheat.smx into the /plugins/ folder inside of Sourcemod on your game server
    Load the plugin manually, or change maps
    Edit the Config (/cfg/CowAntiCheat/CowAntiCheat.cfg)
    Watch the bans roll in!
