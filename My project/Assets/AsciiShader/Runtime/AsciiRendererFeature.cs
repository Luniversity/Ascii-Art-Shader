using System;

using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Experimental.Rendering;

public sealed class AsciiRendererFeature
    : ScriptableRendererFeature
{
    [Serializable]
    public sealed class Settings
    {
        public RenderPassEvent injectionPoint =
            RenderPassEvent.AfterRenderingPostProcessing;

        public Material material;
    }

    [SerializeField]
    private Settings settings = new Settings();

    private AsciiRenderPass renderPass;


    public override void Create()
    {
        renderPass = new AsciiRenderPass
        {
            renderPassEvent = settings.injectionPoint,
            requiresIntermediateTexture = true,
        };
    }


    public override void AddRenderPasses(
        ScriptableRenderer renderer,
        ref RenderingData renderingData
    )
    {
        if (settings.material == null)
        {
            return;
        }

        CameraType cameraType =
            renderingData.cameraData.cameraType;

        if (
            cameraType == CameraType.Preview
            || cameraType == CameraType.Reflection
        )
        {
            return;
        }

        renderPass.renderPassEvent = settings.injectionPoint;
        renderPass.Setup(settings.material);

        renderer.EnqueuePass(renderPass);
    }


    private sealed class AsciiRenderPass
        : ScriptableRenderPass
    {
        private const int CellAnalysisPassIndex = 0;
        private const int AsciiRendererPassIndex = 1;

        private static readonly int CellWidthId =
            Shader.PropertyToID("_CellWidth");

        private static readonly int CellHeightId =
            Shader.PropertyToID("_CellHeight");

        private Material material;


        public void Setup(Material passMaterial)
        {
            material = passMaterial;
        }


        public override void RecordRenderGraph(
            RenderGraph renderGraph,
            ContextContainer frameData
        )
        {
            UniversalResourceData resourceData =
            frameData.Get<UniversalResourceData>();

            TextureHandle source = resourceData.cameraColor;
            TextureHandle destination =
                resourceData.activeColorTexture;

            if (!source.IsValid() || !destination.IsValid())
            {
                return;
            }
            TextureDesc sourceDescriptor =
                renderGraph.GetTextureDesc(source);

            UniversalCameraData cameraData =
                frameData.Get<UniversalCameraData>();

            int sourceWidth = sourceDescriptor.width > 0
                ? sourceDescriptor.width
                : cameraData.cameraTargetDescriptor.width;

            int sourceHeight = sourceDescriptor.height > 0
                ? sourceDescriptor.height
                : cameraData.cameraTargetDescriptor.height;

            int cellWidth = Mathf.Max(
                Mathf.RoundToInt(material.GetFloat(CellWidthId)),
                1
            );

            int cellHeight = Mathf.Max(
                Mathf.RoundToInt(material.GetFloat(CellHeightId)),
                1
            );

            int cellTextureWidth =
                (sourceWidth + cellWidth - 1) / cellWidth;

            int cellTextureHeight =
                (sourceHeight + cellHeight - 1) / cellHeight;

            TextureDesc cellDescriptor =
                new TextureDesc(sourceDescriptor)
                {
                    name = "_AsciiCellTexture",

                    sizeMode = TextureSizeMode.Explicit,
                    width = cellTextureWidth,
                    height = cellTextureHeight,

                    format =
                        GraphicsFormat.R16G16B16A16_SFloat,

                    filterMode = FilterMode.Point,
                    wrapMode = TextureWrapMode.Clamp,

                    msaaSamples = MSAASamples.None,
                    bindTextureMS = false,

                    useMipMap = false,
                    autoGenerateMips = false,
                    enableRandomWrite = false,

                    useDynamicScale = false,
                    useDynamicScaleExplicit = false,

                    clearBuffer = false,
                    discardBuffer = false,
                };

            TextureHandle cellTexture =
                renderGraph.CreateTexture(cellDescriptor);

            if (!cellTexture.IsValid())
            {
                return;
            }
            var analysisParameters =
                new RenderGraphUtils.BlitMaterialParameters(
                    source,
                    cellTexture,
                    material,
                    CellAnalysisPassIndex
                );

            renderGraph.AddBlitPass(
                analysisParameters,
                "Analyze ASCII Cells"
            );

            var blitParameters =
                new RenderGraphUtils.BlitMaterialParameters(
                    cellTexture,
                    destination,
                    material,
                    AsciiRendererPassIndex
                );

            renderGraph.AddBlitPass(
                blitParameters,
                "Render ASCII"
            );
        }
    }
}