float Fresnel(float3 world, float3 normal, float power)
{    
    return pow(saturate(1-dot(normalize(_WorldSpaceCameraPos - world), normalize(normal))), (1-power) * 8);
}