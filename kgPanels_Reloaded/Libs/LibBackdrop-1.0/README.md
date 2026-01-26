# LibBackdrop-1.0

## DEPRECATED - DO NOT USE - PERSONAL FORK of https://www.curseforge.com/wow/addons/libbackdrop-1-0

LibBackdrop provides a 100% compatible replacement for SetBackDrop.

It also mixes in the following methods to the frame

Mixin methods

```lua
SetBackdropGradient(orient,minR,minG,minB,maxR,maxG,maxB)
```

setup a gradient on the bg texture.

```lua
SetBackdropGradientAlpha(orient,minR,minG,minB,minA,maxR,maxG,maxB,maxA)
```

setup a gradient with alpha on the bg texture

```lua
SetBackdropBorderGradient(orient,minR,minG,minB,maxR,maxG,maxB)
```

setup a gradient on the border texture

```lua
SetBackdropBorderGradientAlpha(orient,minR,minG,minB,minA,maxR,maxG,maxB,maxA)
```

setup a gradient with alpha on the border texture

```lua
GetBackdropBorderSection(section)
```

get a reference to a section of the border

[Valid values are: TOPLEFTCORNER,TOP,TOPRIGHTCORNER,LEFT,RIGHT,BOTLEFTCORNER,BOT,BOTRIGHTCORNER]

```lua
GetBackdropBackground
```

get a reference to the backdrop background texture itself

```lua
BorderTextureFunction(function name, params)
```

this method allows you to call a function on each border texture, passing whatever params you want. This is a convience method, instead of having to fetch each subtexture to call some method. Example usage frame:BorderTextureFunction("SetDrawLayer","ARTWORK") to raise the border draw layer

Library High Level Function

```lua
IsEnhanced(frame)
```

test if a frame has already been enhanced

```lua
EnhanceBackdrop (frame)
```

embed the mixins into a given frame

To Use:

```lua
local BD = LibStub("LibBackdrop-1.0") -- Create a frame as normal local testFrame = CreateFrame("Frame","Test Frame",UIParent) -- Embed the new backdrop functions BD:EnhanceBackdrop(testFrame) -- Use as you would normally testFrame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }}) --Now for some coloring fun -- Set the border to gradient upward from red to green testFrame:SetBackdropBorderGradient("vertical",1,0,0,0.5,1,0) -- Set the background image to color from blue to green testFrame:SetBackdropGradient("VERTICAL",0,0,1,0,1,0)
```

Here is the result of the above code http://dl.dropbox.com/u/10956/LibBackDrop-Example.png
