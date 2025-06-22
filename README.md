# Clipsal C-BUS Serial

See [Change Log](/CHANGELOG.md)

This is a Q-SYS Plugin for Clipsal C-BUS Serial connections. It communicates using the C-BUS protocol.

> Bug reports and feature requests should be sent to Jason Foord (jf@tag.com.au).

## How do I get set up?

See [Q-SYS Online Help File - Plugins](https://q-syshelp.qsc.com/#Schematic_Library/plugins.htm)

## Properties

#### Protocol

Communication method used by the plugin.

> C-BUS

> The protocol of the Envision Gateway is set under the *Port Editor* tab in *Clipsal Toolkit*

#### Enable Polling

Whether the plugin will poll current presets and levels.

#### Poll Rate (s)

The polling interval.

#### Connection Type

The connection method.

> TCP | Serial

#### Area Slots

Each area slot will generate a new page.

> Each page configures a single area, or can be left on area '0' (none).

#### Presets

The number of preset slots available in each area slot.

#### Preset Recall Mode

Use opcodes `01` - `04` and `0A` - `0D` for preset recall (`Non-Linear`), or opcode `65` (`Linear`).

> Linear | Non-Linear

#### Enable Logical Channels

Whether to show logical channel controls.

#### Logical Channels

The number of logical channel controls to show in each area slot.

> The value range is ***255 - 0***

## Controls

### Area Slot
![Area Slot](./screenshots/interface.jpg)

#### IP Address

The IP Address of the device.

> This is a global control that displays on every page.

#### Port

The TCP port to use.

> This is a global control that displays on every page.

> Default port is 50000

#### Device Status

Displays the device's status.

> This is a global control that displays on every page.

#### Connect

Toggles the connection to the device.

> This is a global control that displays on every page.

##### Area Number

The Area to control. Leave at '0' if unallocated.

0 | 255

> Area information is configured in the *Clipsal Toolkit* software.

##### Area Status

The plugin-determined status of the area.

> :warning: ***Avoid having the same area number in multiple slots; it won't break everything, but the feedback hasn't been fully optimised for this use case as it shouldn't exist.***

> Area Unallocated | Area is Duplicate | OK

##### Preset Fade Time

The fade time to recall the preset with when loaded.

##### Preset Load

Recalls the preset.

##### Preset Match

Indicates if the preset is currently active.

> Adjusting a logical channel level manually will clear all preset match indicators.

##### Area Logical Channel Level

Control of the logical channel level.

> Can either be used in real-time, or snapshotted in Q-SYS to achieve 'preset' functionality.
