using System.Globalization;

using UnityEngine;


namespace AsciiShader
{
    public sealed class AsciiLuminanceBoundsDiagnostics
        : MonoBehaviour
    {
        [SerializeField]
        private AsciiRendererFeature rendererFeature;

        [SerializeField]
        private bool showOverlay = true;

        private uint observedReportVersion;
        private bool awaitsReport;


        private void Update()
        {
            if (
                !awaitsReport
                || rendererFeature == null
                || rendererFeature.LuminanceBoundsReportVersion
                    == observedReportVersion
            )
            {
                return;
            }

            observedReportVersion =
                rendererFeature.LuminanceBoundsReportVersion;
            awaitsReport = false;

            if (!rendererFeature.HasReportedLuminanceBounds)
            {
                return;
            }

            Vector2 automaticBounds =
                rendererFeature.ReportedLuminanceBounds;

            Material material = rendererFeature.BenchmarkMaterial;

            float manualBlack = material != null
                ? material.GetFloat("_LuminanceBlackPoint")
                : 0.0f;
            float manualWhite = material != null
                ? material.GetFloat("_LuminanceWhitePoint")
                : 1.0f;
            float rangeConfidence = material != null
                ? CalculateRangeConfidence(
                    automaticBounds,
                    material.GetFloat("_GlyphCount")
                )
                : 0.0f;

            Debug.Log(
                "ASCII luminance bounds - detected: "
                + Format(automaticBounds.x)
                + " to "
                + Format(automaticBounds.y)
                + " (range "
                + Format(automaticBounds.y - automaticBounds.x)
                + "); manual: "
                + Format(manualBlack)
                + " to "
                + Format(manualWhite)
                + "; automatic safety: "
                + GetSafetyLabel(rangeConfidence)
                + " ("
                + Format(rangeConfidence * 100.0f)
                + "%)"
                + "."
            );
        }


        private void OnGUI()
        {
            if (!showOverlay || rendererFeature == null)
            {
                return;
            }

            const float width = 370.0f;
            const float height = 205.0f;
            const float margin = 16.0f;

            float x = Mathf.Max(
                Screen.width - width - margin,
                margin
            );

            GUILayout.BeginArea(
                new Rect(x, margin, width, height),
                GUI.skin.box
            );

            GUILayout.Label("ASCII Luminance Bounds");

            Material material = rendererFeature.BenchmarkMaterial;

            if (material == null)
            {
                GUILayout.Label("Renderer material is unavailable.");
                GUILayout.EndArea();
                return;
            }

            float manualBlack =
                material.GetFloat("_LuminanceBlackPoint");
            float manualWhite =
                material.GetFloat("_LuminanceWhitePoint");
            bool usesManualDevelopmentBounds =
                material.GetFloat(
                    "_UseManualLuminanceBounds"
                ) > 0.5f;
            bool usesAdaptiveStaticMapping =
                material.GetFloat(
                    "_LuminanceMappingMode"
                ) > 0.5f;

            string activeSource = usesManualDevelopmentBounds
                ? "Development manual"
                : usesAdaptiveStaticMapping
                    ? "Adaptive static image"
                    : "Stable";

            GUILayout.Label(
                "Active source: "
                + activeSource
            );

            GUILayout.Label(
                "Development manual: "
                + Format(manualBlack)
                + " to "
                + Format(manualWhite)
                + "  (range "
                + Format(manualWhite - manualBlack)
                + ")"
            );

            if (rendererFeature.HasReportedLuminanceBounds)
            {
                Vector2 automaticBounds =
                    rendererFeature.ReportedLuminanceBounds;

                float rangeConfidence =
                    CalculateRangeConfidence(
                        automaticBounds,
                        material.GetFloat("_GlyphCount")
                    );

                GUILayout.Label(
                    "Detected: "
                    + Format(automaticBounds.x)
                    + " to "
                    + Format(automaticBounds.y)
                    + "  (range "
                    + Format(
                        automaticBounds.y
                        - automaticBounds.x
                    )
                    + ")"
                );

                GUILayout.Label(
                    "Automatic safety: "
                    + GetSafetyLabel(rangeConfidence)
                    + "  ("
                    + Format(rangeConfidence * 100.0f)
                    + "%)"
                );
            }
            else
            {
                GUILayout.Label("Detected: not captured yet");
            }

            GUILayout.Space(8.0f);

            GUI.enabled = !awaitsReport;

            if (
                GUILayout.Button(
                    awaitsReport
                        ? "Waiting for GPU..."
                        : "Capture Current Bounds"
                )
            )
            {
                observedReportVersion =
                    rendererFeature.LuminanceBoundsReportVersion;
                awaitsReport = true;
                rendererFeature.RequestLuminanceBoundsReport();
            }

            GUI.enabled = true;

            GUILayout.Label(
                "Capture is asynchronous and diagnostic-only."
            );

            GUILayout.EndArea();
        }


        private static string Format(float value)
        {
            return value.ToString(
                "F4",
                CultureInfo.InvariantCulture
            );
        }


        private static float CalculateRangeConfidence(
            Vector2 bounds,
            float configuredGlyphCount
        )
        {
            float glyphCount = Mathf.Max(
                Mathf.Round(configuredGlyphCount),
                2.0f
            );

            float oneGlyphStep = 1.0f / glyphCount;
            float detectedRange = Mathf.Max(
                bounds.y - bounds.x,
                0.0f
            );

            float transition = Mathf.Clamp01(
                (detectedRange - oneGlyphStep)
                / oneGlyphStep
            );

            return transition
                * transition
                * (3.0f - 2.0f * transition);
        }


        private static string GetSafetyLabel(float confidence)
        {
            if (confidence <= 0.001f)
            {
                return "Suppressed";
            }

            if (confidence >= 0.999f)
            {
                return "Fully active";
            }

            return "Partially active";
        }
    }
}
