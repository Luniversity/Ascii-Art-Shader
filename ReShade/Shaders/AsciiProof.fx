#include "ReShade.fxh"

uniform float TintStrength <
    ui_label = "Tint Strength";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.5;

static const float3 ProofTint =
    float3(1.0, 0.25, 0.10);

float4 TintPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    float4 sourceColor =
        tex2D(ReShade::BackBuffer, texcoord);

    sourceColor.rgb = lerp(
        sourceColor.rgb,
        sourceColor.rgb * ProofTint,
        TintStrength
    );

    return sourceColor;
}

technique AsciiProof
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = TintPS;
    }
}