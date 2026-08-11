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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            TEXTURE2D(_GlyphAtlas);
            SAMPLER(sampler_GlyphAtlas);

            CBUFFER_START(UnityPerMaterial)
                float _CellWidth;
                float _CellHeight;
                float _GlyphCount;
            CBUFFER_END

            float4 AsciiRendererFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 cellSize = max(
                    round(float2(_CellWidth, _CellHeight)),
                    float2(1.0, 1.0)
                );

                float2 textureResolution = _BlitTexture_TexelSize.zw;
                float2 pixelPosition = input.texcoord * textureResolution;
                float2 cellIndex = floor(pixelPosition / cellSize);

                float2 cellCenterPixel = (cellIndex + 0.5) * cellSize;
                float2 cellCenterUV = cellCenterPixel / textureResolution;

                float4 sourceColor = SAMPLE_TEXTURE2D_X_LOD(
                    _BlitTexture,
                    sampler_PointClamp,
                    cellCenterUV,
                    0
                );

                const float3 luminanceWeights = float3(
                    0.2126,
                    0.7152,
                    0.0722
                );

                float luminance = dot(sourceColor.rgb, luminanceWeights);
                luminance = saturate(luminance);

                float glyphCount = max(round(_GlyphCount), 2.0);

                float glyphIndex = min(
                    floor(luminance * glyphCount),
                    glyphCount - 1.0
                );

                float2 cellUV = frac(pixelPosition / cellSize);

                float2 glyphUV = float2(
                    (glyphIndex + cellUV.x) / glyphCount,
                    cellUV.y
                );

                float glyphMask = SAMPLE_TEXTURE2D_LOD(
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
        }
    }

    FallBack Off
}
