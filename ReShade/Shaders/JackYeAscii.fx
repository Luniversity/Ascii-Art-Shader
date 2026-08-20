#include "ReShade.fxh"

#define ASCII_CELL_SIZE 8
#define ASCII_CLASSIC_GLYPH_COUNT 10.0
#define ASCII_EXTENDED_GLYPH_COUNT 16.0

#define ASCII_GLYPH_WIDTH 8
#define ASCII_GLYPH_HEIGHT 8

#define ASCII_CLASSIC_GLYPH_ATLAS_WIDTH \
    (ASCII_GLYPH_WIDTH * 10)

#define ASCII_EXTENDED_GLYPH_ATLAS_WIDTH \
    (ASCII_GLYPH_WIDTH * 16)

#define ASCII_GLYPH_ATLAS_HEIGHT \
    ASCII_GLYPH_HEIGHT

#define ASCII_EDGE_GLYPH_COUNT 5.0

#define ASCII_EDGE_GLYPH_ATLAS_WIDTH \
    (ASCII_GLYPH_WIDTH * 5)

#define ASCII_EDGE_GLYPH_ATLAS_HEIGHT \
    ASCII_GLYPH_HEIGHT

#define ASCII_GAUSSIAN_SIGMA 2.0
#define ASCII_GAUSSIAN_RADIUS 2
#define ASCII_GAUSSIAN_SCALE 1.6
#define ASCII_DOG_TAU 0.96
#define ASCII_DOG_THRESHOLD 0.005

#define ASCII_VIEW_OUTPUT 0
#define ASCII_VIEW_CELL_COLOR 1
#define ASCII_VIEW_CELL_LUMINANCE 2
#define ASCII_VIEW_GLYPH_INDEX 3
#define ASCII_VIEW_GLYPH_ATLAS 4
#define ASCII_VIEW_FULL_RESOLUTION_LUMINANCE 5
#define ASCII_VIEW_TAU_DOG_RESPONSE 6
#define ASCII_VIEW_BINARY_DOG 7
#define ASCII_VIEW_IMAGE_EVIDENCE_MASK 8
#define ASCII_VIEW_IMAGE_EVIDENCE_DIRECTION 9
#define ASCII_VIEW_IMAGE_CELL_PIXEL_COUNT 10
#define ASCII_VIEW_IMAGE_CELL_SUPPORT 11
#define ASCII_VIEW_IMAGE_CELL_DOMINANCE 12
#define ASCII_VIEW_IMAGE_CELL_DIRECTION 13
#define ASCII_VIEW_IMAGE_CELL_CANDIDATE 14
#define ASCII_VIEW_IMAGE_EDGE_ONLY 15
#define ASCII_VIEW_IMAGE_STABILIZED_CANDIDATE 16
#define ASCII_VIEW_IMAGE_STABILIZED_DIRECTION 17
#define ASCII_VIEW_IMAGE_TEMPORAL_INTERVENTION 18
#define ASCII_VIEW_IMAGE_STABILIZED_EDGE_ONLY 19
#define ASCII_VIEW_LINEARIZED_DEPTH 20
#define ASCII_VIEW_DEPTH_SOBEL_MAGNITUDE 21
#define ASCII_VIEW_DEPTH_SOBEL_DIRECTION 22
#define ASCII_VIEW_DEPTH_PROXIMITY_WEIGHT 23
#define ASCII_VIEW_DEPTH_WEIGHTED_MAGNITUDE 24
#define ASCII_VIEW_DEPTH_EVIDENCE_MASK 25
#define ASCII_VIEW_DEPTH_CELL_PIXEL_COUNT 26
#define ASCII_VIEW_DEPTH_CELL_SUPPORT 27
#define ASCII_VIEW_DEPTH_CELL_DOMINANCE 28
#define ASCII_VIEW_DEPTH_CELL_DIRECTION 29
#define ASCII_VIEW_DEPTH_CELL_CANDIDATE 30
#define ASCII_VIEW_DEPTH_EDGE_ONLY 31
#define ASCII_VIEW_DEPTH_STABILIZED_CANDIDATE 32
#define ASCII_VIEW_DEPTH_STABILIZED_DIRECTION 33
#define ASCII_VIEW_DEPTH_TEMPORAL_INTERVENTION 34
#define ASCII_VIEW_DEPTH_STABILIZED_EDGE_ONLY 35
#define ASCII_VIEW_COMBINED_EDGE_SOURCE 36
#define ASCII_VIEW_COMBINED_EDGE_ONLY 37
#define ASCII_VIEW_PALETTE_SLOT 38
#define ASCII_VIEW_GENERATED_PALETTE_STRIP 39

#define ASCII_CELL_TEXTURE_WIDTH \
    ((BUFFER_WIDTH + ASCII_CELL_SIZE - 1) / ASCII_CELL_SIZE)

#define ASCII_CELL_TEXTURE_HEIGHT \
    ((BUFFER_HEIGHT + ASCII_CELL_SIZE - 1) / ASCII_CELL_SIZE)


texture AsciiCellColorTexture
{
    Width = ASCII_CELL_TEXTURE_WIDTH;
    Height = ASCII_CELL_TEXTURE_HEIGHT;
    Format = RGBA16F;
};

texture AsciiFullResolutionLuminanceTexture
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = R16F;
};

texture AsciiGaussianHorizontalTexture
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RG16F;
};

texture AsciiGaussianVerticalTexture
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RG16F;
};

texture AsciiDepthEdgeEvidenceTexture
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

texture AsciiCellEdgeHistogramTexture
{
    Width = ASCII_CELL_TEXTURE_WIDTH;
    Height = ASCII_CELL_TEXTURE_HEIGHT;
    Format = RGBA16F;
};

texture AsciiCellDepthEdgeHistogramTexture
{
    Width = ASCII_CELL_TEXTURE_WIDTH;
    Height = ASCII_CELL_TEXTURE_HEIGHT;
    Format = RGBA16F;
};

texture AsciiCellEdgeStateTexture
{
    Width = ASCII_CELL_TEXTURE_WIDTH;
    Height = ASCII_CELL_TEXTURE_HEIGHT;
    Format = RGBA8;
};

texture AsciiPreviousCellEdgeStateTexture
{
    Width = ASCII_CELL_TEXTURE_WIDTH;
    Height = ASCII_CELL_TEXTURE_HEIGHT;
    Format = RGBA8;
};

texture AsciiDepthCellEdgeStateTexture
{
    Width = ASCII_CELL_TEXTURE_WIDTH;
    Height = ASCII_CELL_TEXTURE_HEIGHT;
    Format = RGBA8;
};

texture AsciiPreviousDepthCellEdgeStateTexture
{
    Width = ASCII_CELL_TEXTURE_WIDTH;
    Height = ASCII_CELL_TEXTURE_HEIGHT;
    Format = RGBA8;
};

texture AsciiGeneratedPaletteTexture
{
    Width = 6;
    Height = 1;
    Format = RGBA16F;
};

texture AsciiRandomPaletteStateTexture
{
    Width = 2;
    Height = 1;
    Format = RGBA16F;
};

texture AsciiPreviousRandomPaletteStateTexture
{
    Width = 2;
    Height = 1;
    Format = RGBA16F;
};

texture GlyphAtlasTexture <
    source = "JackYeAscii_GlyphAtlasStandard.png";
>
{
    Width = ASCII_CLASSIC_GLYPH_ATLAS_WIDTH;
    Height = ASCII_GLYPH_ATLAS_HEIGHT;
    Format = R8;
};

texture GlyphAtlas16Texture <
    source = "JackYeAscii_GlyphAtlasExtended.png";
>
{
    Width = ASCII_EXTENDED_GLYPH_ATLAS_WIDTH;
    Height = ASCII_GLYPH_ATLAS_HEIGHT;
    Format = R8;
};

texture EdgeGlyphAtlasTexture <
    source = "JackYeAscii_EdgeAtlas.png";
>
{
    Width = ASCII_EDGE_GLYPH_ATLAS_WIDTH;
    Height = ASCII_EDGE_GLYPH_ATLAS_HEIGHT;
    Format = R8;
};

sampler GlyphAtlas
{
    Texture = GlyphAtlasTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler GlyphAtlas16
{
    Texture = GlyphAtlas16Texture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiGeneratedPalette
{
    Texture = AsciiGeneratedPaletteTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiRandomPaletteState
{
    Texture = AsciiRandomPaletteStateTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiPreviousRandomPaletteState
{
    Texture = AsciiPreviousRandomPaletteStateTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

uniform int AsciiPaletteFrameCount <
    source = "framecount";
>;

uniform int GlyphSet <
    ui_label = "Glyph Set";
    ui_tooltip =
        "Choose the classic ten-step ramp or the extended sixteen-step "
        "ramp.";
    ui_type = "combo";
    ui_items =
        "Classic (10 Glyphs)\0"
        "Extended (16 Glyphs)\0";
> = 0;

uniform int ColorMode <
    ui_label = "Color Mode";
    ui_tooltip =
        "Choose monochrome, a designed palette, or source-colored glyphs.";
    ui_type = "combo";
    ui_items =
        "Monochrome\0"
        "Palette\0"
        "Cell Tint\0";
> = 1;

uniform int PaletteType <
    ui_label = "Palette Type";
    ui_tooltip =
        "Generate a harmonious palette or select every colour manually.";
    ui_type = "combo";
    ui_items =
        "Generated Palette\0"
        "Manual Palette (2 Colors)\0"
        "Manual Palette (6 Colors)\0";
> = 0;

uniform bool EnableEdgeGlyphs <
    ui_label = "Enable Edge Glyphs";
    ui_tooltip =
        "Replace suitable luminance glyphs with directional contour glyphs.";
    ui_type = "checkbox";
> = true;

uniform int GeneratedPaletteHarmony <
    ui_category = "Generated Palette";
    ui_label = "Harmony";
    ui_tooltip =
        "Tonal keeps one hue across the ramp. Analogous spreads the five "
        "foreground roles around the seed hue. Complementary uses the "
        "seed hue for the background and two darkest foreground roles, "
        "then uses the opposing hue for the three brightest roles. Triadic "
        "divides all six roles evenly between three hues.";
    ui_type = "combo";
    ui_items =
        "Tonal\0"
        "Analogous\0"
        "Complementary\0"
        "Triadic\0";
> = 0;

uniform float GeneratedPaletteHue <
    ui_category = "Generated Palette";
    ui_label = "Palette Hue";
    ui_tooltip =
        "Base hue shared by Tonal palettes and centered within Analogous "
        "palettes.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 360.0;
    ui_step = 1.0;
    ui_units = "degrees";
> = 68.4;

uniform float GeneratedPaletteBrightness <
    ui_category = "Generated Palette";
    ui_label = "Palette Brightness";
    ui_tooltip =
        "Perceptual brightness of the middle foreground colour. Changing "
        "the hue does not alter this value.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.7833;

uniform float GeneratedPaletteColorIntensity <
    ui_category = "Generated Palette";
    ui_label = "Palette Color Intensity";
    ui_tooltip =
        "Perceptual strength of the generated colours. Values outside the "
        "displayable range are safely reduced by gamut mapping.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.235;

uniform bool RandomizeGeneratedPalette <
    ui_category = "Generated Palette";
    ui_label = "Randomize Palette";
    ui_tooltip =
        "Generate and remember a plausible palette within the tested "
        "ranges. This temporarily overrides the palette sliders while "
        "preserving the selected harmony.";
    ui_type = "button";
    nosave = true;
> = false;

uniform bool ReturnToManualPalette <
    ui_category = "Generated Palette";
    ui_label = "Use Slider Values";
    ui_tooltip =
        "Stop using the remembered random palette and return generation "
        "to the visible sliders.";
    ui_type = "button";
    nosave = true;
> = false;

uniform float GeneratedPaletteHueSpan <
    ui_category = "Generated Palette - Fine Tuning";
    ui_category_closed = true;
    ui_label = "Analogous Hue Span";
    ui_tooltip =
        "Total hue angle covered by the five foreground roles. The darkest "
        "and lightest roles sit at opposite ends of this span.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 180.0;
    ui_step = 1.0;
    ui_units = "degrees";
> = 60.0;

uniform float GeneratedPaletteLightnessRange <
    ui_category = "Generated Palette - Fine Tuning";
    ui_category_closed = true;
    ui_label = "Foreground Lightness Range";
    ui_tooltip =
        "Total Oklab lightness range covered by the five foreground roles.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.8;
    ui_step = 0.01;
> = 0.3;

uniform float GeneratedPaletteColorfulnessRange <
    ui_category = "Generated Palette - Fine Tuning";
    ui_category_closed = true;
    ui_label = "Color Intensity Range";
    ui_tooltip =
        "Controls how much chroma grows from the darkest to the lightest "
        "foreground role.";
    ui_type = "slider";
    ui_min = -1.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.0;

uniform float GeneratedPaletteBackgroundSeparation <
    ui_category = "Generated Palette - Fine Tuning";
    ui_category_closed = true;
    ui_label = "Background Separation";
    ui_tooltip =
        "Oklab lightness distance between the seed and generated "
        "background role.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.55;

uniform float3 PaletteBackgroundColor <
    ui_category = "Manual Palette - 2 Colors";
    ui_category_closed = true;
    ui_label = "Background";
    ui_tooltip =
        "Background color used by the two-color manual palette.";
    ui_type = "color";
> = float3(
    0.09383891,
    0.078431375,
    0.078431375
);

uniform float3 PaletteGlyphColor <
    ui_category = "Manual Palette - 2 Colors";
    ui_category_closed = true;
    ui_label = "Foreground";
    ui_tooltip =
        "Foreground color used by the two-color manual palette.";
    ui_type = "color";
> = float3(
    0.8392157,
    0.76862746,
    0.64705884
);

uniform float3 PaletteRampBackgroundColor <
    ui_category = "Manual Palette - 6 Colors";
    ui_category_closed = true;
    ui_label = "Background";
    ui_type = "color";
> = float3(0.055, 0.045, 0.05);

uniform float3 PaletteRampColor0 <
    ui_category = "Manual Palette - 6 Colors";
    ui_category_closed = true;
    ui_label = "Foreground 1 (Darkest)";
    ui_type = "color";
> = float3(0.24, 0.17, 0.16);

uniform float3 PaletteRampColor1 <
    ui_category = "Manual Palette - 6 Colors";
    ui_category_closed = true;
    ui_label = "Foreground 2";
    ui_type = "color";
> = float3(0.37, 0.27, 0.22);

uniform float3 PaletteRampColor2 <
    ui_category = "Manual Palette - 6 Colors";
    ui_category_closed = true;
    ui_label = "Foreground 3";
    ui_type = "color";
> = float3(0.52, 0.40, 0.31);

uniform float3 PaletteRampColor3 <
    ui_category = "Manual Palette - 6 Colors";
    ui_category_closed = true;
    ui_label = "Foreground 4";
    ui_type = "color";
> = float3(0.68, 0.56, 0.43);

uniform float3 PaletteRampColor4 <
    ui_category = "Manual Palette - 6 Colors";
    ui_category_closed = true;
    ui_label = "Foreground 5 (Brightest)";
    ui_type = "color";
> = float3(0.8392157, 0.76862746, 0.64705884);

uniform float CellTintValueInfluence <
    ui_category = "Cell Tint";
    ui_category_closed = true;
    ui_label = "Value Influence";
    ui_tooltip =
        "Controls how much source Value affects tinted glyph brightness. "
        "Zero reproduces the original full-Value tint; one uses the cell's "
        "complete source Value.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.65;

uniform bool EnableDepthEdges <
    ui_category = "Edge Rendering";
    ui_category_closed = true;
    ui_label = "Enable Depth Edges";
    ui_tooltip =
        "Prefer geometry-derived contour glyphs when ReShade exposes a "
        "usable depth buffer.";
    ui_type = "checkbox";
> = true;

uniform bool EnableTemporalEdgeStability <
    ui_category = "Edge Rendering";
    ui_category_closed = true;
    ui_label = "Enable Temporal Edge Stability";
    ui_tooltip =
        "Reduce edge flicker by retaining well-supported cell edges and "
        "resisting uncertain direction changes.";
    ui_type = "checkbox";
> = true;

uniform int InputColorSpace <
    ui_category = "Compatibility";
    ui_category_closed = true;
    ui_label = "Input Color Space";
    ui_tooltip =
        "Most SDR games use an sRGB backbuffer. Choose Linear only if "
        "glyph selection appears consistently too dark after comparison.";
    ui_type = "combo";
    ui_items =
        "sRGB (Typical Backbuffer)\0"
        "Linear\0";
> = 0;

uniform int DiagnosticView <
    ui_category = "Diagnostics";
    ui_category_closed = true;
    ui_label = "Debug View";
    ui_tooltip =
        "Inspect intermediate stages of the ASCII rendering pipeline.";
    ui_type = "combo";
    ui_items =
        "ASCII Output\0"
        "Cell Color\0"
        "Luminance\0"
        "Glyph Index\0"
        "Glyph Atlas\0"
        "Full-Resolution Luminance\0"
        "Tau-Adjusted DoG Response\0"
        "Binary DoG\0"
        "Edge Evidence Mask\0"
        "Edge Sobel Direction\0"
        "Cell Edge Pixel Count\0"
        "Cell Edge Support Margin\0"
        "Cell Edge Dominance Margin\0"
        "Cell Edge Dominant Direction\0"
        "Cell Edge Candidate Mask\0"
        "Edge Only ASCII\0"
        "Stabilized Candidate Mask\0"
        "Stabilized Dominant Direction\0"
        "Temporal Intervention Mask\0"
        "Stabilized Edge Only ASCII\0"
        "Linearized Depth\0"
        "Depth Sobel Magnitude\0"
        "Depth Sobel Direction\0"
        "Depth Proximity Weight\0"
        "Weighted Depth Magnitude\0"
        "Binary Depth Edge Mask\0"
        "Depth Cell Edge Pixel Count\0"
        "Depth Cell Edge Support Margin\0"
        "Depth Cell Edge Dominance Margin\0"
        "Depth Cell Edge Dominant Direction\0"
        "Depth Cell Edge Candidate Mask\0"
        "Depth Edge Only ASCII\0"
        "Stabilized Depth Candidate Mask\0"
        "Stabilized Depth Dominant Direction\0"
        "Depth Temporal Intervention Mask\0"
        "Stabilized Depth Edge Only ASCII\0"
        "Combined Edge Source\0"
        "Combined Edge Only ASCII\0"
        "Palette Slot\0"
        "Generated Palette Strip\0";
> = ASCII_VIEW_OUTPUT;

uniform float SobelMagnitudeDisplayScale <
    ui_category = "Diagnostics";
    ui_label = "Sobel View Brightness";
    ui_tooltip =
        "Changes diagnostic visibility only; edge detection is unaffected.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 10.0;
    ui_step = 0.1;
> = 1.0;

uniform float DoGDisplayScale <
    ui_category = "Diagnostics";
    ui_label = "DoG View Brightness";
    ui_tooltip =
        "Changes diagnostic visibility only; edge detection is unaffected.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 100.0;
    ui_step = 1.0;
> = 20.0;

uniform float DepthDisplayScale <
    ui_category = "Diagnostics";
    ui_label = "Depth View Brightness";
    ui_tooltip =
        "Brightens the Linearized Depth diagnostic only so compressed "
        "near-range values are easier to inspect.";
    ui_type = "slider";
    ui_min = 1.0;
    ui_max = 10.0;
    ui_step = 0.1;
> = 1.0;

uniform float DepthSobelDisplayScale <
    ui_category = "Diagnostics";
    ui_label = "Depth Sobel View Brightness";
    ui_tooltip =
        "Changes depth-gradient diagnostic visibility only; no edge "
        "threshold is applied yet.";
    ui_type = "slider";
    ui_min = 1.0;
    ui_max = 1000.0;
    ui_step = 1.0;
> = 100.0;

uniform float DepthEdgeMaximumDistance <
    ui_category = "Depth Edges - Advanced";
    ui_category_closed = true;
    ui_label = "Maximum Edge Distance";
    ui_tooltip =
        "Normalized linear depth where depth-derived edges finish fading "
        "out. The meaning depends on ReShade's configured far plane.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.6;

uniform float DepthEdgeFadeWidth <
    ui_category = "Depth Edges - Advanced";
    ui_category_closed = true;
    ui_label = "Distance Fade Width";
    ui_tooltip =
        "Normalized depth range over which distant depth-edge evidence "
        "fades before Maximum Edge Distance.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.5;
    ui_step = 0.001;
> = 0.3;

uniform float DepthEdgeMinimumMagnitude <
    ui_category = "Depth Edges - Advanced";
    ui_category_closed = true;
    ui_label = "Minimum Weighted Magnitude";
    ui_tooltip =
        "Weighted Sobel magnitude required for a pixel to become depth-edge "
        "evidence.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.15;

uniform float DepthCellEdgeMinimumDominantPixels <
    ui_category = "Depth Edges - Advanced";
    ui_category_closed = true;
    ui_label = "Depth Minimum Dominant Pixels";
    ui_tooltip =
        "Depth-edge votes required in a cell's winning direction before "
        "the cell becomes a candidate.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 64.0;
    ui_step = 1.0;
> = 10.0;

uniform float DepthCellEdgeMinimumDominance <
    ui_category = "Depth Edges - Advanced";
    ui_category_closed = true;
    ui_label = "Depth Minimum Dominance";
    ui_tooltip =
        "Required fraction of accepted depth-edge pixels that must support "
        "the winning direction.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.5;

uniform float DepthTemporalEdgeRetentionSupport <
    ui_category = "Depth Temporal Stability - Advanced";
    ui_category_closed = true;
    ui_label = "Depth Temporal Retention Support";
    ui_tooltip =
        "Current depth-edge votes required to retain a previously displayed "
        "depth edge.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 64.0;
    ui_step = 1.0;
> = 2.0;

uniform float DepthTemporalEdgeRetentionDominance <
    ui_category = "Depth Temporal Stability - Advanced";
    ui_category_closed = true;
    ui_label = "Depth Temporal Retention Dominance";
    ui_tooltip =
        "Current directional dominance required to retain a previous depth "
        "edge.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.1;

uniform float DepthTemporalEdgeDirectionSwitchMargin <
    ui_category = "Depth Temporal Stability - Advanced";
    ui_category_closed = true;
    ui_label = "Depth Temporal Direction Switch Margin";
    ui_tooltip =
        "Extra votes a new depth direction needs over the retained direction "
        "before its glyph can replace it.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 64.0;
    ui_step = 1.0;
> = 3.0;

uniform bool DepthBufferAvailable <
    source = "bufready_depth";
>;

uniform float CellEdgeMinimumDominantPixels <
    ui_category = "Edge Classification - Advanced";
    ui_category_closed = true;
    ui_label = "Minimum Dominant Pixels";
    ui_tooltip =
        "Votes required in a cell's winning direction before a new edge "
        "candidate can appear.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 64.0;
    ui_step = 1.0;
> = 8.0;

uniform float CellEdgeMinimumDominance <
    ui_category = "Edge Classification - Advanced";
    ui_category_closed = true;
    ui_label = "Minimum Dominance";
    ui_tooltip =
        "Required fraction of accepted contour pixels that must support "
        "the winning direction.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.65;

uniform float TemporalEdgeRetentionSupport <
    ui_category = "Temporal Stability - Advanced";
    ui_category_closed = true;
    ui_label = "Temporal Retention Support";
    ui_tooltip =
        "Current votes required to retain a previously displayed edge.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 64.0;
    ui_step = 1.0;
> = 6.0;

uniform float TemporalEdgeRetentionDominance <
    ui_category = "Temporal Stability - Advanced";
    ui_category_closed = true;
    ui_label = "Temporal Retention Dominance";
    ui_tooltip =
        "Current directional dominance required to retain a previous edge.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.3;

uniform float TemporalEdgeDirectionSwitchMargin <
    ui_category = "Temporal Stability - Advanced";
    ui_category_closed = true;
    ui_label = "Temporal Direction Switch Margin";
    ui_tooltip =
        "Extra votes a new direction needs over the retained direction "
        "before its glyph can replace it.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 64.0;
    ui_step = 1.0;
> = 3.0;

sampler AsciiCellColor
{
    Texture = AsciiCellColorTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiFullResolutionLuminance
{
    Texture = AsciiFullResolutionLuminanceTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler EdgeGlyphAtlas
{
    Texture = EdgeGlyphAtlasTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiGaussianHorizontal
{
    Texture = AsciiGaussianHorizontalTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiGaussianVertical
{
    Texture = AsciiGaussianVerticalTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiEdgeEvidence
{
    // The horizontal Gaussian result is no longer needed after the vertical
    // pass, so this texture is reused for the final image-edge gradient.
    Texture = AsciiGaussianHorizontalTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiDepthEdgeEvidence
{
    Texture = AsciiDepthEdgeEvidenceTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiCellEdgeHistogram
{
    Texture = AsciiCellEdgeHistogramTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiCellDepthEdgeHistogram
{
    Texture = AsciiCellDepthEdgeHistogramTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiCellEdgeState
{
    Texture = AsciiCellEdgeStateTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiPreviousCellEdgeState
{
    Texture = AsciiPreviousCellEdgeStateTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiDepthCellEdgeState
{
    Texture = AsciiDepthCellEdgeStateTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler AsciiPreviousDepthCellEdgeState
{
    Texture = AsciiPreviousDepthCellEdgeStateTexture;

    AddressU = CLAMP;
    AddressV = CLAMP;

    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

bool IsCombinedEdgeDiagnostic()
{
    return
        DiagnosticView == ASCII_VIEW_COMBINED_EDGE_SOURCE
        || DiagnosticView == ASCII_VIEW_COMBINED_EDGE_ONLY;
}

bool IsImageEdgeDiagnostic()
{
    return
        (
            DiagnosticView >= ASCII_VIEW_TAU_DOG_RESPONSE
            && DiagnosticView
                <= ASCII_VIEW_IMAGE_STABILIZED_EDGE_ONLY
        )
        || IsCombinedEdgeDiagnostic();
}

bool IsDepthEdgeDiagnostic()
{
    return
        (
            DiagnosticView >= ASCII_VIEW_DEPTH_SOBEL_MAGNITUDE
            && DiagnosticView
                <= ASCII_VIEW_DEPTH_STABILIZED_EDGE_ONLY
        )
        || (
            IsCombinedEdgeDiagnostic()
            && EnableDepthEdges
        );
}

bool NeedsImageEdgePipeline()
{
    return EnableEdgeGlyphs || IsImageEdgeDiagnostic();
}

bool NeedsDepthEdgePipeline()
{
    return
        (EnableEdgeGlyphs && EnableDepthEdges)
        || IsDepthEdgeDiagnostic();
}

bool NeedsImageTemporalPipeline()
{
    bool temporalDiagnostic =
        DiagnosticView
            >= ASCII_VIEW_IMAGE_STABILIZED_CANDIDATE
        && DiagnosticView
            <= ASCII_VIEW_IMAGE_STABILIZED_EDGE_ONLY;

    return
        NeedsImageEdgePipeline()
        && (
            EnableTemporalEdgeStability
            || temporalDiagnostic
        );
}

bool NeedsDepthTemporalPipeline()
{
    bool temporalDiagnostic =
        DiagnosticView
            >= ASCII_VIEW_DEPTH_STABILIZED_CANDIDATE
        && DiagnosticView
            <= ASCII_VIEW_DEPTH_STABILIZED_EDGE_ONLY;

    return
        NeedsDepthEdgePipeline()
        && (
            EnableTemporalEdgeStability
            || temporalDiagnostic
        );
}

float CalculateLuminance(float3 color)
{
    static const float3 luminanceWeights =
        float3(0.2126, 0.7152, 0.0722);

    return saturate(
        dot(color, luminanceWeights)
    );
}

float SRGBChannelToLinear(float value)
{
    value = saturate(value);

    if (value <= 0.04045)
    {
        return value / 12.92;
    }

    return pow(
        (value + 0.055) / 1.055,
        2.4
    );
}

float LinearChannelToSRGB(float value)
{
    value = saturate(value);

    if (value <= 0.0031308)
    {
        return value * 12.92;
    }

    return 1.055 * pow(value, 1.0 / 2.4) - 0.055;
}

float3 SRGBToLinear(float3 color)
{
    return float3(
        SRGBChannelToLinear(color.r),
        SRGBChannelToLinear(color.g),
        SRGBChannelToLinear(color.b)
    );
}

float3 LinearToSRGB(float3 color)
{
    return float3(
        LinearChannelToSRGB(color.r),
        LinearChannelToSRGB(color.g),
        LinearChannelToSRGB(color.b)
    );
}

// Oklab conversion matrices by Bjorn Ottosson.
// Public domain and also available under the MIT license:
// https://bottosson.github.io/posts/oklab/
float3 OKLabToLinearSRGB(float3 color)
{
    float lRoot =
        color.x
        + 0.3963377774 * color.y
        + 0.2158037573 * color.z;

    float mRoot =
        color.x
        - 0.1055613458 * color.y
        - 0.0638541728 * color.z;

    float sRoot =
        color.x
        - 0.0894841775 * color.y
        - 1.2914855480 * color.z;

    float l = lRoot * lRoot * lRoot;
    float m = mRoot * mRoot * mRoot;
    float s = sRoot * sRoot * sRoot;

    return float3(
        4.0767416621 * l
            - 3.3077115913 * m
            + 0.2309699292 * s,
        -1.2684380046 * l
            + 2.6097574011 * m
            - 0.3413193965 * s,
        -0.0041960863 * l
            - 0.7034186147 * m
            + 1.7076147010 * s
    );
}

bool IsLinearSRGBInGamut(float3 color)
{
    return all(color >= 0.0)
        && all(color <= 1.0);
}

float3 GamutMapOKLCH(
    float lightness,
    float2 hueDirection,
    float requestedChroma
)
{
    float safeChroma = max(requestedChroma, 0.0);

    float3 requestedLab = float3(
        saturate(lightness),
        hueDirection * safeChroma
    );

    float3 requestedRGB = OKLabToLinearSRGB(
        requestedLab
    );

    if (IsLinearSRGBInGamut(requestedRGB))
    {
        return saturate(requestedRGB);
    }

    float lowerChroma = 0.0;
    float upperChroma = safeChroma;

    for (int iteration = 0; iteration < 8; ++iteration)
    {
        float testedChroma =
            (lowerChroma + upperChroma) * 0.5;

        float3 testedLab = float3(
            saturate(lightness),
            hueDirection * testedChroma
        );

        float3 testedRGB = OKLabToLinearSRGB(
            testedLab
        );

        if (IsLinearSRGBInGamut(testedRGB))
        {
            lowerChroma = testedChroma;
        }
        else
        {
            upperChroma = testedChroma;
        }
    }

    float3 mappedLab = float3(
        saturate(lightness),
        hueDirection * lowerChroma
    );

    return saturate(
        OKLabToLinearSRGB(mappedLab)
    );
}

float2 RotateHueDirection(
    float2 hueDirection,
    float angleDegrees
)
{
    float angleRadians =
        angleDegrees * 0.01745329252;

    float sineValue;
    float cosineValue;
    sincos(
        angleRadians,
        sineValue,
        cosineValue
    );

    return float2(
        hueDirection.x * cosineValue
            - hueDirection.y * sineValue,
        hueDirection.x * sineValue
            + hueDirection.y * cosineValue
    );
}

float PaletteRandomValue(float seed, float channel)
{
    return frac(
        sin(seed * 12.9898 + channel * 78.233)
        * 43758.5453
    );
}

float4 BuildRandomPaletteStatePixel(
    int statePixel
)
{
    float seed =
        float(AsciiPaletteFrameCount) + 0.5;

    float hue =
        PaletteRandomValue(seed, 1.0) * 360.0;

    float lightnessRange = lerp(
        0.35,
        0.8,
        PaletteRandomValue(seed, 5.0)
    );

    float brightness = lerp(
        0.6,
        0.9,
        PaletteRandomValue(seed, 2.0)
    );

    // Keep no more than the brightest role slightly above Oklab L = 1.
    // This avoids collapsing several bright palette slots to the same value.
    brightness = min(
        brightness,
        1.05 - lightnessRange * 0.5
    );

    brightness = max(brightness, 0.6);

    float colorIntensity = lerp(
        0.1,
        0.8,
        PaletteRandomValue(seed, 3.0)
    );

    float analogousHueSpan = lerp(
        60.0,
        180.0,
        PaletteRandomValue(seed, 4.0)
    );

    float colorfulnessRange = lerp(
        -0.4,
        0.4,
        PaletteRandomValue(seed, 6.0)
    );

    float backgroundSeparation = lerp(
        0.52,
        0.63,
        PaletteRandomValue(seed, 7.0)
    );

    if (statePixel <= 0)
    {
        return float4(
            hue / 360.0,
            brightness,
            colorIntensity,
            analogousHueSpan / 180.0
        );
    }

    return float4(
        lightnessRange,
        (colorfulnessRange + 0.4) / 0.8,
        (backgroundSeparation - 0.52) / 0.11,
        0.731
    );
}

float4 UpdateRandomPaletteStatePS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    int statePixel = min(int(position.x), 1);

    if (RandomizeGeneratedPalette)
    {
        return BuildRandomPaletteStatePixel(
            statePixel
        );
    }

    if (ReturnToManualPalette)
    {
        return 0.0;
    }

    float2 stateUV = float2(
        (float(statePixel) + 0.5) / 2.0,
        0.5
    );

    return tex2Dlod(
        AsciiPreviousRandomPaletteState,
        float4(stateUV, 0.0, 0.0)
    );
}

float4 CopyRandomPaletteStatePS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    int statePixel = min(int(position.x), 1);

    float2 stateUV = float2(
        (float(statePixel) + 0.5) / 2.0,
        0.5
    );

    return tex2Dlod(
        AsciiRandomPaletteState,
        float4(stateUV, 0.0, 0.0)
    );
}

struct GeneratedPaletteParameters
{
    float hue;
    float brightness;
    float colorIntensity;
    float analogousHueSpan;
    float lightnessRange;
    float colorfulnessRange;
    float backgroundSeparation;
};

GeneratedPaletteParameters ResolveGeneratedPaletteParameters()
{
    GeneratedPaletteParameters parameters;

    parameters.hue = GeneratedPaletteHue;
    parameters.brightness = GeneratedPaletteBrightness;
    parameters.colorIntensity =
        GeneratedPaletteColorIntensity;
    parameters.analogousHueSpan =
        GeneratedPaletteHueSpan;
    parameters.lightnessRange =
        GeneratedPaletteLightnessRange;
    parameters.colorfulnessRange =
        GeneratedPaletteColorfulnessRange;
    parameters.backgroundSeparation =
        GeneratedPaletteBackgroundSeparation;

    float4 randomState0 = tex2Dlod(
        AsciiRandomPaletteState,
        float4(0.25, 0.5, 0.0, 0.0)
    );

    float4 randomState1 = tex2Dlod(
        AsciiRandomPaletteState,
        float4(0.75, 0.5, 0.0, 0.0)
    );

    bool randomStateIsActive =
        abs(randomState1.a - 0.731) < 0.001;

    if (randomStateIsActive)
    {
        parameters.hue = randomState0.r * 360.0;
        parameters.brightness = randomState0.g;
        parameters.colorIntensity = randomState0.b;
        parameters.analogousHueSpan =
            randomState0.a * 180.0;
        parameters.lightnessRange = randomState1.r;
        parameters.colorfulnessRange =
            randomState1.g * 0.8 - 0.4;
        parameters.backgroundSeparation =
            randomState1.b * 0.11 + 0.52;
    }

    return parameters;
}

float3 GeneratePaletteRole(int roleIndex)
{
    GeneratedPaletteParameters parameters =
        ResolveGeneratedPaletteParameters();

    float seedLightness =
        saturate(parameters.brightness);

    float2 hueDirection = RotateHueDirection(
        float2(1.0, 0.0),
        parameters.hue
    );

    // The user-facing 0-1 intensity maps onto a practical OKLCH chroma
    // range. Gamut mapping handles hue/lightness combinations that cannot
    // display the full requested intensity.
    float baseChroma =
        saturate(parameters.colorIntensity)
        * 0.4;

    float targetLightness;
    float targetChroma;
    float hueOffsetDegrees = 0.0;

    if (roleIndex <= 0)
    {
        targetLightness = max(
            seedLightness
                - max(
                    parameters.backgroundSeparation,
                    0.0
                ),
            0.01
        );

        targetChroma = baseChroma * 0.35;

        if (GeneratedPaletteHarmony == 3)
        {
            hueOffsetDegrees = -120.0;
        }
    }
    else
    {
        float foregroundPosition =
            float(roleIndex - 1) / 4.0;

        float centeredPosition =
            foregroundPosition - 0.5;

        targetLightness = saturate(
            seedLightness
            + centeredPosition
                * max(
                    parameters.lightnessRange,
                    0.0
                )
        );

        float colorfulnessMultiplier = max(
            1.0
            + centeredPosition
                * 2.0
                * parameters.colorfulnessRange,
            0.0
        );

        targetChroma =
            baseChroma * colorfulnessMultiplier;

        if (GeneratedPaletteHarmony == 1)
        {
            hueOffsetDegrees =
                centeredPosition
                * max(parameters.analogousHueSpan, 0.0);
        }
        else if (
            GeneratedPaletteHarmony == 2
            && roleIndex >= 3
        )
        {
            // Split the six palette roles evenly: the background and two
            // darkest foreground roles use the seed hue, while the three
            // brightest roles use its complement. Avoiding hue interpolation
            // or alternating bands keeps adjacent glyph steps stable.
            hueOffsetDegrees = 180.0;
        }
        else if (GeneratedPaletteHarmony == 3)
        {
            if (roleIndex <= 1)
            {
                hueOffsetDegrees = -120.0;
            }
            else if (roleIndex >= 4)
            {
                hueOffsetDegrees = 120.0;
            }
        }
    }

    float2 roleHueDirection = RotateHueDirection(
        hueDirection,
        hueOffsetDegrees
    );

    float3 generatedLinear = GamutMapOKLCH(
        targetLightness,
        roleHueDirection,
        targetChroma
    );

    return LinearToSRGB(generatedLinear);
}

float4 GeneratePalettePS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    int roleIndex = min(
        int(position.x),
        5
    );

    return float4(
        GeneratePaletteRole(roleIndex),
        1.0
    );
}

float3 DecodeInputColor(float3 color)
{
    float3 decodedColor = color;

    if (InputColorSpace == 0)
    {
        decodedColor = SRGBToLinear(color);
    }

    return decodedColor;
}

float3 EncodeAnalysisColor(float3 color)
{
    float3 encodedColor = color;

    if (InputColorSpace == 0)
    {
        encodedColor = LinearToSRGB(color);
    }

    return encodedColor;
}


float GetActiveGlyphCount()
{
    return GlyphSet == 1
        ? ASCII_EXTENDED_GLYPH_COUNT
        : ASCII_CLASSIC_GLYPH_COUNT;
}

float SampleActiveGlyphAtlas(float2 atlasUV)
{
    if (GlyphSet == 1)
    {
        return tex2Dlod(
            GlyphAtlas16,
            float4(atlasUV, 0.0, 0.0)
        ).r;
    }

    return tex2Dlod(
        GlyphAtlas,
        float4(atlasUV, 0.0, 0.0)
    ).r;
}

int GetPaletteStopIndex(float glyphIndex)
{
    int threeGlyphBand = int(
        max(glyphIndex - 1.0, 0.0)
    ) / 3;

    if (GlyphSet == 0)
    {
        return min(threeGlyphBand * 2, 4);
    }

    return min(threeGlyphBand, 4);
}

float3 GetCustomPaletteRampColor(int paletteStop)
{
    if (paletteStop <= 0)
    {
        return PaletteRampColor0;
    }

    if (paletteStop == 1)
    {
        return PaletteRampColor1;
    }

    if (paletteStop == 2)
    {
        return PaletteRampColor2;
    }

    if (paletteStop == 3)
    {
        return PaletteRampColor3;
    }

    return PaletteRampColor4;
}

float3 GetPaletteStopDebugColor(int paletteStop)
{
    if (paletteStop <= 0)
    {
        return float3(1.0, 0.1, 0.1);
    }

    if (paletteStop == 1)
    {
        return float3(1.0, 0.7, 0.1);
    }

    if (paletteStop == 2)
    {
        return float3(0.1, 1.0, 0.2);
    }

    if (paletteStop == 3)
    {
        return float3(0.1, 0.8, 1.0);
    }

    return float3(0.55, 0.25, 1.0);
}

float3 SampleGeneratedPaletteRole(int roleIndex)
{
    float2 paletteUV = float2(
        (float(clamp(roleIndex, 0, 5)) + 0.5) / 6.0,
        0.5
    );

    return tex2Dlod(
        AsciiGeneratedPalette,
        float4(paletteUV, 0.0, 0.0)
    ).rgb;
}

float3 GetPaletteForegroundColor(float glyphIndex)
{
    int paletteStop = GetPaletteStopIndex(glyphIndex);

    if (PaletteType == 2)
    {
        return GetCustomPaletteRampColor(
            paletteStop
        );
    }

    if (PaletteType == 0)
    {
        return SampleGeneratedPaletteRole(
            paletteStop + 1
        );
    }

    return PaletteGlyphColor;
}

float3 GetPaletteBackgroundColor()
{
    if (PaletteType == 2)
    {
        return PaletteRampBackgroundColor;
    }

    if (PaletteType == 0)
    {
        return SampleGeneratedPaletteRole(0);
    }

    return PaletteBackgroundColor;
}

float CalculateGlyphIndex(float luminance)
{
    float glyphCount = GetActiveGlyphCount();

    return min(
        floor(luminance * glyphCount),
        glyphCount - 1.0
    );
}

float3 CalculateCellTint(float3 sourceColor)
{
    float3 nonNegativeColor = max(
        sourceColor,
        float3(0.0, 0.0, 0.0)
    );

    float maximumChannel = max(
        nonNegativeColor.r,
        max(nonNegativeColor.g, nonNegativeColor.b)
    );

    if (maximumChannel <= 0.0001)
    {
        float blackCellValue = lerp(
            1.0,
            0.0,
            saturate(CellTintValueInfluence)
        );

        return float3(
            blackCellValue,
            blackCellValue,
            blackCellValue
        );
    }

    float3 fullValueTint =
        nonNegativeColor / maximumChannel;

    float influencedValue = lerp(
        1.0,
        saturate(maximumChannel),
        saturate(CellTintValueInfluence)
    );

    return fullValueTint * influencedValue;
}

struct CellEdgeDirectionSummary
{
    int dominantDirection;
    float dominantCount;
    float runnerUpCount;
    float totalCount;
};

struct CellEdgeClassification
{
    int dominantDirection;
    float dominantCount;
    float runnerUpCount;
    float totalCount;
    float dominance;
    float effectiveMinimumSupport;
    float isCandidate;
};

CellEdgeDirectionSummary SummarizeCellEdgeDirections(
    float4 directionCounts
)
{
    CellEdgeDirectionSummary summary;

    summary.dominantDirection = 0;
    summary.dominantCount = directionCounts.x;
    summary.runnerUpCount = 0.0;
    summary.totalCount =
        directionCounts.x
        + directionCounts.y
        + directionCounts.z
        + directionCounts.w;

    if (directionCounts.y > summary.dominantCount)
    {
        summary.runnerUpCount = summary.dominantCount;
        summary.dominantDirection = 1;
        summary.dominantCount = directionCounts.y;
    }
    else
    {
        summary.runnerUpCount = max(
            summary.runnerUpCount,
            directionCounts.y
        );
    }

    if (directionCounts.z > summary.dominantCount)
    {
        summary.runnerUpCount = summary.dominantCount;
        summary.dominantDirection = 2;
        summary.dominantCount = directionCounts.z;
    }
    else
    {
        summary.runnerUpCount = max(
            summary.runnerUpCount,
            directionCounts.z
        );
    }

    if (directionCounts.w > summary.dominantCount)
    {
        summary.runnerUpCount = summary.dominantCount;
        summary.dominantDirection = 3;
        summary.dominantCount = directionCounts.w;
    }
    else
    {
        summary.runnerUpCount = max(
            summary.runnerUpCount,
            directionCounts.w
        );
    }

    return summary;
}

CellEdgeClassification ClassifyCellEdgeWithThresholds(
    float4 directionCounts,
    float sampleCount,
    float minimumDominantPixels,
    float minimumDominance
)
{
    CellEdgeClassification classification;

    CellEdgeDirectionSummary summary =
        SummarizeCellEdgeDirections(directionCounts);

    classification.dominantDirection =
        summary.dominantDirection;

    classification.dominantCount =
        summary.dominantCount;

    classification.runnerUpCount =
        summary.runnerUpCount;

    classification.totalCount =
        summary.totalCount;

    float safeSampleCount = max(sampleCount, 1.0);
    float fullCellSampleCount =
        float(ASCII_CELL_SIZE * ASCII_CELL_SIZE);

    classification.effectiveMinimumSupport =
        max(minimumDominantPixels, 0.0)
        * safeSampleCount
        / fullCellSampleCount;

    classification.dominance =
        classification.totalCount > 0.00001
            ? saturate(
                classification.dominantCount
                / classification.totalCount
            )
            : 0.0;

    bool hasEvidence =
        classification.totalCount > 0.00001;

    bool hasSupport =
        classification.dominantCount
        >= classification.effectiveMinimumSupport;

    bool hasDominance =
        classification.dominance
        >= saturate(minimumDominance);

    bool hasUniqueDirection =
        classification.dominantCount
        > classification.runnerUpCount;

    classification.isCandidate =
        hasEvidence
        && hasSupport
        && hasDominance
        && hasUniqueDirection
            ? 1.0
            : 0.0;

    return classification;
}

CellEdgeClassification ClassifyCellEdge(
    float4 directionCounts,
    float sampleCount
)
{
    return ClassifyCellEdgeWithThresholds(
        directionCounts,
        sampleCount,
        CellEdgeMinimumDominantPixels,
        CellEdgeMinimumDominance
    );
}

CellEdgeClassification ClassifyDepthCellEdge(
    float4 directionCounts,
    float sampleCount
)
{
    return ClassifyCellEdgeWithThresholds(
        directionCounts,
        sampleCount,
        DepthCellEdgeMinimumDominantPixels,
        DepthCellEdgeMinimumDominance
    );
}

float GetDirectionVoteCount(
    float4 directionCounts,
    int direction
)
{
    if (direction == 0)
    {
        return directionCounts.x;
    }

    if (direction == 1)
    {
        return directionCounts.y;
    }

    if (direction == 2)
    {
        return directionCounts.z;
    }

    return directionCounts.w;
}

int DecodeTemporalDirection(float encodedDirection)
{
    return int(floor(
        saturate(encodedDirection) * 3.0 + 0.5
    ));
}

float4 CalculateTemporalEdgeStateWithThresholds(
    float4 directionCounts,
    float sampleCount,
    float4 previousState,
    float entrySupport,
    float entryDominance,
    float retentionSupport,
    float retentionDominance,
    float directionSwitchMargin
)
{
    CellEdgeClassification currentClassification =
        ClassifyCellEdgeWithThresholds(
            directionCounts,
            sampleCount,
            entrySupport,
            entryDominance
        );

    float outputCandidate =
        currentClassification.isCandidate;

    int outputDirection =
        currentClassification.dominantDirection;

    bool historyIsValid =
        previousState.a > 0.999;

    bool previousWasCandidate =
        historyIsValid
        && previousState.r > 0.5;

    if (previousWasCandidate)
    {
        int previousDirection =
            DecodeTemporalDirection(previousState.g);

        float previousDirectionCount =
            GetDirectionVoteCount(
                directionCounts,
                previousDirection
            );

        float totalCount =
            directionCounts.x
            + directionCounts.y
            + directionCounts.z
            + directionCounts.w;

        float fullCellSampleCount =
            float(ASCII_CELL_SIZE * ASCII_CELL_SIZE);

        float safeSampleCount = max(
            sampleCount,
            1.0
        );

        float effectiveRetentionSupport =
            max(retentionSupport, 0.0)
            * safeSampleCount
            / fullCellSampleCount;

        float previousDirectionDominance =
            totalCount > 0.00001
                ? previousDirectionCount / totalCount
                : 0.0;

        bool canRetainPrevious =
            previousDirectionCount
                >= effectiveRetentionSupport
            && previousDirectionDominance
                >= saturate(
                    retentionDominance
                );

        bool currentMatchesPrevious =
            currentClassification.isCandidate > 0.5
            && currentClassification.dominantDirection
                == previousDirection;

        float effectiveSwitchMargin =
            max(
                directionSwitchMargin,
                0.0
            )
            * safeSampleCount
            / fullCellSampleCount;

        bool canSwitchDirection =
            currentClassification.isCandidate > 0.5
            && currentClassification.dominantDirection
                != previousDirection
            && currentClassification.dominantCount
                >= previousDirectionCount
                    + effectiveSwitchMargin;

        if (currentMatchesPrevious)
        {
            outputCandidate = 1.0;
            outputDirection = previousDirection;
        }
        else if (canSwitchDirection)
        {
            outputCandidate = 1.0;
            outputDirection =
                currentClassification.dominantDirection;
        }
        else if (canRetainPrevious)
        {
            outputCandidate = 1.0;
            outputDirection = previousDirection;
        }
    }

    bool candidateChanged =
        (outputCandidate > 0.5)
        != (currentClassification.isCandidate > 0.5);

    bool directionChanged =
        outputCandidate > 0.5
        && currentClassification.isCandidate > 0.5
        && outputDirection
            != currentClassification.dominantDirection;

    float intervention =
        candidateChanged || directionChanged
            ? 1.0
            : 0.0;

    return float4(
        outputCandidate,
        float(outputDirection) / 3.0,
        intervention,
        1.0
    );
}

float4 CalculateTemporalEdgeState(
    float4 directionCounts,
    float sampleCount,
    float4 previousState
)
{
    return CalculateTemporalEdgeStateWithThresholds(
        directionCounts,
        sampleCount,
        previousState,
        CellEdgeMinimumDominantPixels,
        CellEdgeMinimumDominance,
        TemporalEdgeRetentionSupport,
        TemporalEdgeRetentionDominance,
        TemporalEdgeDirectionSwitchMargin
    );
}

float4 CalculateTemporalDepthEdgeState(
    float4 directionCounts,
    float sampleCount,
    float4 previousState
)
{
    return CalculateTemporalEdgeStateWithThresholds(
        directionCounts,
        sampleCount,
        previousState,
        DepthCellEdgeMinimumDominantPixels,
        DepthCellEdgeMinimumDominance,
        DepthTemporalEdgeRetentionSupport,
        DepthTemporalEdgeRetentionDominance,
        DepthTemporalEdgeDirectionSwitchMargin
    );
}

float3 GetCellEdgeDirectionDebugColor(int direction)
{
    if (direction == 0)
    {
        return float3(1.0, 0.15, 0.15);
    }

    if (direction == 1)
    {
        return float3(1.0, 0.8, 0.1);
    }

    if (direction == 2)
    {
        return float3(0.1, 1.0, 1.0);
    }

    return float3(0.4, 0.25, 1.0);
}

float DisplayThresholdCenteredValue(
    float value,
    float threshold,
    float maximumValue
)
{
    float safeMaximum = max(maximumValue, 0.00001);
    float clampedThreshold = clamp(
        threshold,
        0.0,
        safeMaximum
    );

    if (clampedThreshold <= 0.00001)
    {
        return value > 0.00001
            ? 0.5 + 0.5 * saturate(value / safeMaximum)
            : 0.5;
    }

    if (value <= clampedThreshold)
    {
        return 0.5 * saturate(
            value / clampedThreshold
        );
    }

    float remainingRange =
        safeMaximum - clampedThreshold;

    return remainingRange > 0.00001
        ? 0.5 + 0.5 * saturate(
            (value - clampedThreshold)
            / remainingRange
        )
        : 0.5;
}

int GetEdgeGlyphIndexForDirection(int direction)
{
    if (direction == 0)
    {
        return 2;
    }

    if (direction == 1)
    {
        return 4;
    }

    if (direction == 2)
    {
        return 1;
    }

    return 3;
}

int GetEdgeGlyphIndex(
    CellEdgeClassification classification
)
{
    if (classification.isCandidate <= 0.5)
    {
        return 0;
    }

    return GetEdgeGlyphIndexForDirection(
        classification.dominantDirection
    );
}

int GetTemporalEdgeGlyphIndex(float4 temporalState)
{
    if (temporalState.r <= 0.5)
    {
        return 0;
    }

    int direction = DecodeTemporalDirection(
        temporalState.g
    );

    return GetEdgeGlyphIndexForDirection(direction);
}

struct CombinedCellEdgeSelection
{
    int direction;
    float isCandidate;
    float imageCandidate;
    float depthCandidate;
};

float CalculateCellSampleCount(uint2 cellCoordinate)
{
    uint2 sourceOrigin =
        cellCoordinate * ASCII_CELL_SIZE;

    uint2 sourceEnd = min(
        sourceOrigin + ASCII_CELL_SIZE,
        uint2(BUFFER_WIDTH, BUFFER_HEIGHT)
    );

    uint2 sampleExtent = sourceEnd - sourceOrigin;

    return max(
        float(sampleExtent.x * sampleExtent.y),
        1.0
    );
}

CombinedCellEdgeSelection SelectCombinedCellEdge(
    uint2 cellCoordinate,
    bool useTemporalState
)
{
    float2 cellUV =
        (float2(cellCoordinate) + 0.5)
        / float2(
            ASCII_CELL_TEXTURE_WIDTH,
            ASCII_CELL_TEXTURE_HEIGHT
        );

    CombinedCellEdgeSelection selection;
    selection.direction = 0;
    selection.isCandidate = 0.0;
    selection.imageCandidate = 0.0;
    selection.depthCandidate = 0.0;

    int imageDirection = 0;

    if (useTemporalState)
    {
        float4 imageState = tex2Dlod(
            AsciiCellEdgeState,
            float4(cellUV, 0.0, 0.0)
        );

        selection.imageCandidate =
            imageState.r > 0.5 ? 1.0 : 0.0;

        imageDirection = DecodeTemporalDirection(
            imageState.g
        );
    }
    else
    {
        float sampleCount = CalculateCellSampleCount(
            cellCoordinate
        );

        float4 imageDirectionCounts = tex2Dlod(
            AsciiCellEdgeHistogram,
            float4(cellUV, 0.0, 0.0)
        );

        CellEdgeClassification imageClassification =
            ClassifyCellEdge(
                imageDirectionCounts,
                sampleCount
            );

        selection.imageCandidate =
            imageClassification.isCandidate;

        imageDirection =
            imageClassification.dominantDirection;
    }

    selection.isCandidate = selection.imageCandidate;
    selection.direction = imageDirection;

    if (EnableDepthEdges && DepthBufferAvailable)
    {
        int depthDirection = 0;

        if (useTemporalState)
        {
            float4 depthState = tex2Dlod(
                AsciiDepthCellEdgeState,
                float4(cellUV, 0.0, 0.0)
            );

            selection.depthCandidate =
                depthState.r > 0.5 ? 1.0 : 0.0;

            depthDirection = DecodeTemporalDirection(
                depthState.g
            );
        }
        else
        {
            float sampleCount = CalculateCellSampleCount(
                cellCoordinate
            );

            float4 depthDirectionCounts = tex2Dlod(
                AsciiCellDepthEdgeHistogram,
                float4(cellUV, 0.0, 0.0)
            );

            CellEdgeClassification depthClassification =
                ClassifyDepthCellEdge(
                    depthDirectionCounts,
                    sampleCount
                );

            selection.depthCandidate =
                depthClassification.isCandidate;

            depthDirection =
                depthClassification.dominantDirection;
        }

        if (selection.depthCandidate > 0.5)
        {
            selection.isCandidate = 1.0;
            selection.direction = depthDirection;
        }
    }

    return selection;
}

float LoadFullResolutionLuminance(int2 pixelPosition)
{
    int2 maximumPixel = int2(
        BUFFER_WIDTH - 1,
        BUFFER_HEIGHT - 1
    );

    int2 clampedPosition = clamp(
        pixelPosition,
        int2(0, 0),
        maximumPixel
    );

    float2 sampleUV =
        (float2(clampedPosition) + 0.5)
        * BUFFER_PIXEL_SIZE;

    return tex2Dlod(
        AsciiFullResolutionLuminance,
        float4(sampleUV, 0.0, 0.0)
    ).r;
}

float LoadLinearizedDepth(int2 pixelPosition)
{
    int2 maximumPixel = int2(
        BUFFER_WIDTH - 1,
        BUFFER_HEIGHT - 1
    );

    int2 clampedPosition = clamp(
        pixelPosition,
        int2(0, 0),
        maximumPixel
    );

    float2 sampleUV =
        (float2(clampedPosition) + 0.5)
        * BUFFER_PIXEL_SIZE;

    return ReShade::GetLinearizedDepth(sampleUV);
}

struct DepthSobelResult
{
    float2 gradient;
    float nearestDepth;
};

DepthSobelResult CalculateDepthSobel(int2 pixelPosition)
{
    float d00 = LoadLinearizedDepth(
        pixelPosition + int2(-1, -1)
    );

    float d10 = LoadLinearizedDepth(
        pixelPosition + int2(0, -1)
    );

    float d20 = LoadLinearizedDepth(
        pixelPosition + int2(1, -1)
    );

    float d01 = LoadLinearizedDepth(
        pixelPosition + int2(-1, 0)
    );

    float d11 = LoadLinearizedDepth(
        pixelPosition
    );

    float d21 = LoadLinearizedDepth(
        pixelPosition + int2(1, 0)
    );

    float d02 = LoadLinearizedDepth(
        pixelPosition + int2(-1, 1)
    );

    float d12 = LoadLinearizedDepth(
        pixelPosition + int2(0, 1)
    );

    float d22 = LoadLinearizedDepth(
        pixelPosition + int2(1, 1)
    );

    float gradientX =
        (d20 + 2.0 * d21 + d22)
        - (d00 + 2.0 * d01 + d02);

    float gradientY =
        (d02 + 2.0 * d12 + d22)
        - (d00 + 2.0 * d10 + d20);

    DepthSobelResult result;

    result.gradient = float2(
        gradientX,
        gradientY
    );

    result.nearestDepth = min(
        min(
            min(d00, d10),
            min(d20, d01)
        ),
        min(
            min(d11, d21),
            min(
                min(d02, d12),
                d22
            )
        )
    );

    return result;
}

float CalculateDepthProximityWeight(float nearestDepth)
{
    float maximumDistance = saturate(
        DepthEdgeMaximumDistance
    );

    float fadeWidth = min(
        max(DepthEdgeFadeWidth, 0.0),
        maximumDistance
    );

    if (fadeWidth <= 0.00001)
    {
        return nearestDepth <= maximumDistance
            ? 1.0
            : 0.0;
    }

    float fadeStart =
        maximumDistance - fadeWidth;

    return 1.0 - smoothstep(
        fadeStart,
        maximumDistance,
        nearestDepth
    );
}

float2 LoadGaussianHorizontal(int2 pixelPosition)
{
    int2 maximumPixel = int2(
        BUFFER_WIDTH - 1,
        BUFFER_HEIGHT - 1
    );

    int2 clampedPosition = clamp(
        pixelPosition,
        int2(0, 0),
        maximumPixel
    );

    float2 sampleUV =
        (float2(clampedPosition) + 0.5)
        * BUFFER_PIXEL_SIZE;

    return tex2Dlod(
        AsciiGaussianHorizontal,
        float4(sampleUV, 0.0, 0.0)
    ).rg;
}

float2 LoadGaussianVertical(int2 pixelPosition)
{
    int2 maximumPixel = int2(
        BUFFER_WIDTH - 1,
        BUFFER_HEIGHT - 1
    );

    int2 clampedPosition = clamp(
        pixelPosition,
        int2(0, 0),
        maximumPixel
    );

    float2 sampleUV =
        (float2(clampedPosition) + 0.5)
        * BUFFER_PIXEL_SIZE;

    return tex2Dlod(
        AsciiGaussianVertical,
        float4(sampleUV, 0.0, 0.0)
    ).rg;
}

float LoadBinaryDoG(int2 pixelPosition)
{
    float2 gaussianPair = LoadGaussianVertical(
        pixelPosition
    );

    float thresholdResponse =
        gaussianPair.x
        - ASCII_DOG_TAU * gaussianPair.y;

    return thresholdResponse >= ASCII_DOG_THRESHOLD
        ? 1.0
        : 0.0;
}

float GetGaussianWeight(
    int sampleOffset,
    float sigma
)
{
    float offset = float(sampleOffset);
    float safeSigma = max(sigma, 0.0001);

    float exponent =
        -(offset * offset)
        / (2.0 * safeSigma * safeSigma);

    return exp(exponent);
}

float4 AnalyzeFullResolutionLuminancePS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    if (
        !NeedsImageEdgePipeline()
        && DiagnosticView
            != ASCII_VIEW_FULL_RESOLUTION_LUMINANCE
    )
    {
        return 0.0;
    }

    uint2 sourcePixel = uint2(position.xy);

    float2 sourceUV =
        (float2(sourcePixel) + 0.5)
        * BUFFER_PIXEL_SIZE;

    float3 sourceColor = tex2Dlod(
        ReShade::BackBuffer,
        float4(sourceUV, 0.0, 0.0)
    ).rgb;

    float luminance = CalculateLuminance(
        DecodeInputColor(sourceColor)
    );

    return float4(luminance, 0.0, 0.0, 1.0);
}

float4 AnalyzeGaussianHorizontalPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    if (!NeedsImageEdgePipeline())
    {
        return 0.0;
    }

    int2 pixelPosition = int2(position.xy);
    float smallSigma = ASCII_GAUSSIAN_SIGMA;
    float largeSigma = max(
        smallSigma * ASCII_GAUSSIAN_SCALE,
        0.0001
    );

    float2 weightedLuminance = float2(0.0, 0.0);
    float2 totalWeight = float2(0.0, 0.0);

    for (
        int sampleOffset = -ASCII_GAUSSIAN_RADIUS;
        sampleOffset <= ASCII_GAUSSIAN_RADIUS;
        ++sampleOffset
    )
    {
        float luminance = LoadFullResolutionLuminance(
            pixelPosition + int2(sampleOffset, 0)
        );

        float smallWeight = GetGaussianWeight(
            sampleOffset,
            smallSigma
        );

        float largeWeight = GetGaussianWeight(
            sampleOffset,
            largeSigma
        );

        weightedLuminance += luminance * float2(
            smallWeight,
            largeWeight
        );

        totalWeight += float2(
            smallWeight,
            largeWeight
        );
    }

    float2 gaussianPair = weightedLuminance / max(
        totalWeight,
        float2(0.0001, 0.0001)
    );

    return float4(gaussianPair, 0.0, 1.0);
}

float4 AnalyzeGaussianVerticalPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    if (!NeedsImageEdgePipeline())
    {
        return 0.0;
    }

    int2 pixelPosition = int2(position.xy);
    float smallSigma = ASCII_GAUSSIAN_SIGMA;
    float largeSigma = max(
        smallSigma * ASCII_GAUSSIAN_SCALE,
        0.0001
    );

    float2 weightedLuminance = float2(0.0, 0.0);
    float2 totalWeight = float2(0.0, 0.0);

    for (
        int sampleOffset = -ASCII_GAUSSIAN_RADIUS;
        sampleOffset <= ASCII_GAUSSIAN_RADIUS;
        ++sampleOffset
    )
    {
        float2 luminancePair = LoadGaussianHorizontal(
            pixelPosition + int2(0, sampleOffset)
        );

        float smallWeight = GetGaussianWeight(
            sampleOffset,
            smallSigma
        );

        float largeWeight = GetGaussianWeight(
            sampleOffset,
            largeSigma
        );

        weightedLuminance += luminancePair * float2(
            smallWeight,
            largeWeight
        );

        totalWeight += float2(
            smallWeight,
            largeWeight
        );
    }

    float2 gaussianPair = weightedLuminance / max(
        totalWeight,
        float2(0.0001, 0.0001)
    );

    return float4(gaussianPair, 0.0, 1.0);
}

float4 AnalyzeEdgeEvidencePS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    if (!NeedsImageEdgePipeline())
    {
        return 0.0;
    }

    int2 pixelPosition = int2(position.xy);

    float l00 = LoadBinaryDoG(
        pixelPosition + int2(-1, -1)
    );

    float l10 = LoadBinaryDoG(
        pixelPosition + int2(0, -1)
    );

    float l20 = LoadBinaryDoG(
        pixelPosition + int2(1, -1)
    );

    float l01 = LoadBinaryDoG(
        pixelPosition + int2(-1, 0)
    );

    float l21 = LoadBinaryDoG(
        pixelPosition + int2(1, 0)
    );

    float l02 = LoadBinaryDoG(
        pixelPosition + int2(-1, 1)
    );

    float l12 = LoadBinaryDoG(
        pixelPosition + int2(0, 1)
    );

    float l22 = LoadBinaryDoG(
        pixelPosition + int2(1, 1)
    );

    float gradientX =
        (l20 + 2.0 * l21 + l22)
        - (l00 + 2.0 * l01 + l02);

    float gradientY =
        (l02 + 2.0 * l12 + l22)
        - (l00 + 2.0 * l10 + l20);

    float2 gradient = float2(
        gradientX,
        gradientY
    );

    return float4(
        gradient,
        0.0,
        0.0
    );
}

float4 AnalyzeDepthEdgeEvidencePS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    if (
        !DepthBufferAvailable
        || !NeedsDepthEdgePipeline()
    )
    {
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    DepthSobelResult depthSobel = CalculateDepthSobel(
        int2(position.xy)
    );

    float magnitude = length(depthSobel.gradient);
    float proximityWeight = CalculateDepthProximityWeight(
        depthSobel.nearestDepth
    );

    float weightedMagnitude =
        magnitude * proximityWeight;

    float accepted =
        weightedMagnitude
            >= max(DepthEdgeMinimumMagnitude, 0.0)
        ? 1.0
        : 0.0;

    return float4(
        depthSobel.gradient,
        accepted,
        proximityWeight
    );
}

float4 CalculateCellDirectionVote(float2 gradient)
{
    float magnitude = length(gradient);

    if (magnitude <= 0.00001)
    {
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    float2 lineDirection = float2(
        -gradient.y,
        gradient.x
    ) / magnitude;

    static const float inverseSquareRootTwo =
        0.70710678118;

    float4 alignment = abs(float4(
        lineDirection.x,
        dot(
            lineDirection,
            float2(
                inverseSquareRootTwo,
                inverseSquareRootTwo
            )
        ),
        lineDirection.y,
        dot(
            lineDirection,
            float2(
                -inverseSquareRootTwo,
                inverseSquareRootTwo
            )
        )
    ));

    int closestDirection = 0;
    float closestAlignment = alignment.x;

    if (alignment.y > closestAlignment)
    {
        closestDirection = 1;
        closestAlignment = alignment.y;
    }

    if (alignment.z > closestAlignment)
    {
        closestDirection = 2;
        closestAlignment = alignment.z;
    }

    if (alignment.w > closestAlignment)
    {
        closestDirection = 3;
    }

    if (closestDirection == 0)
    {
        return float4(1.0, 0.0, 0.0, 0.0);
    }

    if (closestDirection == 1)
    {
        return float4(0.0, 1.0, 0.0, 0.0);
    }

    if (closestDirection == 2)
    {
        return float4(0.0, 0.0, 1.0, 0.0);
    }

    return float4(0.0, 0.0, 0.0, 1.0);
}

float4 AnalyzeCellEdgeHistogramPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    if (!NeedsImageEdgePipeline())
    {
        return 0.0;
    }

    uint2 cellCoordinate = uint2(position.xy);
    uint2 sourceOrigin =
        cellCoordinate * ASCII_CELL_SIZE;

    float4 directionCounts = float4(
        0.0,
        0.0,
        0.0,
        0.0
    );

    for (uint y = 0; y < ASCII_CELL_SIZE; ++y)
    {
        for (uint x = 0; x < ASCII_CELL_SIZE; ++x)
        {
            uint2 sourcePixel =
                sourceOrigin + uint2(x, y);

            if (
                sourcePixel.x >= BUFFER_WIDTH
                || sourcePixel.y >= BUFFER_HEIGHT
            )
            {
                continue;
            }

            float2 sourceUV =
                (float2(sourcePixel) + 0.5)
                * BUFFER_PIXEL_SIZE;

            float2 gradient = tex2Dlod(
                AsciiEdgeEvidence,
                float4(sourceUV, 0.0, 0.0)
            ).rg;

            directionCounts += CalculateCellDirectionVote(
                gradient
            );
        }
    }

    return directionCounts;
}

float4 AnalyzeCellDepthEdgeHistogramPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    if (
        !DepthBufferAvailable
        || !NeedsDepthEdgePipeline()
    )
    {
        return 0.0;
    }

    uint2 cellCoordinate = uint2(position.xy);
    uint2 sourceOrigin =
        cellCoordinate * ASCII_CELL_SIZE;

    float4 directionCounts = float4(
        0.0,
        0.0,
        0.0,
        0.0
    );

    for (uint y = 0; y < ASCII_CELL_SIZE; ++y)
    {
        for (uint x = 0; x < ASCII_CELL_SIZE; ++x)
        {
            uint2 sourcePixel =
                sourceOrigin + uint2(x, y);

            if (
                sourcePixel.x >= BUFFER_WIDTH
                || sourcePixel.y >= BUFFER_HEIGHT
            )
            {
                continue;
            }

            float2 sourceUV =
                (float2(sourcePixel) + 0.5)
                * BUFFER_PIXEL_SIZE;

            float3 evidence = tex2Dlod(
                AsciiDepthEdgeEvidence,
                float4(sourceUV, 0.0, 0.0)
            ).rgb;

            if (evidence.b <= 0.5)
            {
                continue;
            }

            directionCounts += CalculateCellDirectionVote(
                evidence.rg
            );
        }
    }

    return directionCounts;
}

float4 StabilizeCellEdgesPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    if (!NeedsImageTemporalPipeline())
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    uint2 cellCoordinate = uint2(position.xy);

    float2 cellUV =
        (float2(cellCoordinate) + 0.5)
        / float2(
            ASCII_CELL_TEXTURE_WIDTH,
            ASCII_CELL_TEXTURE_HEIGHT
        );

    float4 directionCounts = tex2Dlod(
        AsciiCellEdgeHistogram,
        float4(cellUV, 0.0, 0.0)
    );

    float4 previousState = tex2Dlod(
        AsciiPreviousCellEdgeState,
        float4(cellUV, 0.0, 0.0)
    );

    float sampleCount = CalculateCellSampleCount(
        cellCoordinate
    );

    return CalculateTemporalEdgeState(
        directionCounts,
        sampleCount,
        previousState
    );
}

float4 CopyCellEdgeHistoryPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    return tex2Dlod(
        AsciiCellEdgeState,
        float4(texcoord, 0.0, 0.0)
    );
}

float4 StabilizeDepthCellEdgesPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    if (
        !DepthBufferAvailable
        || !NeedsDepthTemporalPipeline()
    )
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    uint2 cellCoordinate = uint2(position.xy);

    float2 cellUV =
        (float2(cellCoordinate) + 0.5)
        / float2(
            ASCII_CELL_TEXTURE_WIDTH,
            ASCII_CELL_TEXTURE_HEIGHT
        );

    float4 directionCounts = tex2Dlod(
        AsciiCellDepthEdgeHistogram,
        float4(cellUV, 0.0, 0.0)
    );

    float4 previousState = tex2Dlod(
        AsciiPreviousDepthCellEdgeState,
        float4(cellUV, 0.0, 0.0)
    );

    float sampleCount = CalculateCellSampleCount(
        cellCoordinate
    );

    return CalculateTemporalDepthEdgeState(
        directionCounts,
        sampleCount,
        previousState
    );
}

float4 CopyDepthCellEdgeHistoryPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    return tex2Dlod(
        AsciiDepthCellEdgeState,
        float4(texcoord, 0.0, 0.0)
    );
}

float4 AnalyzeCellPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    uint2 cellCoordinate = uint2(position.xy);

    uint2 sourceOrigin =
        cellCoordinate * ASCII_CELL_SIZE;

    float3 colorSum = float3(0.0, 0.0, 0.0);
    float sampleCount = 0.0;

    for (uint y = 0; y < ASCII_CELL_SIZE; ++y)
    {
        for (uint x = 0; x < ASCII_CELL_SIZE; ++x)
        {
            uint2 sourcePixel =
                sourceOrigin + uint2(x, y);

            if (
                sourcePixel.x < BUFFER_WIDTH
                && sourcePixel.y < BUFFER_HEIGHT
            )
            {
                float2 sourceUV =
                    (float2(sourcePixel) + 0.5)
                    * BUFFER_PIXEL_SIZE;

                float3 sourceColor = tex2Dlod(
                    ReShade::BackBuffer,
                    float4(sourceUV, 0.0, 0.0)
                ).rgb;

                colorSum += DecodeInputColor(sourceColor);

                sampleCount += 1.0;
            }
        }
    }

    float3 averageColor =
        colorSum / max(sampleCount, 1.0);

    return float4(averageColor, 1.0);
}

float4 DisplayGlyphAtlasPreview(uint2 outputPixel)
{
    static const uint previewScale = 8u;

    uint activeAtlasWidth =
        uint(GetActiveGlyphCount())
        * ASCII_GLYPH_WIDTH;

    uint2 previewSize = uint2(
        activeAtlasWidth,
        ASCII_GLYPH_ATLAS_HEIGHT
    ) * previewScale;

    if (any(outputPixel >= previewSize))
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    uint2 atlasPixel =
        outputPixel / previewScale;

    float2 atlasUV =
        (float2(atlasPixel) + 0.5)
        / float2(
            activeAtlasWidth,
            ASCII_GLYPH_ATLAS_HEIGHT
        );

    float glyphMask = SampleActiveGlyphAtlas(
        atlasUV
    );

    return float4(
        glyphMask,
        glyphMask,
        glyphMask,
        1.0
    );
}

float4 RenderLuminanceAscii(
    uint2 outputPixel,
    float glyphIndex,
    float3 cellColor
)
{
    uint2 localPixel =
        outputPixel % ASCII_CELL_SIZE;

    float2 glyphUV =
        (float2(localPixel) + 0.5)
        / float2(
            ASCII_GLYPH_WIDTH,
            ASCII_GLYPH_HEIGHT
        );

    float2 atlasUV = float2(
        (
            glyphIndex
            + glyphUV.x
        ) / GetActiveGlyphCount(),
        glyphUV.y
    );

    float glyphMask = SampleActiveGlyphAtlas(
        atlasUV
    );

    if (EnableEdgeGlyphs)
    {
        uint2 cellCoordinate =
            outputPixel / ASCII_CELL_SIZE;

        CombinedCellEdgeSelection edgeSelection =
            SelectCombinedCellEdge(
                cellCoordinate,
                EnableTemporalEdgeStability
            );

        int edgeGlyphIndex =
            edgeSelection.isCandidate > 0.5
                ? GetEdgeGlyphIndexForDirection(
                    edgeSelection.direction
                )
                : 0;

        if (edgeGlyphIndex > 0)
        {

            float2 edgeAtlasUV = float2(
                (
                    float(edgeGlyphIndex)
                    + glyphUV.x
                ) / ASCII_EDGE_GLYPH_COUNT,
                glyphUV.y
            );

            glyphMask = tex2Dlod(
                EdgeGlyphAtlas,
                float4(edgeAtlasUV, 0.0, 0.0)
            ).r;
        }
    }

    float3 foregroundColor =
        float3(1.0, 1.0, 1.0);

    float3 backgroundColor =
        float3(0.0, 0.0, 0.0);

    if (ColorMode == 1)
    {
        foregroundColor = GetPaletteForegroundColor(
            glyphIndex
        );

        backgroundColor = GetPaletteBackgroundColor();
    }
    else if (ColorMode == 2)
    {
        foregroundColor = EncodeAnalysisColor(
            CalculateCellTint(cellColor)
        );
    }

    return float4(
        lerp(
            backgroundColor,
            foregroundColor,
            glyphMask
        ),
        1.0
    );
}

float4 RenderEdgeGlyphDiagnostic(
    uint2 outputPixel,
    int edgeGlyphIndex
)
{
    uint2 localPixel =
        outputPixel % ASCII_CELL_SIZE;

    float2 glyphUV =
        (float2(localPixel) + 0.5)
        / float2(
            ASCII_GLYPH_WIDTH,
            ASCII_GLYPH_HEIGHT
        );

    float2 atlasUV = float2(
        (
            float(edgeGlyphIndex)
            + glyphUV.x
        ) / ASCII_EDGE_GLYPH_COUNT,
        glyphUV.y
    );

    float glyphMask = tex2Dlod(
        EdgeGlyphAtlas,
        float4(atlasUV, 0.0, 0.0)
    ).r;

    float3 foregroundColor =
        float3(1.0, 1.0, 1.0);

    float3 backgroundColor =
        float3(0.0, 0.0, 0.0);

    if (ColorMode == 1)
    {
        foregroundColor = GetPaletteForegroundColor(
            GetActiveGlyphCount() - 1.0
        );

        backgroundColor = GetPaletteBackgroundColor();
    }

    return float4(
        lerp(
            backgroundColor,
            foregroundColor,
            glyphMask
        ),
        1.0
    );
}

float4 RenderEdgeOnlyAscii(
    uint2 outputPixel,
    bool useTemporalState
)
{
    uint2 cellCoordinate =
        outputPixel / ASCII_CELL_SIZE;

    float2 cellUV =
        (float2(cellCoordinate) + 0.5)
        / float2(
            ASCII_CELL_TEXTURE_WIDTH,
            ASCII_CELL_TEXTURE_HEIGHT
        );

    int edgeGlyphIndex = 0;

    if (useTemporalState)
    {
        float4 temporalState = tex2Dlod(
            AsciiCellEdgeState,
            float4(cellUV, 0.0, 0.0)
        );

        edgeGlyphIndex = GetTemporalEdgeGlyphIndex(
            temporalState
        );
    }
    else
    {
        float4 directionCounts = tex2Dlod(
            AsciiCellEdgeHistogram,
            float4(cellUV, 0.0, 0.0)
        );

        float sampleCount = CalculateCellSampleCount(
            cellCoordinate
        );

        CellEdgeClassification classification =
            ClassifyCellEdge(
                directionCounts,
                sampleCount
            );

        edgeGlyphIndex = GetEdgeGlyphIndex(
            classification
        );
    }

    return RenderEdgeGlyphDiagnostic(
        outputPixel,
        edgeGlyphIndex
    );
}

float4 RenderDepthEdgeOnlyAscii(
    uint2 outputPixel,
    bool useTemporalState
)
{
    uint2 cellCoordinate =
        outputPixel / ASCII_CELL_SIZE;

    float2 cellUV =
        (float2(cellCoordinate) + 0.5)
        / float2(
            ASCII_CELL_TEXTURE_WIDTH,
            ASCII_CELL_TEXTURE_HEIGHT
        );

    int edgeGlyphIndex = 0;

    if (useTemporalState)
    {
        float4 temporalState = tex2Dlod(
            AsciiDepthCellEdgeState,
            float4(cellUV, 0.0, 0.0)
        );

        edgeGlyphIndex = GetTemporalEdgeGlyphIndex(
            temporalState
        );
    }
    else
    {
        float4 directionCounts = tex2Dlod(
            AsciiCellDepthEdgeHistogram,
            float4(cellUV, 0.0, 0.0)
        );

        float sampleCount = CalculateCellSampleCount(
            cellCoordinate
        );

        CellEdgeClassification classification =
            ClassifyDepthCellEdge(
                directionCounts,
                sampleCount
            );

        edgeGlyphIndex = GetEdgeGlyphIndex(
            classification
        );
    }

    return RenderEdgeGlyphDiagnostic(
        outputPixel,
        edgeGlyphIndex
    );
}

float4 RenderCombinedEdgeOnlyAscii(uint2 outputPixel)
{
    uint2 cellCoordinate =
        outputPixel / ASCII_CELL_SIZE;

    CombinedCellEdgeSelection selection =
        SelectCombinedCellEdge(
            cellCoordinate,
            EnableTemporalEdgeStability
        );

    int edgeGlyphIndex =
        selection.isCandidate > 0.5
            ? GetEdgeGlyphIndexForDirection(
                selection.direction
            )
            : 0;

    return RenderEdgeGlyphDiagnostic(
        outputPixel,
        edgeGlyphIndex
    );
}

float4 DisplayCellColorPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    uint2 outputPixel = uint2(position.xy);

    if (DiagnosticView == ASCII_VIEW_GENERATED_PALETTE_STRIP)
    {
        int roleIndex = min(
            int(saturate(texcoord.x) * 6.0),
            5
        );

        return float4(
            SampleGeneratedPaletteRole(roleIndex),
            1.0
        );
    }

    if (DiagnosticView == ASCII_VIEW_LINEARIZED_DEPTH)
    {
        if (!DepthBufferAvailable)
        {
            return float4(1.0, 0.0, 1.0, 1.0);
        }

        float2 depthUV =
            (float2(outputPixel) + 0.5)
            * BUFFER_PIXEL_SIZE;

        float displayedDepth = saturate(
            ReShade::GetLinearizedDepth(depthUV)
            * max(DepthDisplayScale, 0.0)
        );

        return float4(
            displayedDepth,
            displayedDepth,
            displayedDepth,
            1.0
        );
    }

    if (
        DiagnosticView >= ASCII_VIEW_DEPTH_SOBEL_MAGNITUDE
        && DiagnosticView <= ASCII_VIEW_DEPTH_EVIDENCE_MASK
    )
    {
        if (!DepthBufferAvailable)
        {
            return float4(1.0, 0.0, 1.0, 1.0);
        }

        float2 depthUV =
            (float2(outputPixel) + 0.5)
            * BUFFER_PIXEL_SIZE;

        float4 depthEvidence = tex2Dlod(
            AsciiDepthEdgeEvidence,
            float4(depthUV, 0.0, 0.0)
        );

        float2 gradient = depthEvidence.rg;
        float magnitude = length(gradient);
        float visibility = saturate(
            magnitude
            * max(DepthSobelDisplayScale, 0.0)
        );

        if (DiagnosticView == ASCII_VIEW_DEPTH_SOBEL_MAGNITUDE)
        {
            return float4(
                visibility,
                visibility,
                visibility,
                1.0
            );
        }

        float proximityWeight = depthEvidence.a;

        if (DiagnosticView == ASCII_VIEW_DEPTH_PROXIMITY_WEIGHT)
        {
            return float4(
                proximityWeight,
                proximityWeight,
                proximityWeight,
                1.0
            );
        }

        float weightedMagnitude =
            magnitude * proximityWeight;

        if (DiagnosticView == ASCII_VIEW_DEPTH_WEIGHTED_MAGNITUDE)
        {
            float weightedVisibility = saturate(
                weightedMagnitude
                * max(DepthSobelDisplayScale, 0.0)
            );

            return float4(
                weightedVisibility,
                weightedVisibility,
                weightedVisibility,
                1.0
            );
        }

        if (DiagnosticView == ASCII_VIEW_DEPTH_EVIDENCE_MASK)
        {
            float acceptedEdge = depthEvidence.b;

            return float4(
                acceptedEdge,
                acceptedEdge,
                acceptedEdge,
                1.0
            );
        }

        if (magnitude <= 0.00001)
        {
            return float4(0.0, 0.0, 0.0, 1.0);
        }

        float2 direction = gradient / magnitude;
        float2 encodedDirection =
            direction * 0.5 + 0.5;

        float3 directionColor = float3(
            encodedDirection,
            0.5
        ) * visibility;

        return float4(
            EncodeAnalysisColor(directionColor),
            1.0
        );
    }

    if (
        DiagnosticView >= ASCII_VIEW_DEPTH_CELL_PIXEL_COUNT
        && DiagnosticView <= ASCII_VIEW_DEPTH_EDGE_ONLY
    )
    {
        if (!DepthBufferAvailable)
        {
            return float4(1.0, 0.0, 1.0, 1.0);
        }

        if (DiagnosticView == ASCII_VIEW_DEPTH_EDGE_ONLY)
        {
            return RenderDepthEdgeOnlyAscii(
                outputPixel,
                false
            );
        }

        uint2 cellCoordinate =
            outputPixel / ASCII_CELL_SIZE;

        float2 cellUV =
            (float2(cellCoordinate) + 0.5)
            / float2(
                ASCII_CELL_TEXTURE_WIDTH,
                ASCII_CELL_TEXTURE_HEIGHT
            );

        float4 directionCounts = tex2Dlod(
            AsciiCellDepthEdgeHistogram,
            float4(cellUV, 0.0, 0.0)
        );

        float sampleCount = CalculateCellSampleCount(
            cellCoordinate
        );

        CellEdgeClassification classification =
            ClassifyDepthCellEdge(
                directionCounts,
                sampleCount
            );

        if (DiagnosticView == ASCII_VIEW_DEPTH_CELL_PIXEL_COUNT)
        {
            float acceptedProportion = saturate(
                classification.totalCount / sampleCount
            );

            float3 displayValue = EncodeAnalysisColor(
                float3(
                    acceptedProportion,
                    acceptedProportion,
                    acceptedProportion
                )
            );

            return float4(displayValue, 1.0);
        }

        if (DiagnosticView == ASCII_VIEW_DEPTH_CELL_SUPPORT)
        {
            float displayedSupport =
                DisplayThresholdCenteredValue(
                    classification.dominantCount,
                    classification.effectiveMinimumSupport,
                    sampleCount
                );

            return float4(
                displayedSupport,
                displayedSupport,
                displayedSupport,
                1.0
            );
        }

        if (DiagnosticView == ASCII_VIEW_DEPTH_CELL_DOMINANCE)
        {
            float displayedDominance =
                classification.totalCount > 0.00001
                    ? DisplayThresholdCenteredValue(
                        classification.dominance,
                        saturate(
                            DepthCellEdgeMinimumDominance
                        ),
                        1.0
                    )
                    : 0.0;

            return float4(
                displayedDominance,
                displayedDominance,
                displayedDominance,
                1.0
            );
        }

        if (DiagnosticView == ASCII_VIEW_DEPTH_CELL_DIRECTION)
        {
            float3 directionColor =
                classification.totalCount > 0.00001
                    ? GetCellEdgeDirectionDebugColor(
                        classification.dominantDirection
                    )
                    : float3(0.0, 0.0, 0.0);

            return float4(
                EncodeAnalysisColor(directionColor),
                1.0
            );
        }

        return float4(
            classification.isCandidate,
            classification.isCandidate,
            classification.isCandidate,
            1.0
        );
    }

    if (
        DiagnosticView >= ASCII_VIEW_DEPTH_STABILIZED_CANDIDATE
        && DiagnosticView <= ASCII_VIEW_DEPTH_STABILIZED_EDGE_ONLY
    )
    {
        if (!DepthBufferAvailable)
        {
            return float4(1.0, 0.0, 1.0, 1.0);
        }

        if (DiagnosticView == ASCII_VIEW_DEPTH_STABILIZED_EDGE_ONLY)
        {
            return RenderDepthEdgeOnlyAscii(
                outputPixel,
                true
            );
        }

        uint2 cellCoordinate =
            outputPixel / ASCII_CELL_SIZE;

        float2 cellUV =
            (float2(cellCoordinate) + 0.5)
            / float2(
                ASCII_CELL_TEXTURE_WIDTH,
                ASCII_CELL_TEXTURE_HEIGHT
            );

        float4 temporalState = tex2Dlod(
            AsciiDepthCellEdgeState,
            float4(cellUV, 0.0, 0.0)
        );

        if (DiagnosticView == ASCII_VIEW_DEPTH_STABILIZED_CANDIDATE)
        {
            return float4(
                temporalState.rrr,
                1.0
            );
        }

        if (DiagnosticView == ASCII_VIEW_DEPTH_STABILIZED_DIRECTION)
        {
            float3 directionColor =
                temporalState.r > 0.5
                    ? GetCellEdgeDirectionDebugColor(
                        DecodeTemporalDirection(
                            temporalState.g
                        )
                    )
                    : float3(0.0, 0.0, 0.0);

            return float4(
                EncodeAnalysisColor(directionColor),
                1.0
            );
        }

        return float4(
            temporalState.bbb,
            1.0
        );
    }

    if (
        DiagnosticView == ASCII_VIEW_COMBINED_EDGE_SOURCE
        || DiagnosticView == ASCII_VIEW_COMBINED_EDGE_ONLY
    )
    {
        if (DiagnosticView == ASCII_VIEW_COMBINED_EDGE_ONLY)
        {
            return RenderCombinedEdgeOnlyAscii(
                outputPixel
            );
        }

        uint2 cellCoordinate =
            outputPixel / ASCII_CELL_SIZE;

        CombinedCellEdgeSelection selection =
            SelectCombinedCellEdge(
                cellCoordinate,
                EnableTemporalEdgeStability
            );

        bool hasImageEdge =
            selection.imageCandidate > 0.5;

        bool hasDepthEdge =
            selection.depthCandidate > 0.5;

        float3 sourceColor =
            float3(0.0, 0.0, 0.0);

        if (hasImageEdge && hasDepthEdge)
        {
            sourceColor = float3(1.0, 0.8, 0.1);
        }
        else if (hasDepthEdge)
        {
            sourceColor = float3(0.1, 1.0, 0.2);
        }
        else if (hasImageEdge)
        {
            sourceColor = float3(0.1, 0.4, 1.0);
        }

        return float4(
            EncodeAnalysisColor(sourceColor),
            1.0
        );
    }

    if (DiagnosticView == ASCII_VIEW_IMAGE_EDGE_ONLY)
    {
        return RenderEdgeOnlyAscii(
            outputPixel,
            false
        );
    }

    if (DiagnosticView == ASCII_VIEW_IMAGE_STABILIZED_EDGE_ONLY)
    {
        return RenderEdgeOnlyAscii(
            outputPixel,
            true
        );
    }

    if (
        DiagnosticView >= ASCII_VIEW_IMAGE_STABILIZED_CANDIDATE
        && DiagnosticView <= ASCII_VIEW_IMAGE_TEMPORAL_INTERVENTION
    )
    {
        uint2 cellCoordinate =
            outputPixel / ASCII_CELL_SIZE;

        float2 cellUV =
            (float2(cellCoordinate) + 0.5)
            / float2(
                ASCII_CELL_TEXTURE_WIDTH,
                ASCII_CELL_TEXTURE_HEIGHT
            );

        float4 temporalState = tex2Dlod(
            AsciiCellEdgeState,
            float4(cellUV, 0.0, 0.0)
        );

        if (DiagnosticView == ASCII_VIEW_IMAGE_STABILIZED_CANDIDATE)
        {
            return float4(
                temporalState.rrr,
                1.0
            );
        }

        if (DiagnosticView == ASCII_VIEW_IMAGE_STABILIZED_DIRECTION)
        {
            float3 directionColor =
                temporalState.r > 0.5
                    ? GetCellEdgeDirectionDebugColor(
                        DecodeTemporalDirection(
                            temporalState.g
                        )
                    )
                    : float3(0.0, 0.0, 0.0);

            return float4(
                EncodeAnalysisColor(directionColor),
                1.0
            );
        }

        return float4(
            temporalState.bbb,
            1.0
        );
    }

    if (DiagnosticView == ASCII_VIEW_FULL_RESOLUTION_LUMINANCE)
    {
        float luminance = LoadFullResolutionLuminance(
            int2(outputPixel)
        );

        float3 displayLuminance = EncodeAnalysisColor(
            float3(luminance, luminance, luminance)
        );

        return float4(displayLuminance, 1.0);
    }

    if (
        DiagnosticView == ASCII_VIEW_TAU_DOG_RESPONSE
        || DiagnosticView == ASCII_VIEW_BINARY_DOG
    )
    {
        float2 gaussianPair = LoadGaussianVertical(
            int2(outputPixel)
        );

        float thresholdResponse =
            gaussianPair.x
            - ASCII_DOG_TAU * gaussianPair.y;

        float displayScale = max(DoGDisplayScale, 0.0);

        if (DiagnosticView == ASCII_VIEW_BINARY_DOG)
        {
            float accepted =
                thresholdResponse >= ASCII_DOG_THRESHOLD
                    ? 1.0
                    : 0.0;

            return float4(
                accepted,
                accepted,
                accepted,
                1.0
            );
        }

        float response =
            thresholdResponse
            - ASCII_DOG_THRESHOLD;

        float positiveResponse = saturate(
            max(response, 0.0) * displayScale
        );

        float negativeResponse = saturate(
            max(-response, 0.0) * displayScale
        );

        float3 responseColor = float3(
            positiveResponse,
            0.0,
            negativeResponse
        );

        return float4(
            EncodeAnalysisColor(responseColor),
            1.0
        );
    }

    if (
        DiagnosticView == ASCII_VIEW_IMAGE_EVIDENCE_MASK
        || DiagnosticView == ASCII_VIEW_IMAGE_EVIDENCE_DIRECTION
    )
    {
        float2 sampleUV =
            (float2(outputPixel) + 0.5)
            * BUFFER_PIXEL_SIZE;

        float2 gradient = tex2Dlod(
            AsciiEdgeEvidence,
            float4(sampleUV, 0.0, 0.0)
        ).rg;

        if (DiagnosticView == ASCII_VIEW_IMAGE_EVIDENCE_MASK)
        {
            float accepted =
                length(gradient) > 0.00001
                    ? 1.0
                    : 0.0;

            return float4(
                accepted,
                accepted,
                accepted,
                1.0
            );
        }

        float magnitude = length(gradient);
        float visibility = saturate(
            magnitude
            * max(SobelMagnitudeDisplayScale, 0.0)
        );

        if (magnitude <= 0.00001)
        {
            return float4(0.0, 0.0, 0.0, 1.0);
        }

        float2 direction = gradient / magnitude;
        float2 encodedDirection =
            direction * 0.5 + 0.5;

        float3 directionColor = float3(
            encodedDirection,
            0.5
        ) * visibility;

        return float4(
            EncodeAnalysisColor(directionColor),
            1.0
        );
    }

    if (
        DiagnosticView >= ASCII_VIEW_IMAGE_CELL_PIXEL_COUNT
        && DiagnosticView <= ASCII_VIEW_IMAGE_CELL_CANDIDATE
    )
    {
        uint2 cellCoordinate =
            outputPixel / ASCII_CELL_SIZE;

        float2 cellUV =
            (float2(cellCoordinate) + 0.5)
            / float2(
                ASCII_CELL_TEXTURE_WIDTH,
                ASCII_CELL_TEXTURE_HEIGHT
            );

        float4 directionCounts = tex2Dlod(
            AsciiCellEdgeHistogram,
            float4(cellUV, 0.0, 0.0)
        );

        float sampleCount = CalculateCellSampleCount(
            cellCoordinate
        );

        CellEdgeClassification classification =
            ClassifyCellEdge(
                directionCounts,
                sampleCount
            );

        if (DiagnosticView == ASCII_VIEW_IMAGE_CELL_PIXEL_COUNT)
        {
            float acceptedProportion = saturate(
                classification.totalCount / sampleCount
            );

            float3 displayValue = EncodeAnalysisColor(
                float3(
                    acceptedProportion,
                    acceptedProportion,
                    acceptedProportion
                )
            );

            return float4(displayValue, 1.0);
        }

        if (DiagnosticView == ASCII_VIEW_IMAGE_CELL_SUPPORT)
        {
            float displayedSupport =
                DisplayThresholdCenteredValue(
                    classification.dominantCount,
                    classification.effectiveMinimumSupport,
                    sampleCount
                );

            float3 displayValue = float3(
                displayedSupport,
                displayedSupport,
                displayedSupport
            );

            return float4(displayValue, 1.0);
        }

        if (DiagnosticView == ASCII_VIEW_IMAGE_CELL_DOMINANCE)
        {
            float displayedDominance =
                classification.totalCount > 0.00001
                    ? DisplayThresholdCenteredValue(
                        classification.dominance,
                        saturate(CellEdgeMinimumDominance),
                        1.0
                    )
                    : 0.0;

            float3 displayValue = float3(
                displayedDominance,
                displayedDominance,
                displayedDominance
            );

            return float4(displayValue, 1.0);
        }

        if (DiagnosticView == ASCII_VIEW_IMAGE_CELL_DIRECTION)
        {
            float3 directionColor =
                classification.totalCount > 0.00001
                    ? GetCellEdgeDirectionDebugColor(
                        classification.dominantDirection
                    )
                    : float3(0.0, 0.0, 0.0);

            return float4(
                EncodeAnalysisColor(directionColor),
                1.0
            );
        }

        return float4(
            classification.isCandidate,
            classification.isCandidate,
            classification.isCandidate,
            1.0
        );
    }

    if (DiagnosticView == ASCII_VIEW_GLYPH_ATLAS)
    {
        return DisplayGlyphAtlasPreview(
            outputPixel
        );
    }


    uint2 cellCoordinate =
        outputPixel / ASCII_CELL_SIZE;

    float2 cellUV =
        (float2(cellCoordinate) + 0.5)
        / float2(
            ASCII_CELL_TEXTURE_WIDTH,
            ASCII_CELL_TEXTURE_HEIGHT
        );

    float4 cellColor = tex2Dlod(
        AsciiCellColor,
        float4(cellUV, 0.0, 0.0)
    );

    float luminance =
        CalculateLuminance(cellColor.rgb);

    float glyphIndex =
        CalculateGlyphIndex(luminance);

    if (DiagnosticView == ASCII_VIEW_PALETTE_SLOT)
    {
        float3 slotColor =
            glyphIndex < 1.0
                ? float3(0.0, 0.0, 0.0)
                : GetPaletteStopDebugColor(
                    GetPaletteStopIndex(glyphIndex)
                );

        return float4(
            EncodeAnalysisColor(slotColor),
            1.0
        );
    }

    if (DiagnosticView == ASCII_VIEW_OUTPUT)
    {
        return RenderLuminanceAscii(
            outputPixel,
            glyphIndex,
            cellColor.rgb
        );
    }

    if (DiagnosticView == ASCII_VIEW_CELL_LUMINANCE)
    {
        float3 displayLuminance = EncodeAnalysisColor(
            float3(luminance, luminance, luminance)
        );

        return float4(
            displayLuminance,
            1.0
        );
    }

    if (DiagnosticView == ASCII_VIEW_GLYPH_INDEX)
    {
        float glyphCount = GetActiveGlyphCount();

        float normalizedGlyphIndex =
            glyphIndex
            / (glyphCount - 1.0);

        return float4(
            normalizedGlyphIndex,
            normalizedGlyphIndex,
            normalizedGlyphIndex,
            1.0
        );
    }

    return float4(
        EncodeAnalysisColor(cellColor.rgb),
        1.0
    );
}

technique JackYeAscii
{
    pass AnalyzeFullResolutionLuminance
    {
        VertexShader = PostProcessVS;
        PixelShader = AnalyzeFullResolutionLuminancePS;
        RenderTarget = AsciiFullResolutionLuminanceTexture;
    }

    pass AnalyzeGaussianHorizontal
    {
        VertexShader = PostProcessVS;
        PixelShader = AnalyzeGaussianHorizontalPS;
        RenderTarget = AsciiGaussianHorizontalTexture;
    }

    pass AnalyzeGaussianVertical
    {
        VertexShader = PostProcessVS;
        PixelShader = AnalyzeGaussianVerticalPS;
        RenderTarget = AsciiGaussianVerticalTexture;
    }

    pass AnalyzeEdgeEvidence
    {
        VertexShader = PostProcessVS;
        PixelShader = AnalyzeEdgeEvidencePS;
        RenderTarget = AsciiGaussianHorizontalTexture;
    }

    pass AnalyzeDepthEdgeEvidence
    {
        VertexShader = PostProcessVS;
        PixelShader = AnalyzeDepthEdgeEvidencePS;
        RenderTarget = AsciiDepthEdgeEvidenceTexture;
    }

    pass AnalyzeCellEdgeHistogram
    {
        VertexShader = PostProcessVS;
        PixelShader = AnalyzeCellEdgeHistogramPS;
        RenderTarget = AsciiCellEdgeHistogramTexture;
    }

    pass AnalyzeCellDepthEdgeHistogram
    {
        VertexShader = PostProcessVS;
        PixelShader = AnalyzeCellDepthEdgeHistogramPS;
        RenderTarget = AsciiCellDepthEdgeHistogramTexture;
    }

    pass StabilizeCellEdges
    {
        VertexShader = PostProcessVS;
        PixelShader = StabilizeCellEdgesPS;
        RenderTarget = AsciiCellEdgeStateTexture;
    }

    pass StabilizeDepthCellEdges
    {
        VertexShader = PostProcessVS;
        PixelShader = StabilizeDepthCellEdgesPS;
        RenderTarget = AsciiDepthCellEdgeStateTexture;
    }

    pass AnalyzeCells
    {
        VertexShader = PostProcessVS;
        PixelShader = AnalyzeCellPS;
        RenderTarget = AsciiCellColorTexture;
    }

    pass UpdateRandomPaletteState
    {
        VertexShader = PostProcessVS;
        PixelShader = UpdateRandomPaletteStatePS;
        RenderTarget = AsciiRandomPaletteStateTexture;
    }

    pass GeneratePalette
    {
        VertexShader = PostProcessVS;
        PixelShader = GeneratePalettePS;
        RenderTarget = AsciiGeneratedPaletteTexture;
    }

    pass StoreRandomPaletteState
    {
        VertexShader = PostProcessVS;
        PixelShader = CopyRandomPaletteStatePS;
        RenderTarget = AsciiPreviousRandomPaletteStateTexture;
    }

    pass DisplayCells
    {
        VertexShader = PostProcessVS;
        PixelShader = DisplayCellColorPS;
    }

    pass UpdateCellEdgeHistory
    {
        VertexShader = PostProcessVS;
        PixelShader = CopyCellEdgeHistoryPS;
        RenderTarget = AsciiPreviousCellEdgeStateTexture;
    }

    pass UpdateDepthCellEdgeHistory
    {
        VertexShader = PostProcessVS;
        PixelShader = CopyDepthCellEdgeHistoryPS;
        RenderTarget = AsciiPreviousDepthCellEdgeStateTexture;
    }
}
