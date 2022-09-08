Shader "Renatus/Stained Glass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _Tint ("Tint",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Assets\RenatusVFXs\Parent Shaders\Noise.cginc"

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolator
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Tint;

            Interpolator vert (MeshData v)
            {
                Interpolator i;
                i.vertex = UnityObjectToClipPos(v.vertex);
                i.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return i;
            }

            float3 rgb(float value)
            {
                float r = sin(tan(value) * 43758.5453);
                float g = cos(atan(value) * 95294.9823);
                float b = sin(tan(value) * 89462.3412);

                return float3(r,g,b);
            }

            float4 frag (Interpolator i) : SV_Target
            {
                float voronoi = 0;
                float cells = 0;

                VoronoiNoise(i.uv, 35, 5, voronoi, cells); 

                return float4(rgb(cells), 1);
            }
            
            ENDCG
        }
    }
}
