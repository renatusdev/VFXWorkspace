Shader "Renatus/Stencil Object"
{
    Properties
    {
        _StencilMask ("Stencil Mask", Int) = 1
        _Tint ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "ForceNoShadowCasting"="True" }

        Stencil
        {
            Ref [_StencilMask]
            Comp Equal
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _Tint;

            struct MeshData
            {
                float4 vertex : POSITION;
            };

            struct Interpolator
            {
                float4 vertex : SV_POSITION;
            };


            Interpolator vert (MeshData v)
            {
                Interpolator i;
                i.vertex = UnityObjectToClipPos(v.vertex);
                return i;
            }

            float4 frag (Interpolator i) : SV_Target
            {
                float4 outColor = 0;


                outColor *= -_Tint;

                return _Tint;
            }

            ENDCG
        }
    }
}
