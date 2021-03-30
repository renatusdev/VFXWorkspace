Shader "Renatus/Liquid"
{
    Properties
    {
        [HDR]_LiquidColor("Liquid Color", Color) = (1,1,1,1)
        [HDR] _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _FillAmount ("Fill Amount", Range(0, 1)) = 0.4
        _FoamWidth ("Foam Width", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _LiquidColor;
            float4 _FoamColor;
            float _FillAmount;
            float _FoamWidth;

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolator
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 world : TEXCOORD1;
            };

            Interpolator vert (MeshData v)
            {
                Interpolator o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.world = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolator i, fixed facing : VFACE) : SV_Target
            {
                float fragWorldY = i.world.y;
                float centerWorldY = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).y;
                float distanceFromFragToCenter = fragWorldY - centerWorldY;
                float fill = ( _FillAmount * 2 - 1);
                float liquidMask = step(distanceFromFragToCenter, fill);
                float foamMask = step(distanceFromFragToCenter, fill+(_FoamWidth * 0.2)) - liquidMask;

                float4 liquid = _LiquidColor * liquidMask;
                float4 foam = _FoamColor * foamMask;
                
                return liquid + foam;
            }

            ENDCG
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
                Interpolator o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolator i, fixed facing : VFACE) : SV_Target
            {
                return 1;
            }

            ENDCG
        }
    }
}