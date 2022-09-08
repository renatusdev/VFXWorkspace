Shader "Renatus/Stencil Mask"
{
    Properties
    {
        _StencilMask ("Stencil Mask", Int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry-100" "ForceNoShadowCasting"="True" }
        ColorMask 0
        ZWrite Off

        Stencil
        {
            Ref [_StencilMask]
            Pass Replace
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolator
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };


            Interpolator vert (MeshData v)
            {
                Interpolator i;
                i.vertex = UnityObjectToClipPos(v.vertex);
                i.uv = v.uv;
                return i;
            }

            float4 frag (Interpolator i) : SV_Target
            {
                return 1;
            }

            ENDCG
        }
    }
}
