# Cow Anti-Cheat
This plugin is designed to be a drag and drop anti-cheat. While making and testing this plugin I have had multiple users who spent hours on end trying to cause false positives, I also have the plugin running on around 5 1v1 arena servers and a couple of retake servers with no false positives. Through this testing we can assert that ban false positives are nearly impossible to produce.

# Dependencies
- Sourcebans++ (optional)
- SteamWorks (required)

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
    HourChecker (Kicks Private Profiles)

# ConVars
There is a config generated (/cfg/CowAntiCheat/CowAntiCheat.cfg)<br />
**I highly recommend leaving ban/log thresholds at their current values to further avoid false positives.**

# Commands
- sm_bhopcheck / !bhopcheck

# Installation
    Install CowAntiCheat.smx into the /plugins/ folder inside of Sourcemod on your game server
    Load the plugin manually, or change maps
    Edit the Config (/cfg/CowAntiCheat/CowAntiCheat.cfg)
    Watch the bans roll in!

# ChangeLog
## [1.10] - 2018-02-02
### Added
- Sourcebans++ Optional Dependency
- Added AHK/MSL Strafe Detection
- Added Cvars for AHK/MSL Strafe Detection
- Added Support for older Sourcebans++ versions

## [1.11] - 2018-02-03
### Added
- AHK/MSL Strafe Detection Updated.

## [1.12] - 2018-02-03
### Added
- Anti-Cheat Logging.

## [1.13] - 2018-02-05
### Added
- HourChecker Added
- SteamWorks Integration

## [1.14] - 2018-02-07
### Added
- ProfileChecker Added
- Steamid Added to logs
