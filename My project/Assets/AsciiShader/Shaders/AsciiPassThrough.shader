Shader "ASCII Shader/Pass Through"
{
    Properties
    {
        _CellSize ("Cell Size (pixels)", Range(1, 64)) = 16
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "Pass Through"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM

            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment PassThroughFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            CBUFFER_START(UnityPerMaterial)
                float _CellSize;
            CBUFFER_END

            float4 PassThroughFragment(Varyings input) : SV_Target
            {
                float cellSize = max(_CellSize, 1.0);

                float2 textureResolution = _BlitTexture_TexelSize.zw;
                float2 pixelPosition = input.texcoord * textureResolution;
                float2 cellIndex = floor(pixelPosition / cellSize);

                float checker = fmod(cellIndex.x + cellIndex.y, 2.0);

                float3 darkColor = float3(0.05, 0.07, 0.12);
                float3 lightColor = float3(0.85, 0.90, 1.00);
                float3 debugColor = lerp(darkColor, lightColor, checker);

                return float4(debugColor, 1.0);
            }

            ENDHLSL
        }
    }

    FallBack Off
}