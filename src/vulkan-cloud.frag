#version 450
// Shader heavy's fragment shader (qml/stages/ShaderHigh.qml) carried over to
// Vulkan GLSL character for character: same seven octaves, same five fBm
// sums, 140 hash() evaluations per pixel. Only that way is the Vulkan stage
// the twin of the QtQuick one rather than just another shader.
//
// Compiled into src/vulkan-spv.h, which is in the tree because the phone has
// no glslc:
//   glslc -O --target-env=vulkan1.0 src/vulkan-full.vert  -mfmt=c -o full.txt
//   glslc -O --target-env=vulkan1.0 src/vulkan-cloud.frag -mfmt=c -o cloud.txt
layout(location = 0) in vec2 uv0;
layout(location = 0) out vec4 fragColor;

layout(push_constant) uniform Push {
    float t;
} push;

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p)
{
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 7; ++i) {
        v += a * noise(p);
        p *= 2.03;
        a *= 0.5;
    }
    return v;
}

void main()
{
    float t = push.t;
    vec2 uv = uv0 * 2.0 - 1.0;
    float r = length(uv);
    vec2 q = vec2(fbm(uv * 3.0 + t * 0.090), fbm(uv * 3.0 - t * 0.066));
    vec2 s = vec2(fbm(uv * 3.0 + q * 2.5 + t * 0.042),
                  fbm(uv * 3.0 + q * 2.5 - t * 0.054));
    float v = fbm(uv * 4.0 + s * 3.0);
    vec3 col = mix(vec3(0.05, 0.10, 0.25), vec3(0.35, 0.85, 0.95), v);
    col = mix(col, vec3(0.95, 0.55, 0.25), clamp(s.x * 0.6, 0.0, 1.0));
    col *= mix(0.70, 1.0, smoothstep(1.04, 0.66, r));
    fragColor = vec4(col, 1.0);
}
