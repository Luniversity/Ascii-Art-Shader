Shader "ASCII Shader/Pass Through"
{
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

            float4 PassThroughFragment(Varyings input) : SV_Target
            {
                return FragBlit(input, sampler_LinearClamp);
            }

            ENDHLSL
        }
    }

    FallBack Off
}