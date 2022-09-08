Shader "Renatus/Scaler"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale ("Scale", Range(-5, 5)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Interpolator
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Scale;

            Interpolator vert (MeshData v)
            {
                Interpolator i;
                // v.vertex.y += _Scale;
                // v.vertex.x = v.normal.x * _Scale;

                i.vertex = UnityObjectToClipPos(v.vertex);
                i.normal = v.normal;
                i.uv = v.uv;

                return i;
            }

            float4 frag (Interpolator i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);

                return float4(i.normal, 1);
            }
            ENDCG
        }
    }
}
