using UnityEngine;

namespace AsciiShader
{
    public sealed class SlowRotator : MonoBehaviour
    {
        [SerializeField]
        private Vector3 degreesPerSecond = new(0f, 18f, 0f);

        private void Update()
        {
            transform.Rotate(degreesPerSecond * Time.deltaTime, Space.World);
        }
    }
}
