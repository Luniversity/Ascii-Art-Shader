#include "ReShade.fxh"

#define ASCII_CELL_SIZE 8
#define ASCII_GLYPH_COUNT 10.0

#define ASCII_GLYPH_WIDTH 8
#define ASCII_GLYPH_HEIGHT 8

#define ASCII_GLYPH_ATLAS_WIDTH \
    (ASCII_GLYPH_WIDTH * 10)

#define ASCII_GLYPH_ATLAS_HEIGHT \
    ASCII_GLYPH_HEIGHT

#define ASCII_EDGE_GLYPH_COUNT 5.0

#define ASCII_EDGE_GLYPH_ATLAS_WIDTH \
    (ASCII_GLYPH_WIDTH * 5)

#define ASCII_EDGE_GLYPH_ATLAS_HEIGHT \
    ASCII_GLYPH_HEIGHT

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

texture AsciiEdgeEvidenceTexture
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

texture GlyphAtlasTexture <
    source = "GlyphAtlas.png";
>
{
    Width = ASCII_GLYPH_ATLAS_WIDTH;
    Height = ASCII_GLYPH_ATLAS_HEIGHT;
    Format = R8;
};

texture EdgeGlyphAtlasTexture <
    source = "EdgeGlyphAtlas.png";
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

uniform int ColorMode <
    ui_category = "Appearance";
    ui_label = "Color Mode";
    ui_tooltip =
        "Choose monochrome, a two-color palette, or source-colored glyphs.";
    ui_type = "combo";
    ui_items =
        "Monochrome\0"
        "Palette\0"
        "Cell Tint\0";
> = 1;

uniform float3 PaletteGlyphColor <
    ui_category = "Appearance";
    ui_label = "Glyph Color";
    ui_tooltip =
        "Foreground color used when Color Mode is set to Palette.";
    ui_type = "color";
> = float3(
    0.8392157,
    0.76862746,
    0.64705884
);

uniform float3 PaletteBackgroundColor <
    ui_category = "Appearance";
    ui_label = "Background Color";
    ui_tooltip =
        "Background color used when Color Mode is set to Palette.";
    ui_type = "color";
> = float3(
    0.09383891,
    0.078431375,
    0.078431375
);

uniform bool EnableEdgeGlyphs <
    ui_category = "Appearance";
    ui_label = "Enable Edge Glyphs";
    ui_tooltip =
        "Replace suitable luminance glyphs with directional contour glyphs.";
    ui_type = "checkbox";
> = true;

uniform bool EnableTemporalEdgeStability <
    ui_category = "Appearance";
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

uniform int DebugView <
    ui_category = "Diagnostics";
    ui_category_closed = true;
    ui_label = "Debug View";
    ui_tooltip =
        "Inspect intermediate stages of the ASCII rendering pipeline.";
    ui_type = "combo";
    ui_items =
        "Cell Color\0"
        "Luminance\0"
        "Glyph Index\0"
        "Glyph Atlas\0"
        "ASCII Output\0"
        "Full-Resolution Luminance\0"
        "Sobel Magnitude\0"
        "Sobel Direction\0"
        "Small Gaussian Luminance\0"
        "Large Gaussian Luminance\0"
        "Signed DoG\0"
        "Tau-Adjusted DoG Response\0"
        "Binary DoG\0"
        "Edge Evidence Mask\0"
        "Edge Sobel Magnitude\0"
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
        "Temporal History Validity\0";
> = 4;

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

uniform float GaussianSigma <
    hidden = true;
    ui_label = "Gaussian Sigma";
    ui_type = "slider";
    ui_min = 0.1;
    ui_max = 5.0;
    ui_step = 0.1;
> = 2.0;

uniform int GaussianRadius <
    hidden = true;
    ui_label = "Gaussian Radius";
    ui_type = "slider";
    ui_min = 0;
    ui_max = 8;
    ui_step = 1;
> = 2;

uniform float GaussianScale <
    hidden = true;
    ui_label = "Gaussian Scale";
    ui_type = "slider";
    ui_min = 1.01;
    ui_max = 3.0;
    ui_step = 0.01;
> = 1.6;

uniform float DoGTau <
    hidden = true;
    ui_label = "DoG Tau";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.5;
    ui_step = 0.001;
> = 0.96;

uniform float DoGThreshold <
    hidden = true;
    ui_label = "DoG Threshold";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.1;
    ui_step = 0.001;
> = 0.005;

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
    Texture = AsciiEdgeEvidenceTexture;

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


float CalculateGlyphIndex(float luminance)
{
    return min(
        floor(luminance * ASCII_GLYPH_COUNT),
        ASCII_GLYPH_COUNT - 1.0
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
        return float3(1.0, 1.0, 1.0);
    }

    return nonNegativeColor / maximumChannel;
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

CellEdgeClassification ClassifyCellEdge(
    float4 directionCounts,
    float sampleCount
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
        max(CellEdgeMinimumDominantPixels, 0.0)
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
        >= saturate(CellEdgeMinimumDominance);

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

float4 CalculateTemporalEdgeState(
    float4 directionCounts,
    float sampleCount,
    float4 previousState
)
{
    CellEdgeClassification currentClassification =
        ClassifyCellEdge(
            directionCounts,
            sampleCount
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
            max(TemporalEdgeRetentionSupport, 0.0)
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
                    TemporalEdgeRetentionDominance
                );

        bool currentMatchesPrevious =
            currentClassification.isCandidate > 0.5
            && currentClassification.dominantDirection
                == previousDirection;

        float effectiveSwitchMargin =
            max(
                TemporalEdgeDirectionSwitchMargin,
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

int GetEdgeGlyphIndex(
    CellEdgeClassification classification
)
{
    if (classification.isCandidate <= 0.5)
    {
        return 0;
    }

    if (classification.dominantDirection == 0)
    {
        return 2;
    }

    if (classification.dominantDirection == 1)
    {
        return 4;
    }

    if (classification.dominantDirection == 2)
    {
        return 1;
    }

    return 3;
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
        - DoGTau * gaussianPair.y;

    return thresholdResponse >= max(DoGThreshold, 0.0)
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

float2 CalculateFullResolutionSobel(
    int2 pixelPosition
)
{
    float l00 = LoadFullResolutionLuminance(
        pixelPosition + int2(-1, -1)
    );

    float l10 = LoadFullResolutionLuminance(
        pixelPosition + int2(0, -1)
    );

    float l20 = LoadFullResolutionLuminance(
        pixelPosition + int2(1, -1)
    );

    float l01 = LoadFullResolutionLuminance(
        pixelPosition + int2(-1, 0)
    );

    float l21 = LoadFullResolutionLuminance(
        pixelPosition + int2(1, 0)
    );

    float l02 = LoadFullResolutionLuminance(
        pixelPosition + int2(-1, 1)
    );

    float l12 = LoadFullResolutionLuminance(
        pixelPosition + int2(0, 1)
    );

    float l22 = LoadFullResolutionLuminance(
        pixelPosition + int2(1, 1)
    );

    float gradientX =
        (l20 + 2.0 * l21 + l22)
        - (l00 + 2.0 * l01 + l02);

    float gradientY =
        (l02 + 2.0 * l12 + l22)
        - (l00 + 2.0 * l10 + l20);

    return float2(
        gradientX,
        gradientY
    );
}

float4 AnalyzeGaussianHorizontalPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    int2 pixelPosition = int2(position.xy);
    int activeRadius = clamp(GaussianRadius, 0, 8);

    float smallSigma = max(GaussianSigma, 0.0001);
    float largeSigma = max(
        smallSigma * max(GaussianScale, 1.0),
        0.0001
    );

    float2 weightedLuminance = float2(0.0, 0.0);
    float2 totalWeight = float2(0.0, 0.0);

    for (int sampleOffset = -8; sampleOffset <= 8; ++sampleOffset)
    {
        if (abs(sampleOffset) > activeRadius)
        {
            continue;
        }

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
    int2 pixelPosition = int2(position.xy);
    int activeRadius = clamp(GaussianRadius, 0, 8);

    float smallSigma = max(GaussianSigma, 0.0001);
    float largeSigma = max(
        smallSigma * max(GaussianScale, 1.0),
        0.0001
    );

    float2 weightedLuminance = float2(0.0, 0.0);
    float2 totalWeight = float2(0.0, 0.0);

    for (int sampleOffset = -8; sampleOffset <= 8; ++sampleOffset)
    {
        if (abs(sampleOffset) > activeRadius)
        {
            continue;
        }

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

    float accepted =
        length(gradient) > 0.00001
            ? 1.0
            : 0.0;

    return float4(
        gradient,
        accepted,
        0.0
    );
}

float4 AnalyzeCellEdgeHistogramPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    uint2 cellCoordinate = uint2(position.xy);
    uint2 sourceOrigin =
        cellCoordinate * ASCII_CELL_SIZE;

    float4 directionCounts = float4(
        0.0,
        0.0,
        0.0,
        0.0
    );

    static const float inverseSquareRootTwo =
        0.70710678118;

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
                AsciiEdgeEvidence,
                float4(sourceUV, 0.0, 0.0)
            ).rgb;

            float2 gradient = evidence.rg;
            float magnitude = length(gradient);

            if (
                evidence.b <= 0.5
                || magnitude <= 0.00001
            )
            {
                continue;
            }

            float2 lineDirection = float2(
                -gradient.y,
                gradient.x
            ) / magnitude;

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
                directionCounts.x += 1.0;
            }
            else if (closestDirection == 1)
            {
                directionCounts.y += 1.0;
            }
            else if (closestDirection == 2)
            {
                directionCounts.z += 1.0;
            }
            else
            {
                directionCounts.w += 1.0;
            }
        }
    }

    return directionCounts;
}

float4 StabilizeCellEdgesPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
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

    uint2 sourceOrigin =
        cellCoordinate * ASCII_CELL_SIZE;

    uint2 sourceEnd = min(
        sourceOrigin + ASCII_CELL_SIZE,
        uint2(BUFFER_WIDTH, BUFFER_HEIGHT)
    );

    uint2 sampleExtent =
        sourceEnd - sourceOrigin;

    float sampleCount = max(
        float(sampleExtent.x * sampleExtent.y),
        1.0
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

    uint2 previewSize = uint2(
        ASCII_GLYPH_ATLAS_WIDTH,
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
            ASCII_GLYPH_ATLAS_WIDTH,
            ASCII_GLYPH_ATLAS_HEIGHT
        );

    float glyphMask = tex2Dlod(
        GlyphAtlas,
        float4(atlasUV, 0.0, 0.0)
    ).r;

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
        ) / ASCII_GLYPH_COUNT,
        glyphUV.y
    );

    float glyphMask = tex2Dlod(
        GlyphAtlas,
        float4(atlasUV, 0.0, 0.0)
    ).r;

    if (EnableEdgeGlyphs)
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

        if (EnableTemporalEdgeStability)
        {
            float4 temporalState = tex2Dlod(
                AsciiCellEdgeState,
                float4(cellUV, 0.0, 0.0)
            );

            edgeGlyphIndex =
                GetTemporalEdgeGlyphIndex(
                    temporalState
                );
        }
        else
        {
            float4 directionCounts = tex2Dlod(
                AsciiCellEdgeHistogram,
                float4(cellUV, 0.0, 0.0)
            );

            uint2 sourceOrigin =
                cellCoordinate * ASCII_CELL_SIZE;

            uint2 sourceEnd = min(
                sourceOrigin + ASCII_CELL_SIZE,
                uint2(BUFFER_WIDTH, BUFFER_HEIGHT)
            );

            uint2 sampleExtent =
                sourceEnd - sourceOrigin;

            float sampleCount = max(
                float(sampleExtent.x * sampleExtent.y),
                1.0
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
        foregroundColor = PaletteGlyphColor;
        backgroundColor = PaletteBackgroundColor;
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

        uint2 sourceOrigin =
            cellCoordinate * ASCII_CELL_SIZE;

        uint2 sourceEnd = min(
            sourceOrigin + ASCII_CELL_SIZE,
            uint2(BUFFER_WIDTH, BUFFER_HEIGHT)
        );

        uint2 sampleExtent =
            sourceEnd - sourceOrigin;

        float sampleCount = max(
            float(sampleExtent.x * sampleExtent.y),
            1.0
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
        foregroundColor = PaletteGlyphColor;
        backgroundColor = PaletteBackgroundColor;
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

float4 DisplayCellColorPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    uint2 outputPixel = uint2(position.xy);

    if (DebugView == 21)
    {
        return RenderEdgeOnlyAscii(
            outputPixel,
            false
        );
    }

    if (DebugView == 25)
    {
        return RenderEdgeOnlyAscii(
            outputPixel,
            true
        );
    }

    if (DebugView >= 22 && DebugView <= 24)
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

        if (DebugView == 22)
        {
            return float4(
                temporalState.rrr,
                1.0
            );
        }

        if (DebugView == 23)
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

    if (DebugView == 26)
    {
        uint2 cellCoordinate =
            outputPixel / ASCII_CELL_SIZE;

        float2 cellUV =
            (float2(cellCoordinate) + 0.5)
            / float2(
                ASCII_CELL_TEXTURE_WIDTH,
                ASCII_CELL_TEXTURE_HEIGHT
            );

        float historyIsValid = tex2Dlod(
            AsciiPreviousCellEdgeState,
            float4(cellUV, 0.0, 0.0)
        ).a > 0.999
            ? 1.0
            : 0.0;

        return float4(
            historyIsValid,
            historyIsValid,
            historyIsValid,
            1.0
        );
    }

    if (DebugView == 5)
    {
        float luminance = LoadFullResolutionLuminance(
            int2(outputPixel)
        );

        float3 displayLuminance = EncodeAnalysisColor(
            float3(luminance, luminance, luminance)
        );

        return float4(displayLuminance, 1.0);
    }

    if (DebugView == 6 || DebugView == 7)
    {
        float2 gradient = CalculateFullResolutionSobel(
            int2(outputPixel)
        );

        float magnitude = length(gradient);
        float visibility = saturate(
            magnitude
            * max(SobelMagnitudeDisplayScale, 0.0)
        );

        if (DebugView == 6)
        {
            float3 displayMagnitude = EncodeAnalysisColor(
                float3(visibility, visibility, visibility)
            );

            return float4(displayMagnitude, 1.0);
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

    if (DebugView == 8 || DebugView == 9)
    {
        float2 sampleUV =
            (float2(outputPixel) + 0.5)
            * BUFFER_PIXEL_SIZE;

        float2 gaussianPair = tex2Dlod(
            AsciiGaussianVertical,
            float4(sampleUV, 0.0, 0.0)
        ).rg;

        float luminance =
            DebugView == 8
                ? gaussianPair.x
                : gaussianPair.y;

        float3 displayLuminance = EncodeAnalysisColor(
            float3(luminance, luminance, luminance)
        );

        return float4(displayLuminance, 1.0);
    }

    if (
        DebugView == 10
        || DebugView == 11
        || DebugView == 12
    )
    {
        float2 gaussianPair = LoadGaussianVertical(
            int2(outputPixel)
        );

        float signedDoG =
            gaussianPair.x - gaussianPair.y;

        float thresholdResponse =
            gaussianPair.x
            - DoGTau * gaussianPair.y;

        float displayScale = max(DoGDisplayScale, 0.0);

        if (DebugView == 12)
        {
            float accepted =
                thresholdResponse >= max(DoGThreshold, 0.0)
                    ? 1.0
                    : 0.0;

            return float4(
                accepted,
                accepted,
                accepted,
                1.0
            );
        }

        float response = signedDoG;

        if (DebugView == 11)
        {
            response =
                thresholdResponse
                - max(DoGThreshold, 0.0);
        }

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
        DebugView == 13
        || DebugView == 14
        || DebugView == 15
    )
    {
        float2 sampleUV =
            (float2(outputPixel) + 0.5)
            * BUFFER_PIXEL_SIZE;

        float3 evidence = tex2Dlod(
            AsciiEdgeEvidence,
            float4(sampleUV, 0.0, 0.0)
        ).rgb;

        if (DebugView == 13)
        {
            return float4(
                evidence.b,
                evidence.b,
                evidence.b,
                1.0
            );
        }

        float2 gradient = evidence.rg;
        float magnitude = length(gradient);
        float visibility = saturate(
            magnitude
            * max(SobelMagnitudeDisplayScale, 0.0)
        );

        if (DebugView == 14)
        {
            float3 displayMagnitude = EncodeAnalysisColor(
                float3(visibility, visibility, visibility)
            );

            return float4(displayMagnitude, 1.0);
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

    if (DebugView >= 16 && DebugView <= 20)
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

        uint2 sourceOrigin =
            cellCoordinate * ASCII_CELL_SIZE;

        uint2 sourceEnd = min(
            sourceOrigin + ASCII_CELL_SIZE,
            uint2(BUFFER_WIDTH, BUFFER_HEIGHT)
        );

        uint2 sampleExtent =
            sourceEnd - sourceOrigin;

        float sampleCount = max(
            float(sampleExtent.x * sampleExtent.y),
            1.0
        );

        CellEdgeClassification classification =
            ClassifyCellEdge(
                directionCounts,
                sampleCount
            );

        if (DebugView == 16)
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

        if (DebugView == 17)
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

        if (DebugView == 18)
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

        if (DebugView == 19)
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

    if (DebugView == 3)
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

    if (DebugView == 4)
    {
        return RenderLuminanceAscii(
            outputPixel,
            glyphIndex,
            cellColor.rgb
        );
    }

    if (DebugView == 1)
    {
        float3 displayLuminance = EncodeAnalysisColor(
            float3(luminance, luminance, luminance)
        );

        return float4(
            displayLuminance,
            1.0
        );
    }

    if (DebugView == 2)
    {
        float normalizedGlyphIndex =
            glyphIndex
            / (ASCII_GLYPH_COUNT - 1.0);

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

technique AsciiShader
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
        RenderTarget = AsciiEdgeEvidenceTexture;
    }

    pass AnalyzeCellEdgeHistogram
    {
        VertexShader = PostProcessVS;
        PixelShader = AnalyzeCellEdgeHistogramPS;
        RenderTarget = AsciiCellEdgeHistogramTexture;
    }

    pass StabilizeCellEdges
    {
        VertexShader = PostProcessVS;
        PixelShader = StabilizeCellEdgesPS;
        RenderTarget = AsciiCellEdgeStateTexture;
    }

    pass AnalyzeCells
    {
        VertexShader = PostProcessVS;
        PixelShader = AnalyzeCellPS;
        RenderTarget = AsciiCellColorTexture;
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
}
