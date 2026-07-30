// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// nutty-benchy's SHADER phase: a doubly domain-warped fBm field.
//
// Chosen because it is honestly GPU-bound and scales with PIXELS, not with
// scene complexity: four fBm evaluations of seven octaves each means ~28 noise
// lookups per fragment, every frame, so a 480x480 panel does 2.25x the work of
// a 320x320 one. That makes it the phase where reporting Mpix/s beside raw FPS
// actually matters.
//
// Qt6 pipeline: this source ships beside the compiled .qsb, built with
//   /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 \
//       -o benchy-shader.frag.qsb benchy-shader.frag
// Inline GLSL crashes Qt6, so the .qsb is what ShaderEffect loads; the source
// is shipped so the phase can be rebuilt and audited rather than trusted as a
// binary blob.

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;
};

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
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    float r = length(uv);

    // Two rounds of domain warping — each one costs a full fBm per axis.
    vec2 q = vec2(fbm(uv * 3.0 + t * 0.090), fbm(uv * 3.0 - t * 0.066));
    vec2 s = vec2(fbm(uv * 3.0 + q * 2.5 + t * 0.042),
                  fbm(uv * 3.0 + q * 2.5 - t * 0.054));
    float v = fbm(uv * 4.0 + s * 3.0);

    vec3 col = mix(vec3(0.05, 0.10, 0.25), vec3(0.35, 0.85, 0.95), v);
    col = mix(col, vec3(0.95, 0.55, 0.25), clamp(s.x * 0.6, 0.0, 1.0));
    // A hint of a rim rather than a black hole — the wide fade to black
    // swallowed the scene (moWerk). Half the width, dimming not extinguishing.
    col *= mix(0.70, 1.0, smoothstep(1.04, 0.66, r));

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
