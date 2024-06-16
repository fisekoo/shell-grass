struct DrawVertex
{
    float3 position;
    float3 normal;
    float2 uv;
    float1 height;
};
struct DrawTriangle{
    DrawVertex vertices[3];
};