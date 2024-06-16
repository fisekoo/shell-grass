using UnityEngine;
[ExecuteInEditMode]
public class InteractiveRender : MonoBehaviour
{
    [SerializeField] private int resolution = 256;
    private RenderTexture rt;
    private Camera cam;
    void OnEnable()
    {
        rt = CreateRT(resolution);

        cam = GetComponent<Camera>();
        cam.targetTexture = rt;

        Shader.SetGlobalTexture("_GlobalInteractiveRT", rt);
        Shader.SetGlobalFloat("_GlobalEffectCamOrthoSize", cam.orthographicSize);
    }
    private void OnDisable()
    {
        if (rt == null || cam == null) return;

        rt.Release();
        rt = null;
        cam.targetTexture.Release();
        cam.targetTexture = null;

    }
    private RenderTexture CreateRT(int res)
    {
        var rt = new CustomRenderTexture(res, res, RenderTextureFormat.RG16);
        rt.initializationMode = CustomRenderTextureUpdateMode.OnDemand;
        rt.initializationColor = Color.black;
        rt.depthStencilFormat = UnityEngine.Experimental.Rendering.GraphicsFormat.None;
        rt.updateMode = CustomRenderTextureUpdateMode.Realtime;
        rt.filterMode = FilterMode.Bilinear;
        rt.enableRandomWrite = true;
        rt.Create();
        return rt;
    }
    private void OnValidate()
    {
        OnEnable();
    }
    private void OnDestroy()
    {
        OnDisable();
    }
}
