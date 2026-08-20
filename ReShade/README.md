# Jack Ye's ASCII Art Shader for ReShade

This package contains the consumer version of Jack Ye's real-time ASCII art
effect. ReShade itself is not included.

## Installation

1. Download and install ReShade from the
   [official ReShade website](https://reshade.me/) for the game's executable.
2. Extract this package directly into the folder containing that executable
   and the ReShade installation. Allow the included `reshade-shaders` folder
   to merge with the existing folder.
3. Start the game and open the ReShade overlay with its configured overlay key
   (the default is `Home`).
4. Enable the `JackYeAscii` technique.

The package does not overwrite standard ReShade effects. Its files use the
`JackYeAscii` prefix to avoid collisions with other effect packages.

## Optional depth-aware contours

The effect works without depth information. To add depth-aware foreground
contours, enable **Depth Edges** in the effect and select a usable depth buffer
under ReShade's **Add-ons > Generic Depth** tab.

The shader's **Linearized Depth** diagnostic should show nearby objects as dark
and distant objects as light. If the depth is incorrect, open
**Edit Global Preprocessor Definitions** in ReShade and try the following:

- If near and far values are reversed, toggle
  `RESHADE_DEPTH_INPUT_IS_REVERSED` between `0` and `1`.
- If the image is upside down, toggle
  `RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN` between `0` and `1`.
- If the diagnostic remains completely black or white, return to
  **Generic Depth** and try another available depth buffer.

Apply the changes and reload the effects. If the game does not expose a usable
depth buffer, leave **Depth Edges** disabled; all image-based features will
continue to work. Depth access may also be disabled in multiplayer.

## Package contents

- `reshade-shaders/Shaders/JackYeAscii.fx`
- `reshade-shaders/Textures/JackYeAscii_GlyphAtlasStandard.png`
- `reshade-shaders/Textures/JackYeAscii_GlyphAtlasExtended.png`
- `reshade-shaders/Textures/JackYeAscii_EdgeAtlas.png`

The source project, development diary, and issue tracker are available in the
[GitHub repository](https://github.com/Luniversity/Ascii-Art-Shader).

## License and credits

Original project code is available under the included MIT License, copyright
© 2026 Jack Ye.

The glyph atlases use or derive from textures in
[Garrett Gunnell's AcerolaFX](https://github.com/GarrettGunnell/AcerolaFX),
distributed under the included AcerolaFX MIT License. The Oklab conversion
matrices are from
[Björn Ottosson's Oklab reference](https://bottosson.github.io/posts/oklab/),
made available as public-domain and MIT-licensed material.
