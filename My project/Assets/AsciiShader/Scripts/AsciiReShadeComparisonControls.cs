using UnityEngine;

namespace AsciiShader
{
    public sealed class AsciiReShadeComparisonControls
        : MonoBehaviour
    {
        [SerializeField]
        private AsciiRendererFeature rendererFeature;

        [SerializeField]
        private bool startWithRawUnityOutputInPlayer = true;

        [SerializeField]
        private bool showOverlay = true;

        [SerializeField]
        private KeyCode toggleKey = KeyCode.F2;

        private bool unityAsciiEnabled;


        private void OnEnable()
        {
            unityAsciiEnabled = Application.isEditor
                || !startWithRawUnityOutputInPlayer;

            ApplyMode();
        }


        private void OnDisable()
        {
            rendererFeature?.SetHostRenderingDisabled(false);
        }


        private void OnGUI()
        {
            Event guiEvent = Event.current;

            if (
                guiEvent.type == EventType.KeyDown
                && guiEvent.keyCode == toggleKey
            )
            {
                ToggleMode();
                guiEvent.Use();
            }

            if (!showOverlay)
            {
                return;
            }

            const float panelWidth = 285f;
            const float panelHeight = 78f;

            GUILayout.BeginArea(
                new Rect(
                    10f,
                    Screen.height - panelHeight - 10f,
                    panelWidth,
                    panelHeight
                ),
                GUI.skin.box
            );

            GUILayout.Label(
                unityAsciiEnabled
                    ? "Unity output: ASCII"
                    : "Unity output: Raw"
            );

            if (
                GUILayout.Button(
                    $"Toggle Unity ASCII ({toggleKey})"
                )
            )
            {
                ToggleMode();
            }

            GUILayout.EndArea();
        }


        private void ToggleMode()
        {
            unityAsciiEnabled = !unityAsciiEnabled;
            ApplyMode();
        }


        private void ApplyMode()
        {
            rendererFeature?.SetHostRenderingDisabled(
                !unityAsciiEnabled
            );
        }
    }
}
