Shader "Renatus/Fresnel"
{
    Properties
    {
        [HDR]_Tint ("Tint", Color) = (1,1,1,1)
        _Power ("Fresnel Power", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Geometry"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Fresnel.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Tint;
            float _Power;

            struct MeshData
            {
                float4 color : COLOR0;
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Interpolator
            {
                float4 vertex   : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float4 color    : TEXCOORD1;
                float3 normal   : TEXCOORD2;
                float3 world    : TEXCOORD3;
            };

            Interpolator vert (MeshData v)
            {
                Interpolator i;

                i.vertex = UnityObjectToClipPos(v.vertex);
                i.world = mul(unity_ObjectToWorld, v.vertex);
                i.uv = v.uv;
                i.color = v.color;
                i.normal = UnityObjectToWorldNormal(v.normal);
        
                return i;
            }

            float4 frag (Interpolator i) : SV_Target
            {
                float4 outColor = float4(0,0,0,0);
                outColor *= i.color;
                outColor += Fresnel(i.world, i.normal, _Power);;                
                outColor *= _Tint;

                return outColor;
            }
            ENDCG
        }
    }
}
