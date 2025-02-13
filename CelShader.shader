Shader "Custom/CelShader"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _ShadowColor("Shadow Color", Color) = (0,0,0,1)
        _MainTex("Texture", 2D) = "white" {}
        _ShadowThreshold("Shadow Threshold", Range(0,1)) = 0.5
        _ShadowSmooth("Shadow Smooth", Range(0,1)) = 0.1
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            Name "ShadowPass"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHTS_SHADOWS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float4 _ShadowColor;
            float _ShadowThreshold;
            float _ShadowSmooth;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS);
                OUT.uv = IN.uv;
                OUT.shadowCoord = TransformWorldToShadowCoord(OUT.positionWS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 normal = normalize(IN.normalWS);
                Light mainLight = GetMainLight(IN.shadowCoord);

                float diffuse = saturate(dot(normal, mainLight.direction));

                float shadowAttenuation = MainLightRealtimeShadow(IN.shadowCoord);
                float shadowValue = diffuse * shadowAttenuation;

                shadowValue = smoothstep(_ShadowThreshold - _ShadowSmooth, _ShadowThreshold + _ShadowSmooth, shadowValue);

                float3 shadowColor = lerp(_ShadowColor.rgb, float3(1,1,1), shadowValue);

                float3 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb * _BaseColor.rgb;

                float3 finalColor = texColor * shadowColor * mainLight.color;

                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            Varyings ShadowPassVertex(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);
                return OUT;
            }

            half4 ShadowPassFragment(Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
