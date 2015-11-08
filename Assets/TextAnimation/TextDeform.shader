Shader "Custom/TextDeform"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _Glossiness("Smoothness", Range(0, 1)) = 0.5
        _Metallic("Metallic", Range(0, 1)) = 0.0
        _Amplitude("Amplitude", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM

        #pragma surface surf Standard vertex:vert nolightmap addshadow
        #pragma target 3.0

        #include "ClassicNoise3D.cginc"

        struct Input {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        half4 _Color;
        float _Amplitude;

        float nrand(float2 uv)
        {
            return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
        }

        float3 displace(float3 p, float r)
        {
            /*
            p *= 2;
            float3 d = float3(
                cnoise(p),
                cnoise(p + float3(88.4, 18.1, 31.4)),
                cnoise(p + float3(28.4, 38.1, 61.4))
            );
            //d = d * d * d;
            d *= 2 * cos(_Time.y * 0.3) * _Amplitude;
            return d;
            */
            /*

            float3 d = float3(
                nrand(p.xy + p.zx),
                nrand(p.xy * 2.1 + p.zx + float2(3.1, 45.2)),
                nrand(p.xy + p.zx * 3.1 + float2(5.3, 5.1))
            );
            d = d * 2 - 1;
            d *= pow(cnoise(p * 0.3 + float3(_Time.y, 0, 0)) * 1.1, 2);
            d *= pow(nrand(p.yz + p.xy + float2(92.12, 11.43)), 5);
            //float ss = pow(sin(p.x/3 + _Time.y * 2), 10);
            //d *= (ss > 0.3) * ss;
            return d * _Amplitude;
            */

/*
            float3 dr = float3(
                nrand(p.xy + p.zx),
                nrand(p.xy * 2.1 + p.zx + float2(3.1, 45.2)),
                nrand(p.xy + p.zx * 3.1 + float2(5.3, 5.1))
            );
            dr = dr * 2 - 1;
            dr = pow(dr, 10) * sign(dr);
            dr *= saturate(cnoise(p * 2.5 + float3(0, _Time.y * 1.7, _Time.y)) * 0.5);

            float r = 20 * (saturate(sin(p.x * 0.2 + _Time.y)) + 0.04 * sin(p.x * 0.4 + _Time.y * 0.9));

            float snr, csr;
            sincos(r, snr, csr);

            float2x2 m = float2x2(csr, -snr, snr, csr);

            p.yz = mul(m, p.yz);

            return p + dr;
            */

            float3 dr = float3(
                nrand(p.xy + p.zx),
                nrand(p.xy * 2.1 + p.zx + float2(3.1, 45.2)),
                nrand(p.xy + p.zx * 3.1 + float2(5.3, 5.1))
            );
            dr = dr * 2 - 1;
            dr = pow(dr, 10) * sign(dr);
            dr *= saturate(cnoise(p * 0.5 + float3(_Time.y * 0.7, _Time.y, 0)) * 0.75);

            dr += float3(0, 0, 0.6 * sin(p.x * 1.25 + _Time.y));

            float snr, csr;
            sincos(r, snr, csr);

            float2x2 m = float2x2(csr, -snr, snr, csr);
            p.yz = mul(m, p.yz);

            return p + dr;
        }

        void vert(inout appdata_full v, out Input data)
        {
            UNITY_INITIALIZE_OUTPUT(Input, data);

            float3 p0 = v.vertex.xyz;
            float3 pc = v.texcoord.xyz;
            float3 p1 = v.texcoord1.xyz;
            float3 p2 = v.texcoord2.xyz;

            float t = max(abs(pc.x) - _Time.y + 3, 0.0);
            float r = t * 2;
            r *= cnoise(pc * 2) * 2;

            p0 = displace(p0, r);
            pc = displace(pc, r);
            p1 = displace(p1, r);
            p2 = displace(p2, r);

            float sc = saturate(0.0 - 0.2 * abs(pc.x) + _Time.y * 0.6);

            v.vertex.xyz = lerp(pc, p0, sc);
            v.normal = normalize(cross(p1 - p0, p2 - p0));
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            o.Albedo = _Color.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
        }

        ENDCG
    }
    FallBack "Diffuse"
}
