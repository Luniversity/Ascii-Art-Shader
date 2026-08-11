Shader "ASCII Shader/Renderer"
{
    Properties
    {
        _CellWidth ("Cell Width (pixels)", Range(1, 64)) = 8
        _CellHeight ("Cell Height (pixels)", Range(1, 64)) = 8
        _GlyphCount ("Glyph Count", Range(2, 16)) = 10
        _GlyphAtlas ("Glyph Atlas", 2D) = "black" {}
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

        CBUFFER_START(UnityPerMaterial)
            float _CellWidth;
            float _CellHeight;
            float _GlyphCount;
        CBUFFER_END


        float2 GetCellSize()
        {
            return max(
                round(float2(_CellWidth, _CellHeight)),
                float2(1.0, 1.0)
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

            return float4(
                glyphMask,
                glyphMask,
                glyphMask,
                1.0
            );
        }

        ENDHLSL


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
    }

    FallBack Off
}
