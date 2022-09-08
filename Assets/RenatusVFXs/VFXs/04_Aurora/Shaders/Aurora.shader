Shader "Renatus/Aurora"
{
    Properties
    {
        [HDR] _BackgroundColor("Background Color", Color) = (1,1,1,1)
        [HDR] _StripColor("Strip Color", Color) = (1,1,1,1)
        _StripSpeed ("Strip Speed", Range(-1, 1)) = 0.5
        _SmallStripAmount ("Small Strip Amount", Range(0, 1)) = 0.5
        _WaveBend ("Wave Bending", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _BottomRimColor;
            float4 _BackgroundColor;
            float4 _StripColor;
            float _WaveBend;
            float _StripSpeed;
            float _SmallStripAmount;
            float _BottomRimHeight;

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


            Interpolator vert (MeshData v)
            {
                Interpolator o;
                
                float wave = sin(v.vertex.x + _Time.y) *_WaveBend;

                v.vertex.y += wave;
                v.vertex.x += wave;
                
                o.uv = v.uv;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float MinkowskiDistance(float2 p1, float2 p2, float p)
            {
                return pow(pow(abs(p1.x-p2.x), p) + pow(abs(p1.y-p2.y), p), 1/p);
            }

            inline float unity_noise_randomValue (float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
            }

            inline float unity_noise_interpolate (float a, float b, float t)
            {
                return (1.0-t)*a + (t*b);
            }

            inline float unity_valueNoise (float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = unity_noise_randomValue(c0);
                float r1 = unity_noise_randomValue(c1);
                float r2 = unity_noise_randomValue(c2);
                float r3 = unity_noise_randomValue(c3);

                float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
                float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
                float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            float SimpleNoise(float2 UV, float Scale)
            {
                float t = 0.0;

                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3-0));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3-1));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3-2));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                return t;
            }

            float4 frag (Interpolator i) : SV_Target
            {
                float4 outColor = float4(0,0,0,0);
                float cornerFade = smoothstep(0.45, 0.75, 1-distance(i.uv.x, 0.5));
                float bottomFade = saturate(smoothstep(0.95, 1, 1-distance(i.uv.y, 0.1)) + ( i.uv.y * 7));

                //////////////////// Aurora Strips //////////////////////
                {
                    float2 grid = float2(frac((i.uv.x + _Time.y * (_StripSpeed * 0.3)) * 4), i.uv.y);

                    float coreStar = pow(1-MinkowskiDistance(float2(0.5, 0.1), float2(grid.x, grid.y), 1), 12);
                    coreStar = smoothstep(0.2, 1, coreStar);
                    
                    float verticalLine = pow(1-distance(grid.x, 0.5), 8);
                    verticalLine = smoothstep(0.8, 1, verticalLine);

                    float verticalFade = 1 - i.uv.y;
                    float auroraStrip = saturate(coreStar + verticalLine) * verticalFade * cornerFade * bottomFade;
                     
                    outColor += _StripColor * auroraStrip;                    
                }

                /////////////////////// Background /////////////////////// 
                {
                    float noise = SimpleNoise(float2(i.uv.x, _Time.y * 0.02), 80);
                    float mask = 1-i.uv.y;

                    mask *= bottomFade;
                    mask *= cornerFade;
                    outColor += _BackgroundColor * noise * mask;
                }

                return outColor;
            }
            ENDCG
        }
    }
}