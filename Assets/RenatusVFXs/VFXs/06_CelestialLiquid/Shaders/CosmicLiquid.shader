Shader "Renatus/CosmicLiquid"
{
    Properties
    {
        _CosmicField ("Cosmic Field", 2D) = "white" {}
        _StarMap ("Star Map", 2D) = "white" {}
        _BlackHole ("BlackHole", 2D) = "white" {}
        [HDR] _LiquidColor("Liquid Color", Color) = (1,1,1,1)
        [HDR] _FoamColor ("Foam Color", Color) = (1,1,1,1)
        [HDR] _EdgeRingColor ("Edge Ring Color", Color) = (1,1,1,1)
        [HDR] _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        _ScreenTextureSize ("Screen Texture Size", Range(0, 1)) = 0.5
        _FillAmount ("Fill Amount", Range(0, 1)) = 0.4
        _FoamWidth ("Foam Width", Range(0, 1)) = 0.5
        _FresnelPower ("Frensel Power", Range(0, 1)) = 0.5
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

            sampler2D _CosmicField;
            sampler2D _StarMap;
            float4 _FresnelColor;
            float4  _LiquidColor;
            float4 _EdgeRingColor;
            float _FresnelPower;
            float _FoamWidth;
            float _FillAmount;
            float _ScreenTextureSize;

            
            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Interpolator
            {
                float4 vertex   : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float4 screen   : TEXCOORD1;
                float3 normal   : TEXCOORD2;
                float3 world    : TEXCOORD3;
            };


            Interpolator vert (MeshData v)
            {
                Interpolator i;

                i.vertex    = UnityObjectToClipPos(v.vertex);
                i.uv        = v.uv;
                i.screen    = ComputeScreenPos(i.vertex);
                i.normal    = UnityObjectToWorldNormal(v.normal);
                i.world     = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                return i;
            }

            float4 frag (Interpolator i) : SV_Target
            {
                float4 outColor = float4(0,0,0,0);

                ///////////////////// Liquid Effect /////////////////////

                // World position of current fragment
                float fragWorldY = i.world.y;

                // World position of the objects' center
                float centerWorldY = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).y;
                float distanceFromFragToCenter = fragWorldY - centerWorldY;

                // Amount to fill                
                // float t = sin(_Time.y * 0.75) * 0.025;
                float fill = ((_FillAmount) * 2 - 1);
                
                // Mask creations
                float liquidMask = step(distanceFromFragToCenter, fill);
                float edgeRingMask = step(distanceFromFragToCenter, fill+(_FoamWidth * 0.2)) - liquidMask;

                // // Adding Color
                // float4 liquid =  _LiquidColor * liquidMask;
                // float4 edgeRing = _EdgeRingColor * foamMask;
                
                // Adding Fresnel
                float fresnelMask = pow(saturate(1-dot(normalize(_WorldSpaceCameraPos - i.world), normalize(i.normal))), (1-_FresnelPower) * 8);
                float4 fresnel = fresnelMask * _FresnelColor;
                fresnel *= (liquidMask + edgeRingMask);

                // outColor += liquid;
                // outColor += edgeRing;
                // outColor += fresnel;
                //////////////////////////////////////////////////////////

                /////////////////// Cosmic Texturing /////////////////////

                // Map Screen UVs to textures (with liquid mask).
                float2 screenUV = (i.screen.xy/i.screen.w) * (_ScreenTextureSize * 3)  + (_Time.y * 0.01); // +(i.screen.x * 0.25);
                float4 cosmicSample = tex2D(_CosmicField, screenUV) * (liquidMask + edgeRingMask);
                float4 cosmicLiquid = cosmicSample * liquidMask* _LiquidColor;
                float4 cosmicEdgeRing = cosmicSample * edgeRingMask * _EdgeRingColor;

                float starMap = tex2D(_StarMap, screenUV).r * (liquidMask + edgeRingMask);

                // cosmicField += starMap;
                outColor += cosmicLiquid;
                outColor += cosmicEdgeRing;
                outColor += starMap;
                outColor += fresnel;
                
                return outColor;
                //////////////////////////////////////////////////////////
                
                return outColor;
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

            sampler2D _BlackHole;
            float4 _FoamColor;
            float _FoamWidth;
            float _FillAmount;
            float _ScreenTextureSize;

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
                float4 screen : TEXCOORD2;
            };

            Interpolator vert (MeshData v)
            {
                Interpolator o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.world = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.screen = ComputeScreenPos(o.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolator i) : SV_Target
            {
                float4 outColor = float4(0,0,0,0);

                // World position of current fragment
                float fragWorldY = i.world.y;

                // World position of the objects' center
                float centerWorldY = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).y;
                float distanceFromFragToCenter = fragWorldY - centerWorldY;

                // Amount to fill                
                // float t = sin(_Time.y * 0.75) * 0.025;
                float fill = ((_FillAmount) * 2 - 1);
                
                // Mask creations
                float liquidMask = step(distanceFromFragToCenter, fill);
                float edgeRingMask = step(distanceFromFragToCenter, fill+(_FoamWidth * 0.2)) - liquidMask;

                /////////////////// Cosmic Texturing /////////////////////

                // Map Screen UVs to textures (with liquid mask).
                float2 screenUV = (i.screen.xy/i.screen.w) * (_ScreenTextureSize * 6)  + (_Time.y * 0.01);
                float blackHole = tex2D(_BlackHole, screenUV).r * (liquidMask + edgeRingMask);
                
                outColor += (liquidMask + edgeRingMask) * _FoamColor;
                outColor += blackHole * 0.4;

                return outColor;
                //////////////////////////////////////////////////////////
            }

            ENDCG
        }
    }
}

