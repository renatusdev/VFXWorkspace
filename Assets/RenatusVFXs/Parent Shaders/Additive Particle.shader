Shader "Renatus/Additive Particle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR]_Tint ("Tint", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend One One
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Tint;

            struct MeshData
            {
                float4 color : COLOR0;
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolator
            {
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            Interpolator vert (MeshData v)
            {
                Interpolator i;

                i.vertex = UnityObjectToClipPos(v.vertex);
                i.uv = v.uv;
                i.color = v.color;
                
                return i;
            }

            float4 frag (Interpolator i) : SV_Target
            {
                float4 outColor = float4(0,0,0,0);
                outColor += tex2D(_MainTex, i.uv);
                outColor *= i.color;
                outColor *= _Tint;

                return outColor;
            }
            ENDCG
        }
    }
}
