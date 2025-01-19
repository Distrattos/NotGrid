# NotGrid
NotGrid is a party and raid frame addon for Vanilla World of Warcraft (1.12.1). While heavily based off of the original addon Grid, it both lacks some Grid features as well as adds new ones. It supports Clique keybinds & macros, Lazyspell, healcomm, eight buff/debuff icons around the unit frame, low mana & aggro warning, proximity checking, pets, and a simple config menu for general resizing/coloring options.

Latest updates:
- Added support for Raid Target Icons to be visible on unit frame, with configurable size & position
- Microbot WoW: Added border & text highlighting to differentiate between players and companions (both yours/controllable and others)

![Screenshot](media/screenshot.jpg)

## Usage
Use */notgrid* or */ng* to show the config menu.  
Use */notgrid grid* to generate a style similar to the original grid.  
Use */notgrid reset* to restore the default settings.
Use */notgrid scan* to manually query server for companion status (Microbot WoW).
Use / for separating multiple Buffs/Debuffs to track on one icon.  
Use */ngcast spellname(Rank X)* in macros for mouseover casting.

## Optional Dependencies
Clique: Enables click-casting on your unit frames.  
LazySpell: Enables Clique and /ngcast auto spell rank scaling depending on unit health deficit.

## Custom server utility
Microbot WoW enables the player to summon AI companions to play with.
This version has been modified to request info from server about status of companions, which lets you highlight them in the unit frame.  
It allows for either a secondary colored border or overriding the name color, with separate configurable colors for
- Players (aka non-companions)
- Your companions (Those companions you can control, either from being the Master for said bot or being assigned it as a partner through .z follow)
- Other companions (Those which belong to other players)

## Additional Note
If you're having issues with the frame borders/edges being un-uniformly sized or appearing clipped by the healthbar make sure to have a proper [UI scale](http://wow.gamepedia.com/UI_Scale) set.  
TLDR: If you play with a 1920x1080 resolution, the correct UI scale would be 768/1080 = 0.7111..., and you would set that by typing */console UIScale 0.7111111111* in the chat.
