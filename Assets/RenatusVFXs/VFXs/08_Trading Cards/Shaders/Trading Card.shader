Shader "Renatus/Trading Card"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}

        [Header(Colors)]
        
        [HDR]_FrameColor ("Frame", Color) = (1,1,1,1)
        [HDR]_CornerColor ("Corner", Color) = (1,1,1,1)
        [HDR]_StarColor ("Stars", Color) = (1,1,1,1)
        [HDR]_DivisionLineColor ("Division Line", Color) = (1,1,1,1)
        [HDR]_TangentLightColor ("Tangent Color", Color) = (1,1,1,1)
        [HDR]_BackgroundColorA ("Background A", Color) = (1,1,1,1)
        [HDR]_BackgroundColorB ("Background B", Color) = (1,1,1,1)
        
        [Header(Shapes And Sizes)]
        
        _FrameSize ("Frame Size", Range(0,1)) = 0.5
        _DivisionLineSize ("Division Line Size", Range(0, 1)) = 0.5
        _DivisionLineY ("Division Line Y", Range(0, 1)) = 0.5
        _BackgroundPower ("Background Power", Range(0, 1)) = 1
        _BackgroundOffsetX ("Background Offset X", Range(0, 1)) = 0
        _BackgroundOffsetY ("Background Offset Y", Range(0, 1)) = 1
        
        [Header(Card Effects)]
        _StarAmount ("Star Amount", Range(0, 1)) = 0.3
        _TangentLightInclination ("Tangent Light Inclination", Range(-1,1)) = 0.4
        _TangentLightStep ("Tangent Light Step", Range(0, 1)) = 0.8
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

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
            #include "Assets\RenatusVFXs\Parent Shaders\Noise.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            float4 _FrameColor;
            float4 _CornerColor;
            float4 _StarColor;
            float4 _DivisionLineColor;
            float4 _TangentLightColor;
            float4 _BackgroundColorA;
            float4 _BackgroundColorB;
            
            float _FrameSize;
            float _DivisionLineSize;
            float _DivisionLineY;
            float _BackgroundPower;
            float _BackgroundOffsetX;
            float _BackgroundOffsetY;

            float _StarAmount;
            float _TangentLightInclination;
            float _TangentLightStep;

            struct MeshData
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Interpolator
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 tangent : TEXCOORD1;
                float3 viewDirection : TEXCOORD3;
            };


            Interpolator vert (MeshData v)
            {
                Interpolator i;

                i.vertex = UnityObjectToClipPos(v.vertex);
                i.uv = v.uv;

                float4 localCamPosition = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                i.viewDirection = i.vertex - localCamPosition;
                float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                float3 bitangent = cross(v.normal, v.tangent.xyz) * tangentSign;
                
                i.tangent = float3
                (
                    dot(i.viewDirection, v.tangent.xyz),
                    dot(i.viewDirection, bitangent.xyz),
                    dot(i.viewDirection, v.normal)
                );
                
                return i;
            }

            float Star(float2 uv,float size, float mass)
            {
                float2 k1 = float2(0.809016994375, -0.587785252292);
                float2 k2 = float2(-k1.x,k1.y);
                uv.x = abs(uv.x);
                uv -= 2.0*max(dot(k1,uv),0.0)*k1;
                uv -= 2.0*max(dot(k2,uv),0.0)*k2;
                uv.x = abs(uv.x);
                uv.y -= size;
                float2 ba = mass*float2(-k1.y,k1.x) - float2(0,1);
                float h = clamp( dot(uv,ba)/dot(ba,ba), 0.0, size);
                return length(uv-ba*h) * sign(uv.y*ba.x-uv.x*ba.y);
            }

            float4 frag (Interpolator i) : SV_Target
            {
                float4 outColor = 0;

                /////////////// Frames & Corners ///////////////                
                float2 rectangle = abs(i.uv * 2 - 1) - float2(0.90 + ((1-_FrameSize)*0.08), 0.90 + ((1-_FrameSize)*0.08));
                rectangle = step(0, rectangle);

                float frame = saturate((rectangle.x + rectangle.y));
                float corners = rectangle.x * rectangle.y;
                float divisionLine = step(distance(i.uv.y, _DivisionLineY), _DivisionLineSize * 0.05);
                frame -= corners;
                divisionLine -= frame;
                divisionLine -= corners;
                divisionLine = saturate(divisionLine);
                ////////////////////////////////////////////////    

                //////////////////// Stars /////////////////////
                // Generate grid of uvs
                float2 starGridUV = float2(i.uv.x+0.035, i.uv.y+0.045) * 15;
                starGridUV = frac(starGridUV) * 2 - 1;
                // return float4(starGridUV, 0, 1);
                // Generate star shape based on uv
                float stars = 1-step(0.01, Star(starGridUV, 0.6, 0.6));
                // Generate the vertical mask for the star header 
                float starMask = step(0.975, 1-distance(i.uv.y, 0.85));
                // Generate the Horizontal mask for the star header
                starMask *=  1-step(_StarAmount, (i.uv.x <= 0.026 ? 1 : i.uv.x) + 0.026);
                // Add the mask to the grid of stars.
                stars *= starMask;
                ////////////////////////////////////////////////

                /////////////// Background Color ///////////////
                float gradient = saturate(pow(distance(float2(_BackgroundOffsetX, _BackgroundOffsetY), i.uv), 8 * _BackgroundPower));
                float4 backgroundColor = lerp(_BackgroundColorA, _BackgroundColorB, gradient); 
                backgroundColor -= frame;
                backgroundColor -= corners;
                backgroundColor -= divisionLine;
                backgroundColor -= stars;
                backgroundColor = saturate(backgroundColor);
                ///////////////////////////////////////////////
                
                //////// Holographic Sparkles & Lights ////////

                float tangentMask = 1-saturate(((i.uv.y * (_TangentLightInclination * 5)) + (i.tangent.x)) * i.tangent.x);
                float tangentLight = smoothstep(_TangentLightStep, 1, tangentMask);

                float2 voronoi; VoronoiNoise(i.uv, 69, 20, voronoi.x, voronoi.y);

                // Converting voronoi to HSV value (which will be used as direction).
                float3 rndDir = saturate(float3(abs(voronoi.y * 6 - 3) - 1,
                                        2 - abs(voronoi.y * 6 - 2),
                                        2 - abs(voronoi.y * 6 - 4)));

                /*
                
                The whole point of this is to take the 3Ddirection of this random texture,
                and get the dot product of it with the view direction. This way EACH node
                is random enough to appear or disappear.
                But that randomness is not happening.
                */

                return dot(normalize(rndDir), i.viewDirection);
                float holographicMask = dot(rndDir, i.viewDirection * rndDir);
                
                return holographicMask;
                
                return float4(rndDir, 1);
                ///////////////////////////////////////////////

                outColor += frame * _FrameColor;
                outColor += corners * _CornerColor;
                outColor += divisionLine * _DivisionLineColor;
                outColor += stars * _StarColor;
                outColor += backgroundColor;
                outColor += tangentLight * _TangentLightColor;

                return outColor;
            }
            ENDCG
        }
    }
}
