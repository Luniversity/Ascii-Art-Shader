using System;

using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Experimental.Rendering;

public enum AsciiDebugView
{
    Final = 0,
    CellColor = 1,
    Luminance = 2,
    GlyphIndex = 3,
    FullResLuminance = 4,
    SmallGaussianLuminance = 5,
    LargeGaussianLuminance = 6,
    SignedDoG = 7,
    TauAdjustedDoGResponse = 8,
    BinaryDoG = 9,
    ReferenceSobelMagnitude = 10,
    ReferenceSobelDirection = 11,
    EdgeSobelDirection = 12,
    CellEdgePixelCount = 13,
    CellEdgeDominantSupport = 14,
    CellEdgeDominance = 15,
    CellEdgeDominantDirection = 16,
    CellEdgeCandidateMask = 17,
    EdgeOnly = 18,
    RemappedCellLuminance = 19,
    LuminanceRangeClipping = 20,
}


public enum AsciiEdgeInput
{
    RawLuminance = 0,
    GaussianLuminance = 1,
}


public enum AsciiBenchmarkRenderMode
{
    MaterialSettings = 0,
    Disabled = 1,
    LuminanceOnly = 2,
    EdgeAware = 3,
}


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

    [NonSerialized]
    private AsciiBenchmarkRenderMode benchmarkRenderMode =
        AsciiBenchmarkRenderMode.MaterialSettings;

    [NonSerialized]
    private bool hostRenderingDisabled;


    internal Material BenchmarkMaterial => settings.material;

    public bool HasReportedLuminanceBounds =>
        renderPass != null
        && renderPass.HasReportedLuminanceBounds;

    public Vector2 ReportedLuminanceBounds =>
        renderPass != null
            ? renderPass.ReportedLuminanceBounds
            : Vector2.zero;

    public uint LuminanceBoundsReportVersion =>
        renderPass != null
            ? renderPass.LuminanceBoundsReportVersion
            : 0u;


    public void RequestLuminanceBoundsReport()
    {
        renderPass?.RequestLuminanceBoundsReport();
    }


    internal void SetBenchmarkRenderMode(
        AsciiBenchmarkRenderMode mode
    )
    {
        benchmarkRenderMode = mode;
    }


    internal void ClearBenchmarkRenderMode()
    {
        benchmarkRenderMode =
            AsciiBenchmarkRenderMode.MaterialSettings;
    }


    internal void SetHostRenderingDisabled(bool disabled)
    {
        hostRenderingDisabled = disabled;
    }


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

        AsciiBenchmarkRenderMode effectiveRenderMode =
            benchmarkRenderMode
            != AsciiBenchmarkRenderMode.MaterialSettings
                ? benchmarkRenderMode
                : hostRenderingDisabled
                    ? AsciiBenchmarkRenderMode.Disabled
                    : AsciiBenchmarkRenderMode.MaterialSettings;

        if (effectiveRenderMode == AsciiBenchmarkRenderMode.Disabled)
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
        renderPass.Setup(
            settings.material,
            effectiveRenderMode
        );

        renderer.EnqueuePass(renderPass);
    }


    private sealed class AsciiRenderPass
        : ScriptableRenderPass
    {
        private const int FullResolutionLuminancePassIndex = 0;
        private const int FullResolutionSobelPassIndex = 1;
        private const int CellAnalysisPassIndex = 2;
        private const int AsciiRendererPassIndex = 3;
        private const int FullResolutionLuminanceDebugPassIndex = 4;

        private const int FullResolutionSobelDebugPassIndex = 5;

        private const int GaussianHorizontalPassIndex = 6;
        private const int GaussianVerticalPassIndex = 7;
        private const int DifferenceOfGaussiansPassIndex = 8;
        private const int DifferenceOfGaussiansDebugPassIndex = 9;
        private const int LargeGaussianLuminanceDebugPassIndex = 10;
        private const int EdgeEvidencePassIndex = 11;
        private const int EdgeEvidenceDebugPassIndex = 12;
        private const int CellEdgeAggregationPassIndex = 13;
        private const int CellEdgeDebugPassIndex = 14;
        private const int EdgeOnlyAsciiPassIndex = 15;
        private const int CompositeAsciiRendererPassIndex = 16;
        private const int CellLuminanceBoundsSeedPassIndex = 17;
        private const int CellLuminanceBoundsReducePassIndex = 18;
        private const int FullResolutionLuminanceDebugView =
            (int)AsciiDebugView.FullResLuminance;
        private const int GaussianLuminanceDebugView =
            (int)AsciiDebugView.SmallGaussianLuminance;
        private const int LargeGaussianLuminanceDebugView =
            (int)AsciiDebugView.LargeGaussianLuminance;
        private const int SignedDoGDebugView =
            (int)AsciiDebugView.SignedDoG;
        private const int TauAdjustedDoGResponseDebugView =
            (int)AsciiDebugView.TauAdjustedDoGResponse;
        private const int BinaryDoGDebugView =
            (int)AsciiDebugView.BinaryDoG;
        private const int ReferenceSobelMagnitudeDebugView =
            (int)AsciiDebugView.ReferenceSobelMagnitude;
        private const int ReferenceSobelDirectionDebugView =
            (int)AsciiDebugView.ReferenceSobelDirection;
        private const int EdgeSobelDirectionDebugView =
            (int)AsciiDebugView.EdgeSobelDirection;
        private const int CellEdgePixelCountDebugView =
            (int)AsciiDebugView.CellEdgePixelCount;
        private const int CellEdgeDominantSupportDebugView =
            (int)AsciiDebugView.CellEdgeDominantSupport;
        private const int CellEdgeDominanceDebugView =
            (int)AsciiDebugView.CellEdgeDominance;
        private const int CellEdgeDominantDirectionDebugView =
            (int)AsciiDebugView.CellEdgeDominantDirection;
        private const int CellEdgeCandidateMaskDebugView =
            (int)AsciiDebugView.CellEdgeCandidateMask;
        private const int EdgeOnlyDebugView =
            (int)AsciiDebugView.EdgeOnly;

        private static readonly int CellWidthId =
            Shader.PropertyToID("_CellWidth");

        private static readonly int CellHeightId =
            Shader.PropertyToID("_CellHeight");

        private static readonly int DebugViewId =
            Shader.PropertyToID("_DebugView");

        private static readonly int EdgeInputId =
            Shader.PropertyToID("_EdgeInput");

        private static readonly int EnableEdgeGlyphsId =
            Shader.PropertyToID("_EnableEdgeGlyphs");

        private static readonly int LuminanceMappingModeId =
            Shader.PropertyToID(
                "_LuminanceMappingMode"
            );

        private static readonly int UseManualLuminanceBoundsId =
            Shader.PropertyToID(
                "_UseManualLuminanceBounds"
            );

        private static readonly int LuminanceBoundsTextureId =
            Shader.PropertyToID("_AsciiLuminanceBounds");

        private static readonly int CellEdgeHistogramTextureId =
            Shader.PropertyToID(
                "_AsciiCellEdgeDirectionalHistogram"
            );

        private Material material;
        private AsciiBenchmarkRenderMode benchmarkRenderMode;

        private bool luminanceBoundsReadbackRequested;
        private bool luminanceBoundsReadbackInFlight;
        private bool hasReportedLuminanceBounds;
        private Vector2 reportedLuminanceBounds;
        private uint luminanceBoundsReportVersion;


        private sealed class CellEdgeAggregationPassData
        {
            public TextureHandle edgeEvidence;
            public Material material;
        }


        private sealed class CompositeAsciiPassData
        {
            public TextureHandle cellTexture;
            public TextureHandle edgeHistogram;
            public TextureHandle luminanceBounds;
            public bool usesAutomaticLuminanceBounds;
            public Material material;
        }


        private sealed class LuminanceAsciiPassData
        {
            public TextureHandle cellTexture;
            public TextureHandle luminanceBounds;
            public Material material;
        }


        private sealed class LuminanceBoundsReadbackPassData
        {
            public TextureHandle luminanceBounds;
            public AsciiRenderPass owner;
        }


        public bool HasReportedLuminanceBounds =>
            hasReportedLuminanceBounds;

        public Vector2 ReportedLuminanceBounds =>
            reportedLuminanceBounds;

        public uint LuminanceBoundsReportVersion =>
            luminanceBoundsReportVersion;


        public void RequestLuminanceBoundsReport()
        {
            if (!luminanceBoundsReadbackInFlight)
            {
                luminanceBoundsReadbackRequested = true;
            }
        }


        private void CompleteLuminanceBoundsReadback(
            AsyncGPUReadbackRequest request
        )
        {
            luminanceBoundsReadbackInFlight = false;

            if (request.hasError)
            {
                Debug.LogWarning(
                    "ASCII luminance-bounds readback failed."
                );
                return;
            }

            var values = request.GetData<float>();

            if (values.Length < 2)
            {
                Debug.LogWarning(
                    "ASCII luminance-bounds readback returned no data."
                );
                return;
            }

            reportedLuminanceBounds = new Vector2(
                Mathf.Clamp01(values[0]),
                Mathf.Clamp01(values[1])
            );

            hasReportedLuminanceBounds = true;
            ++luminanceBoundsReportVersion;
        }


        public void Setup(
            Material passMaterial,
            AsciiBenchmarkRenderMode passBenchmarkRenderMode
        )
        {
            material = passMaterial;
            benchmarkRenderMode = passBenchmarkRenderMode;
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

            bool forcesLuminanceOnly =
                benchmarkRenderMode
                == AsciiBenchmarkRenderMode.LuminanceOnly;

            bool forcesEdgeAware =
                benchmarkRenderMode
                == AsciiBenchmarkRenderMode.EdgeAware;

            int debugView =
                forcesLuminanceOnly || forcesEdgeAware
                    ? (int)AsciiDebugView.Final
                    : Mathf.RoundToInt(
                        material.GetFloat(DebugViewId)
                    );

            bool rendersFinalComposite =
                forcesEdgeAware
                || (
                    !forcesLuminanceOnly
                    && debugView == (int)AsciiDebugView.Final
                    && material.GetFloat(EnableEdgeGlyphsId) > 0.5f
                );

            bool usesAutomaticLuminanceBounds =
                material.GetFloat(
                    LuminanceMappingModeId
                ) > 0.5f
                && material.GetFloat(
                    UseManualLuminanceBoundsId
                ) <= 0.5f;

            bool schedulesLuminanceBoundsReadback =
                cameraData.cameraType == CameraType.Game
                && luminanceBoundsReadbackRequested
                && !luminanceBoundsReadbackInFlight;

            // The full-resolution branch is only needed for its dedicated
            // diagnostics or for the edge-aware final composite.
            bool requiresFullResolutionEdgePipeline =
                rendersFinalComposite
                || (
                    debugView >= FullResolutionLuminanceDebugView
                    && debugView <= EdgeOnlyDebugView
                );

            TextureHandle edgeEvidenceTexture = default;

            if (requiresFullResolutionEdgePipeline)
            {

            TextureDesc luminanceDescriptor =
                new TextureDesc(sourceDescriptor)
                {
                    name = "_AsciiFullResolutionLuminance",

                    sizeMode = TextureSizeMode.Explicit,
                    width = sourceWidth,
                    height = sourceHeight,

                    format = GraphicsFormat.R16_SFloat,

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

            TextureHandle luminanceTexture =
                renderGraph.CreateTexture(luminanceDescriptor);

            if (!luminanceTexture.IsValid())
            {
                return;
            }

            var luminanceParameters =
                new RenderGraphUtils.BlitMaterialParameters(
                    source,
                    luminanceTexture,
                    material,
                    FullResolutionLuminancePassIndex
                );

            renderGraph.AddBlitPass(
                luminanceParameters,
                "Create Full-Resolution Luminance"
            );

            if (debugView == FullResolutionLuminanceDebugView)
            {
                var debugParameters =
                    new RenderGraphUtils.BlitMaterialParameters(
                        luminanceTexture,
                        destination,
                        material,
                        FullResolutionLuminanceDebugPassIndex
                    );

                renderGraph.AddBlitPass(
                    debugParameters,
                    "Debug Full-Resolution Luminance"
                );

                return;
            }

            TextureDesc gaussianHorizontalDescriptor =
                new TextureDesc(luminanceDescriptor)
                {
                    name = "_AsciiGaussianHorizontalPair",
                    format = GraphicsFormat.R16G16_SFloat,
                };

            TextureHandle gaussianHorizontalTexture =
                renderGraph.CreateTexture(
                    gaussianHorizontalDescriptor
                );

            TextureDesc gaussianVerticalDescriptor =
                new TextureDesc(luminanceDescriptor)
                {
                    name = "_AsciiGaussianLuminance",
                    format = GraphicsFormat.R16G16_SFloat,
                };

            TextureHandle gaussianLuminanceTexture =
                renderGraph.CreateTexture(
                    gaussianVerticalDescriptor
                );

            if (
                !gaussianHorizontalTexture.IsValid()
                || !gaussianLuminanceTexture.IsValid()
            )
            {
                return;
            }

            var gaussianHorizontalParameters =
                new RenderGraphUtils.BlitMaterialParameters(
                    luminanceTexture,
                    gaussianHorizontalTexture,
                    material,
                    GaussianHorizontalPassIndex
                );

            renderGraph.AddBlitPass(
                gaussianHorizontalParameters,
                "Gaussian Blur Horizontal"
            );

            var gaussianVerticalParameters =
                new RenderGraphUtils.BlitMaterialParameters(
                    gaussianHorizontalTexture,
                    gaussianLuminanceTexture,
                    material,
                    GaussianVerticalPassIndex
                );

            renderGraph.AddBlitPass(
                gaussianVerticalParameters,
                "Gaussian Blur Vertical"
            );

            if (debugView == GaussianLuminanceDebugView)
            {
                var debugParameters =
                    new RenderGraphUtils.BlitMaterialParameters(
                        gaussianLuminanceTexture,
                        destination,
                        material,
                        FullResolutionLuminanceDebugPassIndex
                    );

                renderGraph.AddBlitPass(
                    debugParameters,
                    "Debug Gaussian Luminance"
                );

                return;
            }

            if (debugView == LargeGaussianLuminanceDebugView)
            {
                var debugParameters =
                    new RenderGraphUtils.BlitMaterialParameters(
                        gaussianLuminanceTexture,
                        destination,
                        material,
                        LargeGaussianLuminanceDebugPassIndex
                    );

                renderGraph.AddBlitPass(
                    debugParameters,
                    "Debug Large Gaussian Luminance"
                );

                return;
            }

            bool displaysDoG =
                debugView == SignedDoGDebugView
                || debugView == BinaryDoGDebugView
                || debugView == TauAdjustedDoGResponseDebugView;

            if (displaysDoG)
            {
                TextureDesc dogDescriptor =
                    new TextureDesc(luminanceDescriptor)
                    {
                        name = "_AsciiDifferenceOfGaussians",
                        format = GraphicsFormat.R16G16_SFloat,
                    };

                TextureHandle dogTexture =
                    renderGraph.CreateTexture(dogDescriptor);

                if (!dogTexture.IsValid())
                {
                    return;
                }

                var dogParameters =
                    new RenderGraphUtils.BlitMaterialParameters(
                        gaussianLuminanceTexture,
                        dogTexture,
                        material,
                        DifferenceOfGaussiansPassIndex
                    );

                renderGraph.AddBlitPass(
                    dogParameters,
                    "Calculate Difference of Gaussians"
                );

                var debugParameters =
                    new RenderGraphUtils.BlitMaterialParameters(
                        dogTexture,
                        destination,
                        material,
                        DifferenceOfGaussiansDebugPassIndex
                    );

                renderGraph.AddBlitPass(
                    debugParameters,
                    "Debug Difference of Gaussians"
                );

                return;
            }

            TextureDesc edgeEvidenceDescriptor =
                new TextureDesc(luminanceDescriptor)
                {
                    name = "_AsciiFullResolutionEdgeEvidence",
                    format = GraphicsFormat.R16G16B16A16_SFloat,
                };

            edgeEvidenceTexture =
                renderGraph.CreateTexture(
                    edgeEvidenceDescriptor
                );

            if (!edgeEvidenceTexture.IsValid())
            {
                return;
            }

            var edgeEvidenceParameters =
                new RenderGraphUtils.BlitMaterialParameters(
                    gaussianLuminanceTexture,
                    edgeEvidenceTexture,
                    material,
                    EdgeEvidencePassIndex
                );

            renderGraph.AddBlitPass(
                edgeEvidenceParameters,
                "Prepare Full-Resolution Edge Evidence"
            );

            bool displaysEdgeEvidence =
                debugView == EdgeSobelDirectionDebugView;

            if (displaysEdgeEvidence)
            {
                var debugParameters =
                    new RenderGraphUtils.BlitMaterialParameters(
                        edgeEvidenceTexture,
                        destination,
                        material,
                        EdgeEvidenceDebugPassIndex
                    );

                renderGraph.AddBlitPass(
                    debugParameters,
                    "Debug Full-Resolution Edge Evidence"
                );

                return;
            }

            bool displaysCellEdgeMeasurements =
                debugView == CellEdgePixelCountDebugView
                || debugView == CellEdgeDominantSupportDebugView
                || debugView == CellEdgeDominanceDebugView
                || debugView == CellEdgeDominantDirectionDebugView
                || debugView == CellEdgeCandidateMaskDebugView
                || debugView == EdgeOnlyDebugView;

            if (displaysCellEdgeMeasurements)
            {
                TextureDesc cellEdgeHistogramDescriptor =
                    new TextureDesc(edgeEvidenceDescriptor)
                    {
                        name = "_AsciiCellEdgeDirectionalHistogram",

                        sizeMode = TextureSizeMode.Explicit,
                        width = cellTextureWidth,
                        height = cellTextureHeight,

                        format =
                            GraphicsFormat.R16G16B16A16_SFloat,
                    };

                TextureHandle cellEdgeHistogramTexture =
                    renderGraph.CreateTexture(
                        cellEdgeHistogramDescriptor
                    );

                if (!cellEdgeHistogramTexture.IsValid())
                {
                    return;
                }

                using (
                    var builder =
                        renderGraph.AddRasterRenderPass<
                            CellEdgeAggregationPassData
                        >(
                            "Aggregate ASCII Cell Edge Evidence",
                            out var passData
                        )
                )
                {
                    passData.edgeEvidence = edgeEvidenceTexture;
                    passData.material = material;

                    builder.UseTexture(
                        passData.edgeEvidence,
                        AccessFlags.Read
                    );

                    builder.SetRenderAttachment(
                        cellEdgeHistogramTexture,
                        0,
                        AccessFlags.Write
                    );

                    builder.SetRenderFunc(
                        static (
                            CellEdgeAggregationPassData data,
                            RasterGraphContext context
                        ) =>
                        {
                            Blitter.BlitTexture(
                                context.cmd,
                                data.edgeEvidence,
                                new Vector4(1.0f, 1.0f, 0.0f, 0.0f),
                                data.material,
                                CellEdgeAggregationPassIndex
                            );
                        }
                    );
                }

                int cellEdgeOutputPassIndex =
                    debugView == EdgeOnlyDebugView
                        ? EdgeOnlyAsciiPassIndex
                        : CellEdgeDebugPassIndex;

                string cellEdgeOutputPassName =
                    debugView == EdgeOnlyDebugView
                        ? "Render Edge-Only ASCII"
                        : "Debug ASCII Cell Edge Measurements";

                var cellEdgeOutputParameters =
                    new RenderGraphUtils.BlitMaterialParameters(
                        cellEdgeHistogramTexture,
                        destination,
                        material,
                        cellEdgeOutputPassIndex
                    );

                renderGraph.AddBlitPass(
                    cellEdgeOutputParameters,
                    cellEdgeOutputPassName
                );

                return;
            }

            bool displaysSobel =
                debugView == ReferenceSobelMagnitudeDebugView
                || debugView == ReferenceSobelDirectionDebugView;

            if (displaysSobel)
            {
                AsciiEdgeInput edgeInput =
                    (AsciiEdgeInput)Mathf.RoundToInt(
                        material.GetFloat(EdgeInputId)
                    );

                TextureHandle sobelInputTexture =
                    edgeInput == AsciiEdgeInput.GaussianLuminance
                        ? gaussianLuminanceTexture
                        : luminanceTexture;

                TextureDesc sobelDescriptor =
                    new TextureDesc(luminanceDescriptor)
                    {
                        name = "_AsciiFullResolutionSobel",
                        format = GraphicsFormat.R16G16_SFloat,
                    };

                TextureHandle sobelTexture =
                    renderGraph.CreateTexture(sobelDescriptor);

                if (!sobelTexture.IsValid())
                {
                    return;
                }

                var sobelParameters =
                    new RenderGraphUtils.BlitMaterialParameters(
                        sobelInputTexture,
                        sobelTexture,
                        material,
                        FullResolutionSobelPassIndex
                    );

                renderGraph.AddBlitPass(
                    sobelParameters,
                    "Calculate Full-Resolution Sobel"
                );

                var debugParameters =
                    new RenderGraphUtils.BlitMaterialParameters(
                        sobelTexture,
                        destination,
                        material,
                        FullResolutionSobelDebugPassIndex
                    );

                renderGraph.AddBlitPass(
                    debugParameters,
                    "Debug Full-Resolution Sobel"
                );

                return;
            }

            }

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

            TextureHandle luminanceBoundsTexture = default;

            if (
                usesAutomaticLuminanceBounds
                || schedulesLuminanceBoundsReadback
            )
            {
                TextureDesc boundsDescriptor =
                    new TextureDesc(cellDescriptor)
                    {
                        name = "_AsciiCellLuminanceBoundsSeed",
                        width = cellTextureWidth,
                        height = cellTextureHeight,
                        format = GraphicsFormat.R16G16_SFloat,
                    };

                TextureHandle currentBoundsTexture =
                    renderGraph.CreateTexture(boundsDescriptor);

                if (!currentBoundsTexture.IsValid())
                {
                    return;
                }

                var seedBoundsParameters =
                    new RenderGraphUtils.BlitMaterialParameters(
                        cellTexture,
                        currentBoundsTexture,
                        material,
                        CellLuminanceBoundsSeedPassIndex
                    );

                renderGraph.AddBlitPass(
                    seedBoundsParameters,
                    "Seed Cell Luminance Bounds"
                );

                int boundsWidth = cellTextureWidth;
                int boundsHeight = cellTextureHeight;

                while (boundsWidth > 1 || boundsHeight > 1)
                {
                    boundsWidth = Mathf.Max(
                        (boundsWidth + 1) / 2,
                        1
                    );
                    boundsHeight = Mathf.Max(
                        (boundsHeight + 1) / 2,
                        1
                    );

                    TextureDesc reducedBoundsDescriptor =
                        new TextureDesc(boundsDescriptor)
                        {
                            name = "_AsciiReducedLuminanceBounds",
                            width = boundsWidth,
                            height = boundsHeight,
                        };

                    TextureHandle reducedBoundsTexture =
                        renderGraph.CreateTexture(
                            reducedBoundsDescriptor
                        );

                    if (!reducedBoundsTexture.IsValid())
                    {
                        return;
                    }

                    var reduceBoundsParameters =
                        new RenderGraphUtils.BlitMaterialParameters(
                            currentBoundsTexture,
                            reducedBoundsTexture,
                            material,
                            CellLuminanceBoundsReducePassIndex
                        );

                    renderGraph.AddBlitPass(
                        reduceBoundsParameters,
                        "Reduce Cell Luminance Bounds"
                    );

                    currentBoundsTexture =
                        reducedBoundsTexture;
                }

                luminanceBoundsTexture = currentBoundsTexture;

                if (schedulesLuminanceBoundsReadback)
                {
                    using (
                        var builder =
                            renderGraph.AddUnsafePass<
                                LuminanceBoundsReadbackPassData
                            >(
                                "Read Back Luminance Bounds",
                                out var passData
                            )
                    )
                    {
                        passData.luminanceBounds =
                            luminanceBoundsTexture;
                        passData.owner = this;

                        builder.UseTexture(
                            passData.luminanceBounds,
                            AccessFlags.Read
                        );
                        builder.AllowPassCulling(false);

                        builder.SetRenderFunc(
                            static (
                                LuminanceBoundsReadbackPassData data,
                                UnsafeGraphContext context
                            ) =>
                            {
                                context.cmd.RequestAsyncReadback(
                                    data.luminanceBounds,
                                    0,
                                    GraphicsFormat.R32G32_SFloat,
                                    data.owner
                                        .CompleteLuminanceBoundsReadback
                                );
                            }
                        );
                    }

                    luminanceBoundsReadbackRequested = false;
                    luminanceBoundsReadbackInFlight = true;
                }
            }

            if (rendersFinalComposite)
            {
                TextureDesc cellEdgeHistogramDescriptor =
                    new TextureDesc(sourceDescriptor)
                    {
                        name = "_AsciiCellEdgeDirectionalHistogram",

                        sizeMode = TextureSizeMode.Explicit,
                        width = cellTextureWidth,
                        height = cellTextureHeight,

                        format =
                            GraphicsFormat.R16G16B16A16_SFloat,
                    };

                TextureHandle cellEdgeHistogramTexture =
                    renderGraph.CreateTexture(
                        cellEdgeHistogramDescriptor
                    );

                if (!cellEdgeHistogramTexture.IsValid())
                {
                    return;
                }

                using (
                    var builder =
                        renderGraph.AddRasterRenderPass<
                            CellEdgeAggregationPassData
                        >(
                            "Aggregate Composite Cell Edge Evidence",
                            out var passData
                        )
                )
                {
                    passData.edgeEvidence = edgeEvidenceTexture;
                    passData.material = material;

                    builder.UseTexture(
                        passData.edgeEvidence,
                        AccessFlags.Read
                    );

                    builder.SetRenderAttachment(
                        cellEdgeHistogramTexture,
                        0,
                        AccessFlags.Write
                    );

                    builder.SetRenderFunc(
                        static (
                            CellEdgeAggregationPassData data,
                            RasterGraphContext context
                        ) =>
                        {
                            Blitter.BlitTexture(
                                context.cmd,
                                data.edgeEvidence,
                                new Vector4(1.0f, 1.0f, 0.0f, 0.0f),
                                data.material,
                                CellEdgeAggregationPassIndex
                            );
                        }
                    );
                }

                using (
                    var builder =
                        renderGraph.AddRasterRenderPass<
                            CompositeAsciiPassData
                        >(
                            "Render Composite ASCII",
                            out var passData
                        )
                )
                {
                    passData.cellTexture = cellTexture;
                    passData.edgeHistogram =
                        cellEdgeHistogramTexture;
                    passData.luminanceBounds =
                        luminanceBoundsTexture;
                    passData.usesAutomaticLuminanceBounds =
                        usesAutomaticLuminanceBounds;
                    passData.material = material;

                    builder.UseTexture(
                        passData.cellTexture,
                        AccessFlags.Read
                    );

                    builder.UseTexture(
                        passData.edgeHistogram,
                        AccessFlags.Read
                    );

                    if (passData.usesAutomaticLuminanceBounds)
                    {
                        builder.UseTexture(
                            passData.luminanceBounds,
                            AccessFlags.Read
                        );
                    }

                    builder.SetRenderAttachment(
                        destination,
                        0,
                        AccessFlags.Write
                    );

                    builder.AllowGlobalStateModification(true);

                    builder.SetRenderFunc(
                        static (
                            CompositeAsciiPassData data,
                            RasterGraphContext context
                        ) =>
                        {
                            context.cmd.SetGlobalTexture(
                                CellEdgeHistogramTextureId,
                                data.edgeHistogram
                            );

                            if (data.usesAutomaticLuminanceBounds)
                            {
                                context.cmd.SetGlobalTexture(
                                    LuminanceBoundsTextureId,
                                    data.luminanceBounds
                                );
                            }

                            Blitter.BlitTexture(
                                context.cmd,
                                data.cellTexture,
                                new Vector4(1.0f, 1.0f, 0.0f, 0.0f),
                                data.material,
                                CompositeAsciiRendererPassIndex
                            );
                        }
                    );
                }

                return;
            }

            if (usesAutomaticLuminanceBounds)
            {
                using (
                    var builder =
                        renderGraph.AddRasterRenderPass<
                            LuminanceAsciiPassData
                        >(
                            "Render ASCII",
                            out var passData
                        )
                )
                {
                    passData.cellTexture = cellTexture;
                    passData.luminanceBounds =
                        luminanceBoundsTexture;
                    passData.material = material;

                    builder.UseTexture(
                        passData.cellTexture,
                        AccessFlags.Read
                    );
                    builder.UseTexture(
                        passData.luminanceBounds,
                        AccessFlags.Read
                    );

                    builder.SetRenderAttachment(
                        destination,
                        0,
                        AccessFlags.Write
                    );

                    builder.AllowGlobalStateModification(true);

                    builder.SetRenderFunc(
                        static (
                            LuminanceAsciiPassData data,
                            RasterGraphContext context
                        ) =>
                        {
                            context.cmd.SetGlobalTexture(
                                LuminanceBoundsTextureId,
                                data.luminanceBounds
                            );

                            Blitter.BlitTexture(
                                context.cmd,
                                data.cellTexture,
                                new Vector4(
                                    1.0f,
                                    1.0f,
                                    0.0f,
                                    0.0f
                                ),
                                data.material,
                                AsciiRendererPassIndex
                            );
                        }
                    );
                }

                return;
            }

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
