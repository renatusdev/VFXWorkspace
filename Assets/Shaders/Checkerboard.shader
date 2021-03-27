Shader "Renatus/Checkerboard"
{
    Properties
    {
        _ColorA("Color A", Color) = (1,1,1,1)
        _ColorB("Color B", Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "PreviewType"="Plane" "RenderPipeline" = "LightweightPipeline"}

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"
            
            float3 _ColorA;
            float3 _ColorB;

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Interpolator
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 world : TEXCOORD2;
            };

            Interpolator vert (MeshData v)
            {
                Interpolator i;
                i.normal = UnityObjectToWorldNormal(v.normal);
                i.world = mul (UNITY_MATRIX_M, v.vertex);
                i.vertex = UnityObjectToClipPos(v.vertex);
                return i;
            }

            // https://docs.unity3d.com/Packages/com.unity.shadergraph@6.9/manual/Checkerboard-Node.html
            float3 Checkerboard(float2 UV, float3 ColorA, float3 ColorB, float2 Frequency)
            {
                UV = (UV.xy + 0.5) * Frequency;
                float4 derivatives = float4(ddx(UV), ddy(UV));
                float2 duv_length = sqrt(float2(dot(derivatives.xz, derivatives.xz), dot(derivatives.yw, derivatives.yw)));
                float width = 1.0;
                float2 distance3 = 4.0 * abs(frac(UV + 0.25) - 0.5) - width;
                float2 scale = 0.35 / duv_length.xy;
                float freqLimiter = sqrt(clamp(1.1f - max(duv_length.x, duv_length.y), 0.0, 1.0));
                float2 vector_alpha = clamp(distance3 * scale.xy, -1.0, 1.0);
                float alpha = saturate(0.5f + 0.5f * vector_alpha.x * vector_alpha.y * freqLimiter);
                
                return lerp(ColorA, ColorB, alpha.xxx);
            }

            float4 frag (Interpolator i) : SV_Target
            {
                float3 checkerboardXZ = Checkerboard(i.world.xz, _ColorA, _ColorB, 1);
                float3 checkerboardYZ = Checkerboard(i.world.yz, _ColorA, _ColorB, 1);
                
                float3 outColor = float3(0,0,0);

                outColor += checkerboardXZ * (1-i.normal.x);
                outColor += checkerboardYZ * (1-i.normal.y);

                return float4(outColor, 1);
            }
            ENDCG
        }
    }
}
