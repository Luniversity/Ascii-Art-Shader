Shader "ASCII Shader/Renderer"
{
    Properties
    {
        [Header(Output)]
        _CellWidth ("Cell Width (pixels)", Range(1, 64)) = 8
        _CellHeight ("Cell Height (pixels)", Range(1, 64)) = 8

        [ToggleUI]
        _EnableEdgeGlyphs ("Enable Edge Glyphs", Float) = 1.0

        [Header(Appearance)]
        [Enum(Monochrome, 0, Palette, 1, CellTint, 2)]
        _ColorMode ("Color Mode", Float) = 1

        _GlyphColor (
            "Palette Glyph Color",
            Color
        ) = (0.8392157, 0.76862746, 0.64705884, 1.0)

        _BackgroundColor (
            "Palette Background Color",
            Color
        ) = (0.09383891, 0.078431375, 0.078431375, 1.0)

        [Header(Edge Selection)]
        _CellEdgeMinimumDominantPixels (
            "Minimum Dominant Pixels",
            Range(0.0, 64.0)
        ) = 8.0

        _CellEdgeMinimumDominance (
            "Minimum Dominance",
            Range(0.0, 1.0)
        ) = 0.5

        [Header(Advanced Edge Preprocessing)]
        _GaussianSigma (
            "Gaussian Sigma",
            Range(0.1, 5.0)
        ) = 2.0

        _GaussianRadius (
            "Gaussian Radius",
            Range(0, 8)
        ) = 2

        _GaussianScale (
            "Gaussian Scale",
            Range(1.01, 3.0)
        ) = 1.6

        _DoGTau (
            "DoG Tau",
            Range(0.5, 1.5)
        ) = 0.96

        _DoGThreshold (
            "DoG Threshold",
            Range(0.0, 0.1)
        ) = 0.005

        [Header(Glyph Assets)]
        _GlyphAtlas ("Glyph Atlas", 2D) = "black" {}
        _GlyphCount ("Glyph Count", Range(2, 16)) = 10
        _EdgeGlyphAtlas ("Edge Glyph Atlas", 2D) = "black" {}

        [Header(Diagnostics)]
        [Enum(AsciiDebugView)]
        _DebugView ("Debug View", Float) = 0

        [Enum(AsciiEdgeInput)]
        _EdgeInput ("Reference Sobel Input", Float) = 0

        _SobelMagnitudeDisplayScale (
            "Sobel Display Scale",
            Range(0.01, 10.0)
        ) = 1.0

        _DoGDisplayScale (
            "DoG Display Scale",
            Range(0.01, 20.0)
        ) = 20.0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
        }

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        #define USE_FULL_PRECISION_BLIT_TEXTURE
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        TEXTURE2D(_GlyphAtlas);
        SAMPLER(sampler_GlyphAtlas);

        TEXTURE2D(_EdgeGlyphAtlas);
        SAMPLER(sampler_EdgeGlyphAtlas);

        TEXTURE2D_X(_AsciiCellEdgeDirectionalHistogram);

        CBUFFER_START(UnityPerMaterial)
            float _CellWidth;
            float _CellHeight;
            float _GlyphCount;
            float _EnableEdgeGlyphs;
            float _ColorMode;
            float4 _GlyphColor;
            float4 _BackgroundColor;
            float _DebugView;
            float _EdgeInput;
            float _SobelMagnitudeDisplayScale;
            float _GaussianSigma;
            float _GaussianRadius;
            float _GaussianScale;
            float _DoGTau;
            float _DoGThreshold;
            float _DoGDisplayScale;
            float _CellEdgeMinimumDominantPixels;
            float _CellEdgeMinimumDominance;
        CBUFFER_END


        float2 GetCellSize()
        {
            return max(
                round(float2(_CellWidth, _CellHeight)),
                float2(1.0, 1.0)
            );
        }


        float3 GetCellTint(float3 sourceColor)
        {
            float3 nonNegativeColor = max(
                sourceColor,
                float3(0.0, 0.0, 0.0)
            );

            float maximumChannel = max(
                nonNegativeColor.r,
                max(
                    nonNegativeColor.g,
                    nonNegativeColor.b
                )
            );

            if (maximumChannel <= 0.0001)
            {
                return float3(1.0, 1.0, 1.0);
            }

            return nonNegativeColor / maximumChannel;
        }

        float4 FullResolutionLuminanceFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            int2 sourcePixel =
                int2(input.positionCS.xy);

            float3 sourceColor = LOAD_TEXTURE2D_X(
                _BlitTexture,
                sourcePixel
            ).rgb;

            const float3 luminanceWeights = float3(
                0.2126,
                0.7152,
                0.0722
            );

            float luminance = max(
                dot(sourceColor, luminanceWeights),
                0.0
            );

            return float4(
                luminance,
                0.0,
                0.0,
                1.0
            );
        }
        float4 FullResolutionLuminanceDebugFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            int2 sourcePixel =
                int2(input.positionCS.xy);

            float luminance = LOAD_TEXTURE2D_X(
                _BlitTexture,
                sourcePixel
            ).r;

            luminance = saturate(luminance);

            return float4(
                luminance,
                luminance,
                luminance,
                1.0
            );
        }


        float4 CellAnalysisFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            uint2 cellSize = (uint2)GetCellSize();

            uint2 sourceResolution =
                (uint2)_BlitTexture_TexelSize.zw;

            uint2 cellIndex =
                (uint2)input.positionCS.xy;

            uint2 sourceStart =
                cellIndex * cellSize;

            uint2 sourceEnd = min(
                sourceStart + cellSize,
                sourceResolution
            );

            float3 colorSum = float3(0.0, 0.0, 0.0);

            [loop]
            for (
                uint sourceY = sourceStart.y;
                sourceY < sourceEnd.y;
                ++sourceY
            )
            {
                [loop]
                for (
                    uint sourceX = sourceStart.x;
                    sourceX < sourceEnd.x;
                    ++sourceX
                )
                {
                    int2 sourcePixel = int2(
                        sourceX,
                        sourceY
                    );

                    colorSum += LOAD_TEXTURE2D_X(
                        _BlitTexture,
                        sourcePixel
                    ).rgb;
                }
            }

            uint2 sampleExtent =
                sourceEnd - sourceStart;

            uint sampleCount =
                sampleExtent.x * sampleExtent.y;

            float inverseSampleCount = rcp(
                max((float)sampleCount, 1.0)
            );

            float3 averageColor =
                colorSum * inverseSampleCount;

            return float4(averageColor, 1.0);
        }


        float4 AsciiRendererFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float2 cellSize = GetCellSize();

            float2 pixelPosition =
                input.positionCS.xy;

            uint2 cellIndex =
                (uint2)(pixelPosition / cellSize);

            float4 sourceColor = LOAD_TEXTURE2D_X(
                _BlitTexture,
                int2(cellIndex)
            );

            const float3 luminanceWeights = float3(
                0.2126,
                0.7152,
                0.0722
            );

            float luminance =
                dot(sourceColor.rgb, luminanceWeights);

            luminance = saturate(luminance);

            float glyphCount =
                max(round(_GlyphCount), 2.0);

            float glyphIndex = min(
                floor(luminance * glyphCount),
                glyphCount - 1.0
            );

            int debugView = (int)round(_DebugView);

            if (debugView == 1)
            {
                return float4(sourceColor.rgb, 1.0);
            }

            if (debugView == 2)
            {
                return float4(
                    luminance,
                    luminance,
                    luminance,
                    1.0
                );
            }

            if (debugView == 3)
            {
                float normalizedGlyphIndex =
                    glyphIndex / (glyphCount - 1.0);

                return float4(
                    normalizedGlyphIndex,
                    normalizedGlyphIndex,
                    normalizedGlyphIndex,
                    1.0
                );
            }

            float2 cellUV =
                frac(pixelPosition / cellSize);

            float2 glyphUV = float2(
                (glyphIndex + cellUV.x) / glyphCount,
                cellUV.y
            );

            float glyphMask =
                SAMPLE_TEXTURE2D_LOD(
                    _GlyphAtlas,
                    sampler_GlyphAtlas,
                    glyphUV,
                    0
                ).r;

            int colorMode =
                (int)round(_ColorMode);

            float3 foregroundColor =
                float3(1.0, 1.0, 1.0);

            float3 backgroundColor =
                float3(0.0, 0.0, 0.0);

            if (colorMode == 1)
            {
                foregroundColor = _GlyphColor.rgb;
                backgroundColor = _BackgroundColor.rgb;
            }
            else if (colorMode == 2)
            {
                foregroundColor =
                    GetCellTint(sourceColor.rgb);
            }

            float3 outputColor = lerp(
                backgroundColor,
                foregroundColor,
                glyphMask
            );

            return float4(outputColor, 1.0);
        }

        float LoadLuminanceClamped(
            int2 pixelPosition,
            int2 textureResolution
        )
        {
            int2 maximumPixel =
                textureResolution - int2(1, 1);

            int2 clampedPosition = clamp(
                pixelPosition,
                int2(0, 0),
                maximumPixel
            );

            return LOAD_TEXTURE2D_X(
                _BlitTexture,
                clampedPosition
            ).r;
        }

        float GetGaussianWeight(
            int sampleOffset,
            float sigma
        )
        {
            float offset =
                (float)sampleOffset;

            float safeSigma =
                max(sigma, 0.0001);

            float exponent =
                -(offset * offset)
                / (2.0 * safeSigma * safeSigma);

            return exp(exponent);
        }

        float2 CalculateGaussianPairHorizontal(
            int2 pixelPosition,
            int2 textureResolution
        )
        {
            int smallRadius = clamp(
                (int)round(_GaussianRadius),
                0,
                8
            );

            float gaussianScale = max(
                _GaussianScale,
                1.0
            );

            int largeRadius = smallRadius;

            float smallSigma = max(
                _GaussianSigma,
                0.0001
            );

            float largeSigma =
                smallSigma * gaussianScale;

            float2 weightedLuminance =
                float2(0.0, 0.0);

            float2 totalWeight =
                float2(0.0, 0.0);

            [loop]
            for (
                int sampleOffset = -largeRadius;
                sampleOffset <= largeRadius;
                ++sampleOffset
            )
            {
                float luminance = LoadLuminanceClamped(
                    pixelPosition
                        + int2(sampleOffset, 0),
                    textureResolution
                );

                if (abs(sampleOffset) <= smallRadius)
                {
                    float smallWeight =
                        GetGaussianWeight(
                            sampleOffset,
                            smallSigma
                        );

                    weightedLuminance.x +=
                        luminance * smallWeight;

                    totalWeight.x += smallWeight;
                }

                float largeWeight =
                    GetGaussianWeight(
                        sampleOffset,
                        largeSigma
                    );

                weightedLuminance.y +=
                    luminance * largeWeight;

                totalWeight.y += largeWeight;
            }

            return weightedLuminance / max(
                totalWeight,
                float2(0.0001, 0.0001)
            );
        }


        float2 LoadGaussianPairClamped(
            int2 pixelPosition,
            int2 textureResolution
        )
        {
            int2 maximumPixel =
                textureResolution - int2(1, 1);

            int2 clampedPosition = clamp(
                pixelPosition,
                int2(0, 0),
                maximumPixel
            );

            return LOAD_TEXTURE2D_X(
                _BlitTexture,
                clampedPosition
            ).rg;
        }

        float2 CalculateGaussianPairVertical(
            int2 pixelPosition,
            int2 textureResolution
        )
        {
            int smallRadius = clamp(
                (int)round(_GaussianRadius),
                0,
                8
            );

            float gaussianScale = max(
                _GaussianScale,
                1.0
            );

            int largeRadius = smallRadius;

            float smallSigma = max(
                _GaussianSigma,
                0.0001
            );

            float largeSigma =
                smallSigma * gaussianScale;

            float2 weightedLuminance =
                float2(0.0, 0.0);

            float2 totalWeight =
                float2(0.0, 0.0);

            [loop]
            for (
                int sampleOffset = -largeRadius;
                sampleOffset <= largeRadius;
                ++sampleOffset
            )
            {
                float2 luminancePair =
                    LoadGaussianPairClamped(
                        pixelPosition
                            + int2(0, sampleOffset),
                        textureResolution
                    );

                if (abs(sampleOffset) <= smallRadius)
                {
                    float smallWeight =
                        GetGaussianWeight(
                            sampleOffset,
                            smallSigma
                        );

                    weightedLuminance.x +=
                        luminancePair.x * smallWeight;

                    totalWeight.x += smallWeight;
                }

                float largeWeight =
                    GetGaussianWeight(
                        sampleOffset,
                        largeSigma
                    );

                weightedLuminance.y +=
                    luminancePair.y * largeWeight;

                totalWeight.y += largeWeight;
            }

            return weightedLuminance / max(
                totalWeight,
                float2(0.0001, 0.0001)
            );
        }

        float4 GaussianHorizontalFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            int2 pixelPosition =
                int2(input.positionCS.xy);

            int2 textureResolution = max(
                (int2)_BlitTexture_TexelSize.zw,
                int2(1, 1)
            );

            float2 gaussianPair =
                CalculateGaussianPairHorizontal(
                    pixelPosition,
                    textureResolution
                );

            return float4(
                gaussianPair,
                0.0,
                1.0
            );
        }


        float4 GaussianVerticalFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            int2 pixelPosition =
                int2(input.positionCS.xy);

            int2 textureResolution = max(
                (int2)_BlitTexture_TexelSize.zw,
                int2(1, 1)
            );

            float2 gaussianPair =
                CalculateGaussianPairVertical(
                    pixelPosition,
                    textureResolution
                );

            return float4(
                gaussianPair,
                0.0,
                1.0
            );
        }

        float4 DifferenceOfGaussiansFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            int2 sourcePixel =
                int2(input.positionCS.xy);

            float2 gaussianPair = LOAD_TEXTURE2D_X(
                _BlitTexture,
                sourcePixel
            ).rg;

            // Keep the true Gaussian difference separate from the
            // tau-biased response used to form the binary regions.
            // When tau is below 1, the biased response contains a
            // positive luminance term that obscures the signed DoG in
            // diagnostic views.
            float signedDog =
                gaussianPair.x
                - gaussianPair.y;

            float thresholdDog =
                gaussianPair.x
                - _DoGTau * gaussianPair.y;

            return float4(
                signedDog,
                thresholdDog,
                0.0,
                1.0
            );
        }

        float4 DifferenceOfGaussiansDebugFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            int2 sourcePixel =
                int2(input.positionCS.xy);

            float2 dogResponses = LOAD_TEXTURE2D_X(
                _BlitTexture,
                sourcePixel
            ).rg;

            float signedDog = dogResponses.x;
            float thresholdDog = dogResponses.y;

            float displayScale = max(
                _DoGDisplayScale,
                0.0
            );

            int debugView =
                (int)round(_DebugView);

            if (debugView == 9)
            {
                float threshold = max(
                    _DoGThreshold,
                    0.0
                );

                float accepted =
                    thresholdDog >= threshold ? 1.0 : 0.0;

                return float4(
                    accepted,
                    accepted,
                    accepted,
                    1.0
                );
            }

            if (debugView == 8)
            {
                float threshold = max(
                    _DoGThreshold,
                    0.0
                );

                float relativeResponse =
                    thresholdDog - threshold;

                float acceptedResponse = saturate(
                    max(relativeResponse, 0.0)
                        * displayScale
                );

                float rejectedResponse = saturate(
                    max(-relativeResponse, 0.0)
                        * displayScale
                );

                return float4(
                    acceptedResponse,
                    0.0,
                    rejectedResponse,
                    1.0
                );
            }

            float positiveResponse = saturate(
                max(signedDog, 0.0) * displayScale
            );

            float negativeResponse = saturate(
                max(-signedDog, 0.0) * displayScale
            );

            return float4(
                positiveResponse,
                0.0,
                negativeResponse,
                1.0
            );
        }


        float LoadBinaryDoGClamped(
            int2 pixelPosition,
            int2 textureResolution
        )
        {
            float2 gaussianPair =
                LoadGaussianPairClamped(
                    pixelPosition,
                    textureResolution
                );

            float dog =
                gaussianPair.x
                - _DoGTau * gaussianPair.y;

            float threshold = max(
                _DoGThreshold,
                0.0
            );

            return dog >= threshold ? 1.0 : 0.0;
        }


        float LoadEdgeSobelInputClamped(
            int2 pixelPosition,
            int2 textureResolution
        )
        {
            return LoadBinaryDoGClamped(
                pixelPosition,
                textureResolution
            );
        }

        float4 EdgeEvidenceFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            int2 pixelPosition =
                int2(input.positionCS.xy);

            int2 textureResolution = max(
                (int2)_BlitTexture_TexelSize.zw,
                int2(1, 1)
            );

            float l00 = LoadEdgeSobelInputClamped(
                pixelPosition + int2(-1, -1),
                textureResolution
            );

            float l10 = LoadEdgeSobelInputClamped(
                pixelPosition + int2(0, -1),
                textureResolution
            );

            float l20 = LoadEdgeSobelInputClamped(
                pixelPosition + int2(1, -1),
                textureResolution
            );

            float l01 = LoadEdgeSobelInputClamped(
                pixelPosition + int2(-1, 0),
                textureResolution
            );

            float l21 = LoadEdgeSobelInputClamped(
                pixelPosition + int2(1, 0),
                textureResolution
            );

            float l02 = LoadEdgeSobelInputClamped(
                pixelPosition + int2(-1, 1),
                textureResolution
            );

            float l12 = LoadEdgeSobelInputClamped(
                pixelPosition + int2(0, 1),
                textureResolution
            );

            float l22 = LoadEdgeSobelInputClamped(
                pixelPosition + int2(1, 1),
                textureResolution
            );

            float gradientX =
                (l20 + 2.0 * l21 + l22)
                - (l00 + 2.0 * l01 + l02);

            float gradientY =
                (l02 + 2.0 * l12 + l22)
                - (l00 + 2.0 * l10 + l20);

            float2 gradient =
                float2(gradientX, gradientY);

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


        float4 CellEdgeAggregationFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            uint2 cellSize =
                (uint2)GetCellSize();

            uint2 sourceResolution =
                (uint2)_BlitTexture_TexelSize.zw;

            uint2 cellIndex =
                (uint2)input.positionCS.xy;

            uint2 sourceStart =
                cellIndex * cellSize;

            uint2 sourceEnd = min(
                sourceStart + cellSize,
                sourceResolution
            );

            float4 directionCounts = float4(
                0.0,
                0.0,
                0.0,
                0.0
            );

            const float inverseSquareRootTwo =
                0.70710678118;

            [loop]
            for (
                uint sourceY = sourceStart.y;
                sourceY < sourceEnd.y;
                ++sourceY
            )
            {
                [loop]
                for (
                    uint sourceX = sourceStart.x;
                    sourceX < sourceEnd.x;
                    ++sourceX
                )
                {
                    float4 evidence = LOAD_TEXTURE2D_X(
                        _BlitTexture,
                        int2(sourceX, sourceY)
                    );

                    float2 gradient = evidence.rg;
                    float magnitude = length(gradient);

                    if (
                        evidence.b > 0.5
                        && magnitude > 0.00001
                    )
                    {
                        float2 lineDirection =
                            float2(
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
            }

            return directionCounts;
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
            CellEdgeDirectionSummary direction;
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
                summary.runnerUpCount =
                    summary.dominantCount;

                summary.dominantDirection = 1;
                summary.dominantCount =
                    directionCounts.y;
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
                summary.runnerUpCount =
                    summary.dominantCount;

                summary.dominantDirection = 2;
                summary.dominantCount =
                    directionCounts.z;
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
                summary.runnerUpCount =
                    summary.dominantCount;

                summary.dominantDirection = 3;
                summary.dominantCount =
                    directionCounts.w;
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
            float sampleCount,
            float fullCellSampleCount
        )
        {
            CellEdgeClassification classification;

            classification.direction =
                SummarizeCellEdgeDirections(
                    directionCounts
                );

            float safeSampleCount = max(
                sampleCount,
                1.0
            );

            float safeFullCellSampleCount = max(
                fullCellSampleCount,
                1.0
            );

            float minimumDominantPixels = max(
                _CellEdgeMinimumDominantPixels,
                0.0
            );

            classification.effectiveMinimumSupport =
                minimumDominantPixels
                * safeSampleCount
                / safeFullCellSampleCount;

            classification.dominance =
                classification.direction.totalCount
                    > 0.00001
                    ? saturate(
                        classification.direction.dominantCount
                            / classification.direction.totalCount
                    )
                    : 0.0;

            float minimumDominance = saturate(
                _CellEdgeMinimumDominance
            );

            bool hasEvidence =
                classification.direction.totalCount
                    > 0.00001;

            bool hasSupport =
                classification.direction.dominantCount
                    >= classification.effectiveMinimumSupport;

            bool hasDominance =
                classification.dominance
                    >= minimumDominance;

            bool hasUniqueDirection =
                classification.direction.dominantCount
                    > classification.direction.runnerUpCount;

            classification.isCandidate =
                hasEvidence
                && hasSupport
                && hasDominance
                && hasUniqueDirection
                    ? 1.0
                    : 0.0;

            return classification;
        }


        float3 GetCellEdgeDirectionDebugColor(
            int direction
        )
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


        int GetEdgeGlyphIndex(
            CellEdgeClassification classification
        )
        {
            if (classification.isCandidate <= 0.5)
            {
                return 0;
            }

            int dominantDirection =
                classification.direction.dominantDirection;

            if (dominantDirection == 0)
            {
                return 2;
            }

            if (dominantDirection == 1)
            {
                return 3;
            }

            if (dominantDirection == 2)
            {
                return 1;
            }

            return 4;
        }


        float4 CellEdgeDebugFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            uint2 cellSize =
                (uint2)GetCellSize();

            uint2 cellTextureResolution = max(
                (uint2)_BlitTexture_TexelSize.zw,
                uint2(1, 1)
            );

            uint2 outputPixel =
                (uint2)input.positionCS.xy;

            uint2 cellIndex = min(
                outputPixel / cellSize,
                cellTextureResolution - 1
            );

            float4 directionCounts = LOAD_TEXTURE2D_X(
                _BlitTexture,
                int2(cellIndex)
            );

            int debugView =
                (int)round(_DebugView);

            uint2 edgeSourceResolution = max(
                (uint2)_ScreenParams.xy,
                uint2(1, 1)
            );

            uint2 sourceStart =
                cellIndex * cellSize;

            uint2 sourceEnd = min(
                sourceStart + cellSize,
                edgeSourceResolution
            );

            uint2 sampleExtent =
                sourceEnd - sourceStart;

            float sampleCount = max(
                (float)(sampleExtent.x * sampleExtent.y),
                1.0
            );

            float fullCellSampleCount = max(
                (float)(cellSize.x * cellSize.y),
                1.0
            );

            CellEdgeClassification classification =
                ClassifyCellEdge(
                    directionCounts,
                    sampleCount,
                    fullCellSampleCount
                );

            CellEdgeDirectionSummary summary =
                classification.direction;

            if (debugView == 13)
            {
                float acceptedProportion = saturate(
                    summary.totalCount / sampleCount
                );

                return float4(
                    acceptedProportion,
                    acceptedProportion,
                    acceptedProportion,
                    1.0
                );
            }

            if (debugView == 14)
            {
                float displayedSupport =
                    classification.effectiveMinimumSupport
                        > 0.00001
                        ? saturate(
                            summary.dominantCount
                                / classification.effectiveMinimumSupport
                        )
                        : summary.dominantCount > 0.0
                            ? 1.0
                            : 0.0;

                return float4(
                    displayedSupport,
                    displayedSupport,
                    displayedSupport,
                    1.0
                );
            }

            if (debugView == 15)
            {
                return float4(
                    classification.dominance,
                    classification.dominance,
                    classification.dominance,
                    1.0
                );
            }

            if (debugView == 16)
            {
                float3 directionColor =
                    summary.totalCount > 0.00001
                        ? GetCellEdgeDirectionDebugColor(
                            summary.dominantDirection
                        )
                        : float3(0.0, 0.0, 0.0);

                return float4(
                    directionColor,
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


        float4 EdgeOnlyAsciiFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            uint2 cellSize =
                (uint2)GetCellSize();

            uint2 cellTextureResolution = max(
                (uint2)_BlitTexture_TexelSize.zw,
                uint2(1, 1)
            );

            float2 pixelPosition =
                input.positionCS.xy;

            uint2 cellIndex = min(
                (uint2)(
                    pixelPosition / (float2)cellSize
                ),
                cellTextureResolution - 1
            );

            float4 directionCounts = LOAD_TEXTURE2D_X(
                _BlitTexture,
                int2(cellIndex)
            );

            uint2 edgeSourceResolution = max(
                (uint2)_ScreenParams.xy,
                uint2(1, 1)
            );

            uint2 sourceStart =
                cellIndex * cellSize;

            uint2 sourceEnd = min(
                sourceStart + cellSize,
                edgeSourceResolution
            );

            uint2 sampleExtent =
                sourceEnd - sourceStart;

            float sampleCount = max(
                (float)(sampleExtent.x * sampleExtent.y),
                1.0
            );

            float fullCellSampleCount = max(
                (float)(cellSize.x * cellSize.y),
                1.0
            );

            CellEdgeClassification classification =
                ClassifyCellEdge(
                    directionCounts,
                    sampleCount,
                    fullCellSampleCount
                );

            int edgeGlyphIndex = GetEdgeGlyphIndex(
                classification
            );

            float2 cellUV = frac(
                pixelPosition / (float2)cellSize
            );

            const float edgeGlyphCount = 5.0;

            float2 glyphUV = float2(
                (
                    (float)edgeGlyphIndex
                    + cellUV.x
                ) / edgeGlyphCount,
                cellUV.y
            );

            float glyphMask = SAMPLE_TEXTURE2D_LOD(
                _EdgeGlyphAtlas,
                sampler_EdgeGlyphAtlas,
                glyphUV,
                0
            ).r;

            float3 foregroundColor =
                float3(1.0, 1.0, 1.0);

            float3 backgroundColor =
                float3(0.0, 0.0, 0.0);

            int colorMode =
                (int)round(_ColorMode);

            if (colorMode == 1)
            {
                foregroundColor = _GlyphColor.rgb;
                backgroundColor = _BackgroundColor.rgb;
            }

            float3 outputColor = lerp(
                backgroundColor,
                foregroundColor,
                glyphMask
            );

            return float4(outputColor, 1.0);
        }


        float4 CompositeAsciiRendererFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float2 cellSize = GetCellSize();

            float2 pixelPosition =
                input.positionCS.xy;

            uint2 cellIndex =
                (uint2)(pixelPosition / cellSize);

            float4 sourceColor = LOAD_TEXTURE2D_X(
                _BlitTexture,
                int2(cellIndex)
            );

            float4 directionCounts = LOAD_TEXTURE2D_X(
                _AsciiCellEdgeDirectionalHistogram,
                int2(cellIndex)
            );

            uint2 edgeSourceResolution = max(
                (uint2)_ScreenParams.xy,
                uint2(1, 1)
            );

            uint2 sourceStart =
                cellIndex * (uint2)cellSize;

            uint2 sourceEnd = min(
                sourceStart + (uint2)cellSize,
                edgeSourceResolution
            );

            uint2 sampleExtent =
                sourceEnd - sourceStart;

            float sampleCount = max(
                (float)(sampleExtent.x * sampleExtent.y),
                1.0
            );

            float fullCellSampleCount = max(
                cellSize.x * cellSize.y,
                1.0
            );

            CellEdgeClassification classification =
                ClassifyCellEdge(
                    directionCounts,
                    sampleCount,
                    fullCellSampleCount
                );

            const float3 luminanceWeights = float3(
                0.2126,
                0.7152,
                0.0722
            );

            float luminance = saturate(
                dot(sourceColor.rgb, luminanceWeights)
            );

            float glyphCount = max(
                round(_GlyphCount),
                2.0
            );

            float luminanceGlyphIndex = min(
                floor(luminance * glyphCount),
                glyphCount - 1.0
            );

            float2 cellUV = frac(
                pixelPosition / cellSize
            );

            float luminanceGlyphMask = SAMPLE_TEXTURE2D_LOD(
                _GlyphAtlas,
                sampler_GlyphAtlas,
                float2(
                    (
                        luminanceGlyphIndex
                        + cellUV.x
                    ) / glyphCount,
                    cellUV.y
                ),
                0
            ).r;

            int edgeGlyphIndex = GetEdgeGlyphIndex(
                classification
            );

            const float edgeGlyphCount = 5.0;

            float edgeGlyphMask = SAMPLE_TEXTURE2D_LOD(
                _EdgeGlyphAtlas,
                sampler_EdgeGlyphAtlas,
                float2(
                    (
                        (float)edgeGlyphIndex
                        + cellUV.x
                    ) / edgeGlyphCount,
                    cellUV.y
                ),
                0
            ).r;

            float glyphMask =
                classification.isCandidate > 0.5
                    ? edgeGlyphMask
                    : luminanceGlyphMask;

            int colorMode =
                (int)round(_ColorMode);

            float3 foregroundColor =
                float3(1.0, 1.0, 1.0);

            float3 backgroundColor =
                float3(0.0, 0.0, 0.0);

            if (colorMode == 1)
            {
                foregroundColor = _GlyphColor.rgb;
                backgroundColor = _BackgroundColor.rgb;
            }
            else if (colorMode == 2)
            {
                foregroundColor = GetCellTint(
                    sourceColor.rgb
                );
            }

            float3 outputColor = lerp(
                backgroundColor,
                foregroundColor,
                glyphMask
            );

            return float4(outputColor, 1.0);
        }

        float4 EdgeEvidenceDebugFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            int2 sourcePixel =
                int2(input.positionCS.xy);

            float4 evidence = LOAD_TEXTURE2D_X(
                _BlitTexture,
                sourcePixel
            );

            float2 gradient =
                evidence.rg;

            float magnitude =
                length(gradient);

            float displayScale = max(
                _SobelMagnitudeDisplayScale,
                0.0
            );

            float visibility = saturate(
                magnitude * displayScale
            );

            if (magnitude <= 0.00001)
            {
                return float4(
                    0.0,
                    0.0,
                    0.0,
                    1.0
                );
            }

            float2 direction =
                gradient / magnitude;

            float2 encodedDirection =
                direction * 0.5 + 0.5;

            float3 directionColor = float3(
                encodedDirection,
                0.5
            );

            return float4(
                directionColor * visibility,
                1.0
            );
        }

        float4 LargeGaussianLuminanceDebugFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            int2 sourcePixel =
                int2(input.positionCS.xy);

            float luminance = LOAD_TEXTURE2D_X(
                _BlitTexture,
                sourcePixel
            ).g;

            luminance = saturate(luminance);

            return float4(
                luminance,
                luminance,
                luminance,
                1.0
            );
        }

        float4 FullResolutionSobelFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            int2 pixelPosition =
                int2(input.positionCS.xy);

            int2 textureResolution = max(
                (int2)_BlitTexture_TexelSize.zw,
                int2(1, 1)
            );

            float l00 = LoadLuminanceClamped(
                pixelPosition + int2(-1, -1),
                textureResolution
            );

            float l10 = LoadLuminanceClamped(
                pixelPosition + int2(0, -1),
                textureResolution
            );

            float l20 = LoadLuminanceClamped(
                pixelPosition + int2(1, -1),
                textureResolution
            );

            float l01 = LoadLuminanceClamped(
                pixelPosition + int2(-1, 0),
                textureResolution
            );

            float l21 = LoadLuminanceClamped(
                pixelPosition + int2(1, 0),
                textureResolution
            );

            float l02 = LoadLuminanceClamped(
                pixelPosition + int2(-1, 1),
                textureResolution
            );

            float l12 = LoadLuminanceClamped(
                pixelPosition + int2(0, 1),
                textureResolution
            );

            float l22 = LoadLuminanceClamped(
                pixelPosition + int2(1, 1),
                textureResolution
            );

            float gradientX =
                (l20 + 2.0 * l21 + l22)
                - (l00 + 2.0 * l01 + l02);

            float gradientY =
                (l02 + 2.0 * l12 + l22)
                - (l00 + 2.0 * l10 + l20);

            return float4(
                gradientX,
                gradientY,
                0.0,
                1.0
            );
        }
        float4 FullResolutionSobelDebugFragment(
            Varyings input
        ) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            int2 sourcePixel =
                int2(input.positionCS.xy);

            float2 gradient = LOAD_TEXTURE2D_X(
                _BlitTexture,
                sourcePixel
            ).rg;

            float magnitude =
                length(gradient);

            float displayScale = max(
                _SobelMagnitudeDisplayScale,
                0.0
            );

            int debugView =
                (int)round(_DebugView);

            if (debugView == 10)
            {
                float displayedMagnitude = saturate(
                    magnitude * displayScale
                );

                return float4(
                    displayedMagnitude,
                    displayedMagnitude,
                    displayedMagnitude,
                    1.0
                );
            }

            if (magnitude <= 0.00001)
            {
                return float4(
                    0.0,
                    0.0,
                    0.0,
                    1.0
                );
            }

            float2 direction =
                gradient / magnitude;

            float2 encodedDirection =
                direction * 0.5 + 0.5;

            float visibility = saturate(
                magnitude * displayScale
            );

            float3 directionColor = float3(
                encodedDirection,
                0.5
            );

            return float4(
                directionColor * visibility,
                1.0
            );
        }

        ENDHLSL


        Pass
        {
            Name "Full-Resolution Luminance"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment FullResolutionLuminanceFragment

            ENDHLSL
        }

        Pass
        {
            Name "Full-Resolution Sobel"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment FullResolutionSobelFragment

            ENDHLSL
        }

        Pass
        {
            Name "Cell Analysis"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment CellAnalysisFragment

            ENDHLSL
        }


        Pass
        {
            Name "ASCII Renderer"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment AsciiRendererFragment

            ENDHLSL
        }


        Pass
        {
            Name "Full-Resolution Luminance Debug"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment FullResolutionLuminanceDebugFragment

            ENDHLSL
        }

        Pass
        {
            Name "Full-Resolution Sobel Debug"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment FullResolutionSobelDebugFragment

            ENDHLSL
        }

        Pass
        {
            Name "Gaussian Horizontal"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment GaussianHorizontalFragment

            ENDHLSL
        }


        Pass
        {
            Name "Gaussian Vertical"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment GaussianVerticalFragment

            ENDHLSL
        }

        Pass
        {
            Name "Difference of Gaussians"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment DifferenceOfGaussiansFragment

            ENDHLSL
        }


        Pass
        {
            Name "Difference of Gaussians Debug"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment DifferenceOfGaussiansDebugFragment

            ENDHLSL
        }


        Pass
        {
            Name "Large Gaussian Luminance Debug"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment LargeGaussianLuminanceDebugFragment

            ENDHLSL
        }

        Pass
        {
            Name "Prepare Edge Evidence"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment EdgeEvidenceFragment

            ENDHLSL
        }


        Pass
        {
            Name "Debug Edge Evidence"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment EdgeEvidenceDebugFragment

            ENDHLSL
        }


        Pass
        {
            Name "Aggregate Cell Edge Evidence"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment CellEdgeAggregationFragment

            ENDHLSL
        }


        Pass
        {
            Name "Debug Cell Edge Measurements"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment CellEdgeDebugFragment

            ENDHLSL
        }


        Pass
        {
            Name "Render Edge-Only ASCII"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment EdgeOnlyAsciiFragment

            ENDHLSL
        }


        Pass
        {
            Name "Render Composite ASCII"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment CompositeAsciiRendererFragment

            ENDHLSL
        }
    }

    FallBack Off
}
