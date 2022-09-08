Shader "Renatus/Liquid"
{
    Properties
    {
        [HDR]_LiquidColor("Liquid Color", Color) = (1,1,1,1)
        [HDR] _FoamColor ("Foam Color", Color) = (1,1,1,1)
        [HDR] _EdgeRingColor ("Edge Ring Color", Color) = (1,1,1,1)
        [HDR] _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        _FillAmount ("Fill Amount", Range(0, 1)) = 0.4
        _FoamWidth ("Foam Width", Range(0, 1)) = 0.5
        _FresnelPower ("Fresnel", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            Tags {"LightMode"="UniversalForward"}

            Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _LiquidColor;
            float4 _EdgeRingColor;
            float4 _FresnelColor;
            float _FoamWidth;
            float _FillAmount;
            float _FresnelPower;

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Interpolator
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 world : TEXCOORD1;
                float3 normal : TEXCOORD2;
            };

            Interpolator vert (MeshData v)
            {
                Interpolator o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.world = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolator i, fixed facing : VFACE) : SV_Target
            {                
                // World position of current fragment
                float fragWorldY = i.world.y;

                // World position of the objects' center
                float centerWorldY = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).y;
                float distanceFromFragToCenter = fragWorldY - centerWorldY;

                // Amount to fill                
                float t = sin(_Time.y * 0.75) * 0.05;
                float fill = ((_FillAmount + t) * 2 - 1);
                
                // Mask creations
                float liquidMask = step(distanceFromFragToCenter, fill);
                float foamMask = step(distanceFromFragToCenter, fill+(_FoamWidth * 0.2)) - liquidMask;

                // Adding Color
                float4 liquid = _LiquidColor * liquidMask;
                float4 foam = _EdgeRingColor * foamMask;
                
                // Adding Fresnel
                float fresnelAnimation = 1 - (_FresnelPower * (sin(_Time.y) * 0.3) + 0.4); 
                float fresnelMask = pow(saturate(1-dot(normalize(_WorldSpaceCameraPos - i.world), normalize(i.normal))), (1-fresnelAnimation) * 8);
                float4 fresnel = fresnelMask * liquidMask * _FresnelColor;

                return liquid + foam + fresnel;
            }

            ENDCG
        }

        Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _LiquidColor;
            float4 _FoamColor;
            float _FoamWidth;
            float _FillAmount;

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

            float4 frag (Interpolator i) : SV_Target
            {
                // World position of current fragment
                float fragWorldY = i.world.y;

                // World position of the objects' center
                float centerWorldY = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).y;
                float distanceFromFragToCenter = fragWorldY - centerWorldY;

                // Amount to fill                
                float t = sin(_Time.y * 0.75) * 0.05;
                float fill = ((_FillAmount + t) * 2 - 1);
                
                // Mask creations
                float liquidMask = step(distanceFromFragToCenter, fill);
                float foamMask = step(distanceFromFragToCenter, fill+(_FoamWidth * 0.2)) - liquidMask;

                return (liquidMask + foamMask)* _FoamColor;
            }

            ENDCG
        }
    }
}