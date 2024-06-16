using System;
using System.Runtime.InteropServices;
using UnityEngine;
[ExecuteInEditMode]
[RequireComponent(typeof(MeshFilter))]
public class ShellGrass : MonoBehaviour
{
    public struct ShellShaderProperties
    {
        public static int SourceVertices { get => Shader.PropertyToID("_InputVertices"); private set { } }
        public static int SourceTriangles { get => Shader.PropertyToID("_InputTriangles"); private set { } }
        public static int DrawTriangles { get => Shader.PropertyToID("_DrawTriangles"); private set { } }
        public static int IndirectArgs { get => Shader.PropertyToID("_IndirectArgs"); private set { } }
        public static int LODMin { get => Shader.PropertyToID("_LODMin"); private set { } }
        public static int LODMax { get => Shader.PropertyToID("_LODMax"); private set { } }
        public static int LODFactor { get => Shader.PropertyToID("_LODFactor"); private set { } }
        public static int CamPos { get => Shader.PropertyToID("_CamPos"); private set { } }
        public static int TriangleCount { get => Shader.PropertyToID("_TriangleCount"); private set { } }
        public static int Layers { get => Shader.PropertyToID("_Layers"); private set { } }
        public static int Height { get => Shader.PropertyToID("_Offset"); private set { } }
        public static int LocalToWorld { get => Shader.PropertyToID("_LocalToWorld"); private set { } }
        public static int WindMap { get => Shader.PropertyToID("_WindMap"); private set { } }
        public static int Amplitude { get => Shader.PropertyToID("_Amplitude"); private set { } }
        public static int Frequency { get => Shader.PropertyToID("_Frequency"); private set { } }
        public static int Time { get => Shader.PropertyToID("_Time"); private set { } }
    }
    [Serializable, StructLayout(LayoutKind.Sequential)]
    public struct InputVertex
    {
        public Vector3 position;
        public Vector3 normal;
        public Vector2 uv;
    }
    [Header("Render")]
    // for gameobject instances
    //private ComputeShader shellGrassCompute;
    //private Material shellMaterial;
    [SerializeField] private ComputeShader shellGrassCompute;
    [SerializeField] private Material shellMaterial;
    [Min(1)][SerializeField] private int layers = 1;
    [SerializeField][Range(0f, 1f)] private float height;
    [SerializeField] private bool castShadows = false;

    [Header("LOD")]
    [SerializeField] private Vector2 LOD_DistanceMinMax = new Vector2(0, 10);
    [SerializeField][Min(0.5f)] private float LOD_Factor = 1;

    // Compute Shader
    private int idGrassKernel, grassThreadGroupSize;

    // Buffers
    private GraphicsBuffer inputVertBuffer;
    private GraphicsBuffer inputTrianglesBuffer;
    private GraphicsBuffer drawTrianglesBuffer;
    private GraphicsBuffer indirectArgsBuffer;

    // Strides
    private const int INPUT_VERTICES_STRIDE = (3 + 3 + 2) * sizeof(float);
    private const int INPUT_TRIANGLES_STRIDE = sizeof(int);
    private const int DRAW_TRIANGLES_STRIDE = (3 * (3 + 3 + 2)) * sizeof(float);
    private const int INDIRECT_ARGS_STRIDE = 4 * sizeof(int);
    private int[] indirectArgs = new int[] { 0, 1, 0, 0 };

    // Mesh
    private Mesh mesh;
    private MeshRenderer meshRenderer;
    private int triangleCount;
    private bool initialized;
    private void OnEnable()
    {
        mesh = GetComponent<MeshFilter>().sharedMesh;
        meshRenderer = GetComponent<MeshRenderer>();
        meshRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;

        triangleCount = (int)mesh.GetIndexCount(0) / 3;
        //CreateInstance();
        SetupBuffers();
        SetupData();
        SendData();
    }
    private void OnDisable()
    {
        ReleaseBuffers();
        //DestroyInstances();
    }
    private void OnValidate()
    {
        initialized = false;

        SetupBuffers();
        SetupData();
        SendData();
    }
    private void SetupBuffers()
    {
        if (triangleCount <= 0) return;

        inputVertBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, mesh.vertices.Length, INPUT_VERTICES_STRIDE);
        inputTrianglesBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, triangleCount * 3, INPUT_TRIANGLES_STRIDE);
        drawTrianglesBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Append, triangleCount * layers, DRAW_TRIANGLES_STRIDE);
        indirectArgsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, 1, INDIRECT_ARGS_STRIDE);
    }

    private void SetupData()
    {
        if (mesh == null || shellGrassCompute == null) return;

        idGrassKernel = shellGrassCompute.FindKernel("ShellGrass");
        shellGrassCompute.GetKernelThreadGroupSizes(idGrassKernel, out uint threadGroupSizeX, out _, out _);
        grassThreadGroupSize = Mathf.CeilToInt((float)triangleCount / threadGroupSizeX);

        Vector3[] positions = mesh.vertices;
        Vector3[] normals = mesh.normals;
        Vector2[] uvs = mesh.uv;

        InputVertex[] vertices = new InputVertex[positions.Length];
        for (int i = 0; i < vertices.Length; i++)
        {
            vertices[i] = new InputVertex
            {
                position = positions[i],
                normal = normals[i],
                uv = uvs[i]
            };
        }
        inputVertBuffer.SetData(vertices);
        inputTrianglesBuffer.SetData(mesh.triangles);
        drawTrianglesBuffer.SetCounterValue(0);
        indirectArgsBuffer.SetData(indirectArgs);
    }
    private void SendData()
    {
        if (mesh == null || shellGrassCompute == null || shellMaterial == null) return;
        // Buffers
        shellGrassCompute.SetBuffer(idGrassKernel, ShellShaderProperties.SourceVertices, inputVertBuffer);
        shellGrassCompute.SetBuffer(idGrassKernel, ShellShaderProperties.SourceTriangles, inputTrianglesBuffer);
        shellGrassCompute.SetBuffer(idGrassKernel, ShellShaderProperties.DrawTriangles, drawTrianglesBuffer);
        shellGrassCompute.SetBuffer(idGrassKernel, ShellShaderProperties.IndirectArgs, indirectArgsBuffer);
        shellMaterial.SetBuffer(ShellShaderProperties.DrawTriangles, drawTrianglesBuffer);

        // LOD props
        shellGrassCompute.SetFloat(ShellShaderProperties.LODMin, LOD_DistanceMinMax.x);
        shellGrassCompute.SetFloat(ShellShaderProperties.LODMax, LOD_DistanceMinMax.y);
        shellGrassCompute.SetFloat(ShellShaderProperties.LODFactor, LOD_Factor);
        shellGrassCompute.SetVector(ShellShaderProperties.CamPos, Camera.main.transform.position);


        // Other props
        shellGrassCompute.SetInt(ShellShaderProperties.TriangleCount, triangleCount);
        shellGrassCompute.SetInt(ShellShaderProperties.Layers, layers);
        shellGrassCompute.SetFloat(ShellShaderProperties.Height, height);
        shellGrassCompute.SetMatrix(ShellShaderProperties.LocalToWorld, transform.localToWorldMatrix);
        shellMaterial.SetMatrix(ShellShaderProperties.LocalToWorld, transform.localToWorldMatrix);

        shellGrassCompute.Dispatch(idGrassKernel, grassThreadGroupSize, 1, 1);

        initialized = true;
    }
    private void Update()
    {
        if (!initialized) return;
        Graphics.DrawProceduralIndirect(
            shellMaterial,
            meshRenderer.bounds, // Bounds isn't correct, update if you are having culling issues
            MeshTopology.Triangles,
            indirectArgsBuffer,
            castShadows: castShadows ? UnityEngine.Rendering.ShadowCastingMode.On : UnityEngine.Rendering.ShadowCastingMode.Off,
            layer: gameObject.layer
        );
    }
    private void ReleaseBuffers()
    {
        ReleaseBuffer(ref inputVertBuffer);
        ReleaseBuffer(ref inputTrianglesBuffer);
        ReleaseBuffer(ref drawTrianglesBuffer);
        ReleaseBuffer(ref indirectArgsBuffer);
    }
    private void ReleaseBuffer(ref GraphicsBuffer buffer)
    {
        if (buffer == null) return;
        buffer.Release();
        buffer = null;
    }
    private void CreateInstance()
    {
        if (shellGrassCompute == null || shellMaterial == null) return;
        shellGrassCompute = Instantiate(shellGrassCompute);
        shellMaterial = Instantiate(shellMaterial);
    }
    private void DestroyInstances()
    {
        if (shellGrassCompute == null || shellMaterial == null) return;
        if (Application.isPlaying)
        {
            Destroy(shellGrassCompute);
            Destroy(shellMaterial);
        }
        else
        {
            DestroyImmediate(shellGrassCompute);
            DestroyImmediate(shellMaterial);
        }
    }
}
