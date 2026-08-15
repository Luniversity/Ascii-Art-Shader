using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;

using Unity.Profiling;
using UnityEngine;

namespace AsciiShader
{
    public sealed class AsciiPerformanceBenchmark : MonoBehaviour
    {
        private static readonly int DebugViewId =
            Shader.PropertyToID("_DebugView");
        private static readonly int LuminanceMappingModeId =
            Shader.PropertyToID("_LuminanceMappingMode");
        private static readonly int UseManualLuminanceBoundsId =
            Shader.PropertyToID("_UseManualLuminanceBounds");

        private const string SeedLuminanceBoundsPassName =
            "Seed Cell Luminance Bounds";
        private const string ReduceLuminanceBoundsPassName =
            "Reduce Cell Luminance Bounds";

        private enum BenchmarkPhase
        {
            Idle,
            Warmup,
            Capturing,
            WritingReport,
            Complete,
            Cancelled,
            Error,
        }

        private static readonly AsciiBenchmarkRenderMode[] StandardSuite =
        {
            AsciiBenchmarkRenderMode.Disabled,
            AsciiBenchmarkRenderMode.LuminanceOnly,
            AsciiBenchmarkRenderMode.EdgeAware,
        };

        private static readonly string[] AsciiGpuPassNames =
        {
            "Create Full-Resolution Luminance",
            "Gaussian Blur Horizontal",
            "Gaussian Blur Vertical",
            "Prepare Full-Resolution Edge Evidence",
            "Analyze ASCII Cells",
            SeedLuminanceBoundsPassName,
            ReduceLuminanceBoundsPassName,
            "Aggregate Composite Cell Edge Evidence",
            "Render Composite ASCII",
            "Render ASCII",
        };

        [SerializeField]
        private AsciiRendererFeature rendererFeature;

        [SerializeField, Min(0f)]
        private float warmupSeconds = 3f;

        [SerializeField, Min(0.1f)]
        private float captureSeconds = 10f;

        [SerializeField]
        private bool freezeGameplay = true;

        private readonly List<ModeResult> results = new();
        private readonly FrameTiming[] timingBuffer =
            new FrameTiming[4];

        private Coroutine activeRun;
        private BenchmarkPhase phase = BenchmarkPhase.Idle;
        private AsciiBenchmarkRenderMode currentMode =
            AsciiBenchmarkRenderMode.MaterialSettings;
        private ModeResult currentResult;
        private double phaseEndTime;
        private bool cancelRequested;
        private string lastReportPath = string.Empty;
        private string statusMessage = "Ready";

        private float previousTimeScale;
        private int previousVSyncCount;
        private int previousTargetFrameRate;
        private bool stateCaptured;
        private float previousDebugView;
        private Material benchmarkMaterialSnapshot;


        private Material BenchmarkMaterial =>
            rendererFeature != null
                ? rendererFeature.BenchmarkMaterial
                : null;


        private void OnDisable()
        {
            if (activeRun != null)
            {
                StopCoroutine(activeRun);
                activeRun = null;
            }

            RestoreRuntimeState();
        }


        private void OnGUI()
        {
            const float panelWidth = 390f;
            const float panelHeight = 285f;

            GUILayout.BeginArea(
                new Rect(16f, 16f, panelWidth, panelHeight),
                GUI.skin.box
            );

            GUILayout.Label("ASCII Performance Benchmark");
            GUILayout.Label($"Status: {statusMessage}");

            if (activeRun != null)
            {
                double remaining = Math.Max(
                    phaseEndTime - Time.realtimeSinceStartupAsDouble,
                    0.0
                );

                GUILayout.Label($"Mode: {GetModeLabel(currentMode)}");
                GUILayout.Label($"Phase: {phase}");
                GUILayout.Label($"Remaining: {remaining:F1} s");

                int validGpuSamples =
                    currentResult != null
                        ? currentResult.GpuFrame.Count
                        : 0;

                GUILayout.Label(
                    $"Valid GPU frame samples: {validGpuSamples}"
                );
            }

            bool wasEnabled = GUI.enabled;
            GUI.enabled = activeRun == null;

            if (GUILayout.Button("Run Standard Suite"))
            {
                StartBenchmark(StandardSuite);
            }

            GUILayout.BeginHorizontal();

            if (GUILayout.Button("Baseline"))
            {
                StartBenchmark(
                    AsciiBenchmarkRenderMode.Disabled
                );
            }

            if (GUILayout.Button("Luminance"))
            {
                StartBenchmark(
                    AsciiBenchmarkRenderMode.LuminanceOnly
                );
            }

            if (GUILayout.Button("Edge Aware"))
            {
                StartBenchmark(
                    AsciiBenchmarkRenderMode.EdgeAware
                );
            }

            GUILayout.EndHorizontal();

            GUI.enabled = activeRun != null;

            if (GUILayout.Button("Cancel"))
            {
                cancelRequested = true;
            }

            GUI.enabled = wasEnabled;

            if (!string.IsNullOrEmpty(lastReportPath))
            {
                GUILayout.Label("Last report:");
                GUILayout.TextField(lastReportPath);
            }

            GUILayout.EndArea();
        }


        private void StartBenchmark(
            params AsciiBenchmarkRenderMode[] modes
        )
        {
            if (activeRun != null)
            {
                return;
            }

            if (rendererFeature == null)
            {
                phase = BenchmarkPhase.Error;
                statusMessage = "Renderer feature reference is missing.";
                return;
            }

            if (BenchmarkMaterial == null)
            {
                phase = BenchmarkPhase.Error;
                statusMessage = "Renderer material reference is missing.";
                return;
            }

            cancelRequested = false;
            results.Clear();
            activeRun = StartCoroutine(RunBenchmark(modes));
        }


        private IEnumerator RunBenchmark(
            IReadOnlyList<AsciiBenchmarkRenderMode> modes
        )
        {
            CaptureAndApplyRuntimeState();

            try
            {
                for (int index = 0; index < modes.Count; ++index)
                {
                    if (cancelRequested)
                    {
                        break;
                    }

                    currentMode = modes[index];
                    rendererFeature.SetBenchmarkRenderMode(currentMode);

                    phase = BenchmarkPhase.Warmup;
                    statusMessage =
                        $"Warming up {GetModeLabel(currentMode)}";

                    yield return RunTimedPhase(
                        warmupSeconds,
                        collectSamples: false,
                        result: null,
                        passRecorders: null
                    );

                    if (cancelRequested)
                    {
                        break;
                    }

                    bool usesAutomaticLuminanceBounds =
                        BenchmarkMaterial.GetFloat(
                            LuminanceMappingModeId
                        ) > 0.5f
                        && BenchmarkMaterial.GetFloat(
                            UseManualLuminanceBoundsId
                        ) <= 0.5f;

                    currentResult = new ModeResult(
                        currentMode,
                        usesAutomaticLuminanceBounds
                    );
                    results.Add(currentResult);

                    using PassRecorderSet passRecorders =
                        new PassRecorderSet(AsciiGpuPassNames);

                    phase = BenchmarkPhase.Capturing;
                    statusMessage =
                        $"Capturing {GetModeLabel(currentMode)}";

                    yield return RunTimedPhase(
                        captureSeconds,
                        collectSamples: true,
                        currentResult,
                        passRecorders
                    );
                }

                if (cancelRequested)
                {
                    phase = BenchmarkPhase.Cancelled;
                    statusMessage = "Benchmark cancelled";
                }
                else
                {
                    phase = BenchmarkPhase.WritingReport;
                    statusMessage = "Writing benchmark report";

                    if (WriteReports())
                    {
                        phase = BenchmarkPhase.Complete;
                        statusMessage = "Benchmark complete";
                    }
                }
            }
            finally
            {
                currentResult = null;
                currentMode =
                    AsciiBenchmarkRenderMode.MaterialSettings;
                RestoreRuntimeState();
                activeRun = null;
            }
        }


        private IEnumerator RunTimedPhase(
            float duration,
            bool collectSamples,
            ModeResult result,
            PassRecorderSet passRecorders
        )
        {
            phaseEndTime =
                Time.realtimeSinceStartupAsDouble
                + Math.Max(duration, 0.0f);

            ulong lastFrameTimestamp = 0;

            while (
                !cancelRequested
                && Time.realtimeSinceStartupAsDouble < phaseEndTime
            )
            {
                yield return new WaitForEndOfFrame();

                FrameTimingManager.CaptureFrameTimings();

                if (!collectSamples)
                {
                    continue;
                }

                ++result.ObservedFrames;
                result.FrameInterval.Add(
                    Time.unscaledDeltaTime * 1000.0
                );

                CollectLatestFrameTiming(
                    result,
                    ref lastFrameTimestamp
                );

                passRecorders?.Collect(result);
            }
        }


        private void CollectLatestFrameTiming(
            ModeResult result,
            ref ulong lastFrameTimestamp
        )
        {
            uint timingCount = FrameTimingManager.GetLatestTimings(
                (uint)timingBuffer.Length,
                timingBuffer
            );

            int newestIndex = -1;
            ulong newestTimestamp = lastFrameTimestamp;

            for (int index = 0; index < timingCount; ++index)
            {
                ulong timestamp =
                    timingBuffer[index].frameStartTimestamp;

                if (timestamp > newestTimestamp)
                {
                    newestTimestamp = timestamp;
                    newestIndex = index;
                }
            }

            if (newestIndex < 0)
            {
                return;
            }

            lastFrameTimestamp = newestTimestamp;
            FrameTiming timing = timingBuffer[newestIndex];

            result.CpuFrame.AddIfValid(timing.cpuFrameTime);
            result.CpuMainThread.AddIfValid(
                timing.cpuMainThreadFrameTime
            );
            result.CpuRenderThread.AddIfValid(
                timing.cpuRenderThreadFrameTime
            );
            result.GpuFrame.AddIfValid(timing.gpuFrameTime);
            result.WidthScale.AddIfValid(timing.widthScale);
            result.HeightScale.AddIfValid(timing.heightScale);
        }


        private void CaptureAndApplyRuntimeState()
        {
            previousTimeScale = Time.timeScale;
            previousVSyncCount = QualitySettings.vSyncCount;
            previousTargetFrameRate = Application.targetFrameRate;
            benchmarkMaterialSnapshot = BenchmarkMaterial;
            previousDebugView =
                benchmarkMaterialSnapshot.GetFloat(DebugViewId);
            stateCaptured = true;

            if (freezeGameplay)
            {
                Time.timeScale = 0f;
            }

            QualitySettings.vSyncCount = 0;
            Application.targetFrameRate = -1;
            benchmarkMaterialSnapshot.SetFloat(
                DebugViewId,
                (float)AsciiDebugView.Final
            );
        }


        private void RestoreRuntimeState()
        {
            rendererFeature?.ClearBenchmarkRenderMode();

            if (!stateCaptured)
            {
                return;
            }

            Time.timeScale = previousTimeScale;
            QualitySettings.vSyncCount = previousVSyncCount;
            Application.targetFrameRate = previousTargetFrameRate;
            if (benchmarkMaterialSnapshot != null)
            {
                benchmarkMaterialSnapshot.SetFloat(
                    DebugViewId,
                    previousDebugView
                );
            }

            benchmarkMaterialSnapshot = null;
            stateCaptured = false;
        }


        private bool WriteReports()
        {
            try
            {
                string outputDirectory = ResolveOutputDirectory();
                Directory.CreateDirectory(outputDirectory);

                string timestamp = DateTime.Now.ToString(
                    "yyyyMMdd_HHmmss",
                    CultureInfo.InvariantCulture
                );

                string basePath = Path.Combine(
                    outputDirectory,
                    $"AsciiBenchmark_{timestamp}"
                );

                BenchmarkMetadata metadata =
                    BenchmarkMetadata.Capture(
                        BenchmarkMaterial,
                        warmupSeconds,
                        captureSeconds
                    );

                File.WriteAllText(
                    basePath + ".csv",
                    BuildCsv(metadata, timestamp),
                    new UTF8Encoding(false)
                );

                File.WriteAllText(
                    basePath + ".md",
                    BuildMarkdown(metadata, timestamp),
                    new UTF8Encoding(false)
                );

                lastReportPath = basePath + ".md";
                Debug.Log(
                    $"ASCII benchmark reports written to {basePath}.csv and {basePath}.md"
                );

                return true;
            }
            catch (Exception exception)
            {
                phase = BenchmarkPhase.Error;
                statusMessage =
                    $"Report writing failed: {exception.Message}";
                Debug.LogException(exception, this);
                return false;
            }
        }


        private string BuildCsv(
            BenchmarkMetadata metadata,
            string timestamp
        )
        {
            var builder = new StringBuilder();

            builder.AppendLine(
                "timestamp,mode,scope,metric,unit,average,median,p95,sample_count,editor,unity_version,platform,operating_system,gpu,gpu_vendor,graphics_api,resolution,cell_size,color_mode,luminance_mapping,gaussian_sigma,gaussian_radius,gaussian_scale,dog_tau,dog_threshold,minimum_dominant_pixels,minimum_dominance,warmup_seconds,capture_seconds"
            );

            foreach (ModeResult result in results)
            {
                AppendMetricCsv(
                    builder,
                    metadata,
                    timestamp,
                    result,
                    "Frame",
                    "Observed frame interval",
                    "ms",
                    result.FrameInterval
                );
                AppendMetricCsv(builder, metadata, timestamp, result, "Frame", "CPU frame", "ms", result.CpuFrame);
                AppendMetricCsv(builder, metadata, timestamp, result, "Frame", "CPU main thread", "ms", result.CpuMainThread);
                AppendMetricCsv(builder, metadata, timestamp, result, "Frame", "CPU render thread", "ms", result.CpuRenderThread);
                AppendMetricCsv(builder, metadata, timestamp, result, "Frame", "GPU frame", "ms", result.GpuFrame);
                AppendMetricCsv(builder, metadata, timestamp, result, "Frame", "Dynamic width scale", "ratio", result.WidthScale);
                AppendMetricCsv(builder, metadata, timestamp, result, "Frame", "Dynamic height scale", "ratio", result.HeightScale);

                foreach (
                    KeyValuePair<string, MetricSamples> entry
                    in result.PassGpuTimes
                )
                {
                    AppendMetricCsv(
                        builder,
                        metadata,
                        timestamp,
                        result,
                        "GPU Pass",
                        entry.Key,
                        "ms",
                        entry.Value
                    );
                }
            }

            AppendDeltaCsv(
                builder,
                metadata,
                timestamp,
                "Basic ASCII GPU delta",
                AsciiBenchmarkRenderMode.LuminanceOnly,
                AsciiBenchmarkRenderMode.Disabled
            );
            AppendDeltaCsv(
                builder,
                metadata,
                timestamp,
                "Additional edge GPU delta",
                AsciiBenchmarkRenderMode.EdgeAware,
                AsciiBenchmarkRenderMode.LuminanceOnly
            );
            AppendDeltaCsv(
                builder,
                metadata,
                timestamp,
                "Total effect GPU delta",
                AsciiBenchmarkRenderMode.EdgeAware,
                AsciiBenchmarkRenderMode.Disabled
            );

            return builder.ToString();
        }


        private void AppendMetricCsv(
            StringBuilder builder,
            BenchmarkMetadata metadata,
            string timestamp,
            ModeResult result,
            string scope,
            string metricName,
            string unit,
            MetricSamples samples
        )
        {
            MetricStatistics statistics = samples.GetStatistics();

            AppendCsvValue(builder, timestamp);
            AppendCsvValue(builder, GetModeLabel(result.Mode));
            AppendCsvValue(builder, scope);
            AppendCsvValue(builder, metricName);
            AppendCsvValue(builder, unit);
            AppendCsvValue(builder, FormatCsvNumber(statistics.Average));
            AppendCsvValue(builder, FormatCsvNumber(statistics.Median));
            AppendCsvValue(builder, FormatCsvNumber(statistics.P95));
            AppendCsvValue(builder, statistics.Count.ToString(CultureInfo.InvariantCulture));
            AppendMetadataCsv(builder, metadata);
            builder.AppendLine();
        }


        private void AppendDeltaCsv(
            StringBuilder builder,
            BenchmarkMetadata metadata,
            string timestamp,
            string label,
            AsciiBenchmarkRenderMode minuendMode,
            AsciiBenchmarkRenderMode subtrahendMode
        )
        {
            if (!TryGetGpuDelta(
                minuendMode,
                subtrahendMode,
                out double delta
            ))
            {
                return;
            }

            AppendCsvValue(builder, timestamp);
            AppendCsvValue(builder, "Suite");
            AppendCsvValue(builder, "Derived");
            AppendCsvValue(builder, label);
            AppendCsvValue(builder, "ms");
            AppendCsvValue(builder, string.Empty);
            AppendCsvValue(builder, FormatCsvNumber(delta));
            AppendCsvValue(builder, string.Empty);
            AppendCsvValue(builder, "0");
            AppendMetadataCsv(builder, metadata);
            builder.AppendLine();
        }


        private static void AppendMetadataCsv(
            StringBuilder builder,
            BenchmarkMetadata metadata
        )
        {
            AppendCsvValue(builder, metadata.IsEditor ? "true" : "false");
            AppendCsvValue(builder, metadata.UnityVersion);
            AppendCsvValue(builder, metadata.Platform);
            AppendCsvValue(builder, metadata.OperatingSystem);
            AppendCsvValue(builder, metadata.Gpu);
            AppendCsvValue(builder, metadata.GpuVendor);
            AppendCsvValue(builder, metadata.GraphicsApi);
            AppendCsvValue(builder, metadata.Resolution);
            AppendCsvValue(builder, metadata.CellSize);
            AppendCsvValue(builder, metadata.ColorMode);
            AppendCsvValue(builder, metadata.LuminanceMapping);
            AppendCsvValue(builder, FormatCsvNumber(metadata.GaussianSigma));
            AppendCsvValue(builder, metadata.GaussianRadius.ToString(CultureInfo.InvariantCulture));
            AppendCsvValue(builder, FormatCsvNumber(metadata.GaussianScale));
            AppendCsvValue(builder, FormatCsvNumber(metadata.DoGTau));
            AppendCsvValue(builder, FormatCsvNumber(metadata.DoGThreshold));
            AppendCsvValue(builder, FormatCsvNumber(metadata.MinimumDominantPixels));
            AppendCsvValue(builder, FormatCsvNumber(metadata.MinimumDominance));
            AppendCsvValue(builder, FormatCsvNumber(metadata.WarmupSeconds));
            AppendCsvValue(builder, FormatCsvNumber(metadata.CaptureSeconds), appendComma: false);
        }


        private string BuildMarkdown(
            BenchmarkMetadata metadata,
            string timestamp
        )
        {
            var builder = new StringBuilder();

            builder.AppendLine("# ASCII Shader Benchmark");
            builder.AppendLine();
            builder.AppendLine($"Recorded: `{timestamp}`");
            builder.AppendLine();
            builder.AppendLine("## Environment");
            builder.AppendLine();
            builder.AppendLine($"- Context: {(metadata.IsEditor ? "Unity Editor" : "Player build")}");
            builder.AppendLine($"- Unity: `{metadata.UnityVersion}`");
            builder.AppendLine($"- Platform: `{metadata.Platform}`");
            builder.AppendLine($"- OS: `{metadata.OperatingSystem}`");
            builder.AppendLine($"- GPU: `{metadata.Gpu}`");
            builder.AppendLine($"- Vendor: `{metadata.GpuVendor}`");
            builder.AppendLine($"- Graphics API: `{metadata.GraphicsApi}`");
            builder.AppendLine($"- Resolution: `{metadata.Resolution}`");
            builder.AppendLine($"- Frame Timing Stats available: `{FrameTimingManager.IsFeatureEnabled()}`");
            builder.AppendLine();
            builder.AppendLine("## Shader settings");
            builder.AppendLine();
            builder.AppendLine($"- Cell size: `{metadata.CellSize}`");
            builder.AppendLine($"- Color mode: `{metadata.ColorMode}`");
            builder.AppendLine($"- Luminance mapping: `{metadata.LuminanceMapping}`");
            builder.AppendLine($"- Gaussian: sigma `{metadata.GaussianSigma:F3}`, radius `{metadata.GaussianRadius}`, scale `{metadata.GaussianScale:F3}`");
            builder.AppendLine($"- DoG: tau `{metadata.DoGTau:F4}`, threshold `{metadata.DoGThreshold:F5}`");
            builder.AppendLine($"- Classifier: minimum dominant pixels `{metadata.MinimumDominantPixels:F2}`, minimum dominance `{metadata.MinimumDominance:F3}`");
            builder.AppendLine($"- Timing: `{metadata.WarmupSeconds:F1}s` warm-up + `{metadata.CaptureSeconds:F1}s` capture per mode");
            builder.AppendLine();
            builder.AppendLine("## Frame comparison");
            builder.AppendLine();
            builder.AppendLine("| Mode | CPU median | CPU p95 | GPU median | GPU p95 | Render scale | Valid GPU samples |");
            builder.AppendLine("|---|---:|---:|---:|---:|---:|---:|");

            foreach (ModeResult result in results)
            {
                MetricStatistics cpu = result.CpuFrame.GetStatistics();
                MetricStatistics gpu = result.GpuFrame.GetStatistics();
                MetricStatistics widthScale =
                    result.WidthScale.GetStatistics();
                MetricStatistics heightScale =
                    result.HeightScale.GetStatistics();

                string renderScale =
                    widthScale.Available && heightScale.Available
                        ? $"{widthScale.Median:F3} x {heightScale.Median:F3}"
                        : "N/A";

                builder.AppendLine(
                    $"| {GetModeLabel(result.Mode)} | {FormatMarkdown(cpu.Median)} | {FormatMarkdown(cpu.P95)} | {FormatMarkdown(gpu.Median)} | {FormatMarkdown(gpu.P95)} | {renderScale} | {gpu.Count} |"
                );
            }

            builder.AppendLine();
            builder.AppendLine("## GPU cost deltas");
            builder.AppendLine();
            AppendDeltaMarkdown(builder, "Basic ASCII", AsciiBenchmarkRenderMode.LuminanceOnly, AsciiBenchmarkRenderMode.Disabled);
            AppendDeltaMarkdown(builder, "Additional edge system", AsciiBenchmarkRenderMode.EdgeAware, AsciiBenchmarkRenderMode.LuminanceOnly);
            AppendDeltaMarkdown(builder, "Total ASCII effect", AsciiBenchmarkRenderMode.EdgeAware, AsciiBenchmarkRenderMode.Disabled);
            builder.AppendLine();
            builder.AppendLine("## ASCII GPU passes");
            builder.AppendLine();
            builder.AppendLine("| Mode | Pass | Median | Average | P95 | Samples |");
            builder.AppendLine("|---|---|---:|---:|---:|---:|");

            var rankedPasses = new List<RankedPass>();

            foreach (ModeResult result in results)
            {
                foreach (
                    KeyValuePair<string, MetricSamples> entry
                    in result.PassGpuTimes
                )
                {
                    MetricStatistics statistics =
                        entry.Value.GetStatistics();

                    builder.AppendLine(
                        $"| {GetModeLabel(result.Mode)} | {entry.Key} | {FormatMarkdown(statistics.Median)} | {FormatMarkdown(statistics.Average)} | {FormatMarkdown(statistics.P95)} | {statistics.Count} |"
                    );

                    if (statistics.Available)
                    {
                        rankedPasses.Add(
                            new RankedPass(
                                result.Mode,
                                entry.Key,
                                statistics.Median
                            )
                        );
                    }
                }
            }

            if (rankedPasses.Count == 0)
            {
                builder.AppendLine("| N/A | GPU pass timing was unavailable | N/A | N/A | N/A | 0 |");
            }

            rankedPasses.Sort(
                static (left, right) =>
                    right.Median.CompareTo(left.Median)
            );

            builder.AppendLine();
            builder.AppendLine("## Measured pass ranking");
            builder.AppendLine();

            if (rankedPasses.Count == 0)
            {
                builder.AppendLine("Per-pass GPU timings were unavailable. Use the Unity GPU Profiler in the Editor or a Development Build.");
            }
            else
            {
                for (int index = 0; index < rankedPasses.Count; ++index)
                {
                    RankedPass pass = rankedPasses[index];
                    builder.AppendLine(
                        $"{index + 1}. {GetModeLabel(pass.Mode)} - {pass.Name}: {pass.Median:F3} ms median"
                    );
                }
            }

            if (metadata.IsEditor)
            {
                builder.AppendLine();
                builder.AppendLine("> Editor timings are intended for iteration. Use a standalone Development Build for portfolio-facing results.");
            }

            return builder.ToString();
        }


        private void AppendDeltaMarkdown(
            StringBuilder builder,
            string label,
            AsciiBenchmarkRenderMode minuendMode,
            AsciiBenchmarkRenderMode subtrahendMode
        )
        {
            if (TryGetGpuDelta(
                minuendMode,
                subtrahendMode,
                out double delta
            ))
            {
                builder.AppendLine($"- {label}: `{delta:+0.000;-0.000;0.000} ms`");
            }
            else
            {
                builder.AppendLine($"- {label}: `N/A`");
            }
        }


        private bool TryGetGpuDelta(
            AsciiBenchmarkRenderMode minuendMode,
            AsciiBenchmarkRenderMode subtrahendMode,
            out double delta
        )
        {
            ModeResult minuend = FindResult(minuendMode);
            ModeResult subtrahend = FindResult(subtrahendMode);

            MetricStatistics minuendStats =
                minuend?.GpuFrame.GetStatistics()
                ?? MetricStatistics.Unavailable;
            MetricStatistics subtrahendStats =
                subtrahend?.GpuFrame.GetStatistics()
                ?? MetricStatistics.Unavailable;

            if (
                !minuendStats.Available
                || !subtrahendStats.Available
            )
            {
                delta = 0.0;
                return false;
            }

            delta = minuendStats.Median - subtrahendStats.Median;
            return true;
        }


        private ModeResult FindResult(
            AsciiBenchmarkRenderMode mode
        )
        {
            for (int index = 0; index < results.Count; ++index)
            {
                if (results[index].Mode == mode)
                {
                    return results[index];
                }
            }

            return null;
        }


        private static string ResolveOutputDirectory()
        {
            DirectoryInfo current = new DirectoryInfo(
                Application.dataPath
            );

            for (int depth = 0; depth < 6 && current != null; ++depth)
            {
                bool hasGit = Directory.Exists(
                    Path.Combine(current.FullName, ".git")
                );
                bool hasUnityProject = Directory.Exists(
                    Path.Combine(current.FullName, "My project", "Assets")
                );

                if (hasGit && hasUnityProject)
                {
                    return Path.Combine(
                        current.FullName,
                        "BenchmarkResults"
                    );
                }

                current = current.Parent;
            }

            return Path.Combine(
                Application.persistentDataPath,
                "AsciiShader",
                "BenchmarkResults"
            );
        }


        private static string GetModeLabel(
            AsciiBenchmarkRenderMode mode
        )
        {
            return mode switch
            {
                AsciiBenchmarkRenderMode.Disabled => "Baseline",
                AsciiBenchmarkRenderMode.LuminanceOnly => "Luminance Only",
                AsciiBenchmarkRenderMode.EdgeAware => "Edge Aware",
                _ => "Material Settings",
            };
        }


        private static string FormatMarkdown(double value)
        {
            return double.IsNaN(value)
                ? "N/A"
                : $"{value:F3} ms";
        }


        private static string FormatCsvNumber(double value)
        {
            return double.IsNaN(value)
                ? string.Empty
                : value.ToString("0.######", CultureInfo.InvariantCulture);
        }


        private static void AppendCsvValue(
            StringBuilder builder,
            string value,
            bool appendComma = true
        )
        {
            string safeValue = value ?? string.Empty;
            builder.Append('"');
            builder.Append(safeValue.Replace("\"", "\"\""));
            builder.Append('"');

            if (appendComma)
            {
                builder.Append(',');
            }
        }


        private sealed class ModeResult
        {
            public readonly AsciiBenchmarkRenderMode Mode;
            public readonly MetricSamples FrameInterval = new();
            public readonly MetricSamples CpuFrame = new();
            public readonly MetricSamples CpuMainThread = new();
            public readonly MetricSamples CpuRenderThread = new();
            public readonly MetricSamples GpuFrame = new();
            public readonly MetricSamples WidthScale = new();
            public readonly MetricSamples HeightScale = new();
            public readonly Dictionary<string, MetricSamples>
                PassGpuTimes = new();

            public int ObservedFrames;


            public ModeResult(
                AsciiBenchmarkRenderMode mode,
                bool usesAutomaticLuminanceBounds
            )
            {
                Mode = mode;

                if (mode == AsciiBenchmarkRenderMode.LuminanceOnly)
                {
                    PassGpuTimes.Add(
                        "Analyze ASCII Cells",
                        new MetricSamples()
                    );

                    if (usesAutomaticLuminanceBounds)
                    {
                        AddLuminanceBoundsPasses();
                    }

                    PassGpuTimes.Add(
                        "Render ASCII",
                        new MetricSamples()
                    );
                }
                else if (mode == AsciiBenchmarkRenderMode.EdgeAware)
                {
                    for (
                        int index = 0;
                        index < AsciiGpuPassNames.Length;
                        ++index
                    )
                    {
                        string passName = AsciiGpuPassNames[index];

                        if (passName != "Render ASCII"
                            && (usesAutomaticLuminanceBounds
                                || !IsLuminanceBoundsPass(passName)))
                        {
                            PassGpuTimes.Add(
                                passName,
                                new MetricSamples()
                            );
                        }
                    }
                }
            }


            private void AddLuminanceBoundsPasses()
            {
                PassGpuTimes.Add(
                    SeedLuminanceBoundsPassName,
                    new MetricSamples()
                );
                PassGpuTimes.Add(
                    ReduceLuminanceBoundsPassName,
                    new MetricSamples()
                );
            }


            private static bool IsLuminanceBoundsPass(
                string passName
            )
            {
                return passName == SeedLuminanceBoundsPassName
                    || passName == ReduceLuminanceBoundsPassName;
            }


            public void AddPassGpuTime(
                string passName,
                double milliseconds
            )
            {
                if (!PassGpuTimes.TryGetValue(
                    passName,
                    out MetricSamples samples
                ))
                {
                    return;
                }

                samples.AddIfValid(milliseconds);
            }
        }


        private sealed class PassRecorderSet : IDisposable
        {
            private readonly Dictionary<string, ProfilerRecorder>
                recorders = new();


            public PassRecorderSet(IEnumerable<string> passNames)
            {
                ProfilerRecorderOptions options =
                    ProfilerRecorderOptions.StartImmediately
                    | ProfilerRecorderOptions.WrapAroundWhenCapacityReached
                    | ProfilerRecorderOptions.SumAllSamplesInFrame
                    | ProfilerRecorderOptions.GpuRecorder;

                foreach (string passName in passNames)
                {
                    try
                    {
                        var recorder = new ProfilerRecorder(
                            passName,
                            1,
                            options
                        );

                        if (recorder.Valid)
                        {
                            recorders.Add(passName, recorder);
                        }
                        else
                        {
                            recorder.Dispose();
                        }
                    }
                    catch (Exception)
                    {
                        // GPU marker recording is optional and platform-dependent.
                    }
                }
            }


            public void Collect(ModeResult result)
            {
                foreach (
                    KeyValuePair<string, ProfilerRecorder> entry
                    in recorders
                )
                {
                    long nanoseconds = entry.Value.LastValue;

                    if (nanoseconds <= 0)
                    {
                        continue;
                    }

                    result.AddPassGpuTime(
                        entry.Key,
                        nanoseconds / 1_000_000.0
                    );
                }
            }


            public void Dispose()
            {
                foreach (
                    KeyValuePair<string, ProfilerRecorder> entry
                    in recorders
                )
                {
                    ProfilerRecorder recorder = entry.Value;
                    recorder.Dispose();
                }

                recorders.Clear();
            }
        }


        private sealed class MetricSamples
        {
            private readonly List<double> values = new();

            public int Count => values.Count;


            public void Add(double value)
            {
                values.Add(value);
            }


            public void AddIfValid(double value)
            {
                if (
                    value > 0.0
                    && !double.IsNaN(value)
                    && !double.IsInfinity(value)
                )
                {
                    values.Add(value);
                }
            }


            public MetricStatistics GetStatistics()
            {
                if (values.Count == 0)
                {
                    return MetricStatistics.Unavailable;
                }

                double[] sorted = values.ToArray();
                Array.Sort(sorted);

                double total = 0.0;

                for (int index = 0; index < sorted.Length; ++index)
                {
                    total += sorted[index];
                }

                double median;
                int middle = sorted.Length / 2;

                if (sorted.Length % 2 == 0)
                {
                    median =
                        (sorted[middle - 1] + sorted[middle])
                        * 0.5;
                }
                else
                {
                    median = sorted[middle];
                }

                int p95Index = Math.Clamp(
                    (int)Math.Ceiling(sorted.Length * 0.95) - 1,
                    0,
                    sorted.Length - 1
                );

                return new MetricStatistics(
                    total / sorted.Length,
                    median,
                    sorted[p95Index],
                    sorted.Length
                );
            }
        }


        private readonly struct MetricStatistics
        {
            public static readonly MetricStatistics Unavailable =
                new MetricStatistics(
                    double.NaN,
                    double.NaN,
                    double.NaN,
                    0
                );

            public readonly double Average;
            public readonly double Median;
            public readonly double P95;
            public readonly int Count;

            public bool Available => Count > 0;


            public MetricStatistics(
                double average,
                double median,
                double p95,
                int count
            )
            {
                Average = average;
                Median = median;
                P95 = p95;
                Count = count;
            }
        }


        private readonly struct RankedPass
        {
            public readonly AsciiBenchmarkRenderMode Mode;
            public readonly string Name;
            public readonly double Median;


            public RankedPass(
                AsciiBenchmarkRenderMode mode,
                string name,
                double median
            )
            {
                Mode = mode;
                Name = name;
                Median = median;
            }
        }


        private readonly struct BenchmarkMetadata
        {
            private static readonly int CellWidthId =
                Shader.PropertyToID("_CellWidth");
            private static readonly int CellHeightId =
                Shader.PropertyToID("_CellHeight");
            private static readonly int ColorModeId =
                Shader.PropertyToID("_ColorMode");
            private static readonly int LuminanceMappingModeId =
                Shader.PropertyToID("_LuminanceMappingMode");
            private static readonly int UseManualLuminanceBoundsId =
                Shader.PropertyToID("_UseManualLuminanceBounds");
            private static readonly int GaussianSigmaId =
                Shader.PropertyToID("_GaussianSigma");
            private static readonly int GaussianRadiusId =
                Shader.PropertyToID("_GaussianRadius");
            private static readonly int GaussianScaleId =
                Shader.PropertyToID("_GaussianScale");
            private static readonly int DoGTauId =
                Shader.PropertyToID("_DoGTau");
            private static readonly int DoGThresholdId =
                Shader.PropertyToID("_DoGThreshold");
            private static readonly int MinimumDominantPixelsId =
                Shader.PropertyToID(
                    "_CellEdgeMinimumDominantPixels"
                );
            private static readonly int MinimumDominanceId =
                Shader.PropertyToID(
                    "_CellEdgeMinimumDominance"
                );

            public readonly bool IsEditor;
            public readonly string UnityVersion;
            public readonly string Platform;
            public readonly string OperatingSystem;
            public readonly string Gpu;
            public readonly string GpuVendor;
            public readonly string GraphicsApi;
            public readonly string Resolution;
            public readonly string CellSize;
            public readonly string ColorMode;
            public readonly string LuminanceMapping;
            public readonly double GaussianSigma;
            public readonly int GaussianRadius;
            public readonly double GaussianScale;
            public readonly double DoGTau;
            public readonly double DoGThreshold;
            public readonly double MinimumDominantPixels;
            public readonly double MinimumDominance;
            public readonly double WarmupSeconds;
            public readonly double CaptureSeconds;


            private BenchmarkMetadata(
                Material material,
                float warmupSeconds,
                float captureSeconds
            )
            {
                IsEditor = Application.isEditor;
                UnityVersion = Application.unityVersion;
                Platform = Application.platform.ToString();
                OperatingSystem = SystemInfo.operatingSystem;
                Gpu = SystemInfo.graphicsDeviceName;
                GpuVendor = SystemInfo.graphicsDeviceVendor;
                GraphicsApi =
                    $"{SystemInfo.graphicsDeviceType} - {SystemInfo.graphicsDeviceVersion}";
                Resolution = $"{Screen.width}x{Screen.height}";

                int cellWidth = Mathf.Max(
                    Mathf.RoundToInt(material.GetFloat(CellWidthId)),
                    1
                );
                int cellHeight = Mathf.Max(
                    Mathf.RoundToInt(material.GetFloat(CellHeightId)),
                    1
                );

                CellSize = $"{cellWidth}x{cellHeight}";

                int colorMode = Mathf.RoundToInt(
                    material.GetFloat(ColorModeId)
                );
                ColorMode = colorMode switch
                {
                    1 => "Palette",
                    2 => "Cell Tint",
                    _ => "Monochrome",
                };

                bool usesManualLuminanceBounds =
                    material.GetFloat(UseManualLuminanceBoundsId) > 0.5f;
                bool usesAdaptiveLuminanceMapping =
                    material.GetFloat(LuminanceMappingModeId) > 0.5f;

                LuminanceMapping = usesManualLuminanceBounds
                    ? "Development Manual"
                    : usesAdaptiveLuminanceMapping
                        ? "Adaptive Static Images"
                        : "Stable";

                GaussianSigma = material.GetFloat(GaussianSigmaId);
                GaussianRadius = Mathf.RoundToInt(
                    material.GetFloat(GaussianRadiusId)
                );
                GaussianScale = material.GetFloat(GaussianScaleId);
                DoGTau = material.GetFloat(DoGTauId);
                DoGThreshold = material.GetFloat(DoGThresholdId);
                MinimumDominantPixels = material.GetFloat(
                    MinimumDominantPixelsId
                );
                MinimumDominance = material.GetFloat(
                    MinimumDominanceId
                );
                WarmupSeconds = warmupSeconds;
                CaptureSeconds = captureSeconds;
            }


            public static BenchmarkMetadata Capture(
                Material material,
                float warmupSeconds,
                float captureSeconds
            )
            {
                return new BenchmarkMetadata(
                    material,
                    warmupSeconds,
                    captureSeconds
                );
            }
        }
    }
}
