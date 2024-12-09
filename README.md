# REAPER Scripts

This repository contains a collection of Lua scripts for REAPER, a digital audio workstation (DAW). These scripts provide various functionalities to enhance your workflow in REAPER.

## Requirements

Some scripts may require the SWS extension or ReaPack. Please ensure you have these installed for full functionality.

## Scripts

### 1. gradualBPMAdjustment.lua

This script allows you to gradually adjust the BPM (Beats Per Minute) of your project using keyboard shortcuts.

#### Usage

- Press `z` to decrease the BPM by 5.
- Press `x` to increase the BPM by 5.

The BPM change will be smooth and gradual.

#### Example

1. Load the script in REAPER.
2. Press `z` or `x` to adjust the BPM.

#### Requirements

- Requires SWS extension.

### 2. goToRegionAndPlay.lua

This script moves the play cursor to a specified region and starts playback.

#### Usage

- Set the desired region index in the script (default is 1).
- Run the script to move the play cursor to the start of the specified region and begin playback.

#### Example

1. Set `desiredRegionIndex` to the region you want to play.
2. Run the script.

### 3. getPlayPositionAndSelectRegion.lua

This script selects the region at the current play position.

#### Usage

- Run the script to select the region where the play cursor is currently located.

#### Example

1. Move the play cursor to a position within a region.
2. Run the script to select that region.

### 4. getActualCursorPositionAndSelectRegion.lua

This script selects the region at the current play position and sets it as the loop range.

#### Usage

- Run the script to select the region at the current play position and set it as the loop range.

#### Example

1. Move the play cursor to a position within a region.
2. Run the script to select that region and set it as the loop range.

#### Requirements

- Requires SWS extension.

## Installation

1. Download the scripts from this repository.
2. Place the scripts in your REAPER scripts directory.
3. Load the scripts in REAPER using the Actions List.
4. For your convenience, after loading the scripts, you can define keyboard shortcuts for each loaded script.

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
