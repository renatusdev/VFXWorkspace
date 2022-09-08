Shader "Renatus/Lightning"
{
    Properties
    {
        [HDR]_Color("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _LightningSize ("Lightning Size", Range(0, 1)) = 0.5
        _LightningYSizeBias ("Lightning Y Size Bias", Range(0, 1)) = 0.5
        _LightningNoise ("Lightning Noise", Range(0, 1)) = 0.5
        _LightningPanX ("Lightning Noise Panning X", Range(0, 1)) = 0.5
        _LightningPanY ("Lightning Noise Panning Y", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "\Assets\RenatusVFXs\Parent Shaders\Noise.cginc"

            sampler2D _MainTex;
            float4 _Color;
            float4 _MainTex_ST;
            float _LightningNoise;
            float _LightningSize;
            float _LightningYSizeBias;
            float _LightningPanX;
            float _LightningPanY;

            struct MeshData
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Interpolator
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
            };

            Interpolator vert (MeshData v)
            {
                Interpolator i;
                i.vertex = UnityObjectToClipPos(v.vertex);
                i.uv = TRANSFORM_TEX(v.uv, _MainTex);
                i.color = v.color;
                return i;
            }

            float4 frag (Interpolator i) : SV_Target
            {
                // Create UV for noise deformation.
                float2 noiseUV = float2(i.uv.x + _Time.y*_LightningPanX, i.uv.y + _Time.y*_LightningPanY);
                // Generate noise sample.
                float noiseDeformation = GradientNoise(noiseUV, 20 * _LightningNoise) * 2 - 1;                
                // Scale down noise deformation.
                noiseDeformation *= 0.05;
                // Distance field from frag-x to (center + the deformation).
                float lightningMask = 1-distance(i.uv.x, 0.5 + noiseDeformation);
                // Create a value to step the lightning mask with a [0.9, 1] range.
                float lightningSize = 0.1 * (1-_LightningSize) + 0.9; 
                // Y-axis bias for lightning size.
                float lightningYSizeBias = (distance(i.uv.y, (1-_LightningYSizeBias)) * (lightningSize-1));
                // Step the lightning mask.
                lightningMask = step(lightningSize - lightningYSizeBias, lightningMask);

                float4 outColor = lightningMask;
                outColor *= i.color;
                outColor *= _Color;

                return outColor;
            }
            ENDCG
        }
    }
}
