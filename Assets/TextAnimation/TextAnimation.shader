Shader "Custom/TextAnimation"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _Glossiness("Smoothness", Range(0, 1)) = 0.5
        _Metallic("Metallic", Range(0, 1)) = 0.0

        [Header(Transition)]
        _Duration("Duration", Float) = 2
        _Speed("Speed", Float) = 1
        _Transition("Current Time", Float) = 0.5

        [Header(Twisting)]
        _Twist("Twisting Angle", Float) = 3.14
        _TNoiseRatio("Noise Ratio", Range(0, 1)) = 1
        _TNoiseFreq("Noise Frequency", Float) = 2

        [Header(Noise)]
        _NoiseAmp("Noise Amplitude", Float) = 0.75
        _NoiseCurve("Amplitude Curve", Float) = 15
        _NoiseFreq("Noise Frequency", Float) = 0.5
        _NoiseVel("Noise Velocity", Vector) = (0.7, 1, 0, 0)

        [Header(Waving)]
        _WaveAmp("Wave Height", Float) = 0.6
        _WaveFreq("Wave Frequency", Float) = 1.25
        _WaveSpeed("Wave Speed", Float) = 1

        [Space]
        _ScaleCurve("Scale Curve", Float) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM

        #pragma surface surf Standard vertex:vert nolightmap
        #pragma target 3.0

        #include "ClassicNoise3D.cginc"

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        half4 _Color;

        float _Duration;
        float _Speed;
        float _Transition;

        float _Twist;
        float _TNoiseRatio;
        float _TNoiseFreq;

        float _NoiseAmp;
        float _NoiseCurve;
        float _NoiseFreq;
        float3 _NoiseVel;

        float _WaveAmp;
        float _WaveFreq;
        float _WaveSpeed;

        float _ScaleCurve;

        float nrand(float2 uv)
        {
            return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
        }

        float3 displace(float3 p, float2x2 mtx)
        {
            // random vector
            float rx = nrand(p.xy + p.zx);
            float ry = nrand(p.yz + p.xy + float2(3.1, 4.2));
            float rz = nrand(p.zx - p.yz + float2(5.3, 5.1));
            float3 rv = float3(rx, ry, rz) * 2 - 1;

            // tweak distribution
            rv = normalize(rv) * pow(nrand(p.xx + p.yz) , _NoiseCurve);

            // noise field
            float3 np = p * _NoiseFreq + _NoiseVel * _Time.y;
            float ns = max(cnoise(np), 0) * _NoiseAmp;

            // waving
            float wv = sin(p.x * _WaveFreq + _Time.y * _WaveSpeed) * _WaveAmp;

            // applying the rotation matrix
            p.yz = mul(mtx, p.yz);

            // composite
            return p + rv * ns + float3(0, 0, wv);
        }

        void vert(inout appdata_full v, out Input data)
        {
            UNITY_INITIALIZE_OUTPUT(Input, data);

            float3 p0 = v.vertex.xyz;    // this vertex
            float3 pc = v.texcoord.xyz;  // centroid
            float3 p1 = v.texcoord1.xyz; // next vertex
            float3 p2 = v.texcoord2.xyz; // prev vertex

            // time parameter
            float t = min(_Transition / _Duration - abs(pc.x) / _Speed, 1.0);

            // twisting angle
            float tw = lerp(_Twist, 0, t);
            tw *= lerp(1, cnoise(pc * _TNoiseFreq), _TNoiseRatio);

            // scaling factor
            float sc = 1 - pow(1 - max(t, 0), _ScaleCurve);

            // rotation matrix
            float snr, csr;
            sincos(tw, snr, csr);
            float2x2 mtx = float2x2(csr, -snr, snr, csr);

            // displace the vertices
            p0 = displace(p0, mtx);
            pc = displace(pc, mtx);
            p1 = displace(p1, mtx);
            p2 = displace(p2, mtx);

            // write back to the vertex
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
