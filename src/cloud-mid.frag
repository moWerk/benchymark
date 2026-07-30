// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// The MID cloud — the middle rung.
//
// Same scene, same cheap hash and same uniform glints as cloud-frugal, with
// the one thing added back that the frugal shader refuses: a DOMAIN WARP.
//
// That is deliberately the only difference. LITE against MID therefore
// isolates warp cost and nothing else — which matters, because the warp is a
// SERIAL dependency: the field cannot start until the warp resolves, so it
// costs more than its instruction count suggests and the GPU cannot hide it
// behind latency. The first measured run made that vivid: MID landed at 4 fps
// against LITE's 16, on one extra fBm.
//
// The warp is now SCALAR rather than vec2 — one fBm feeding both axes instead
// of two independent ones — which halves the added work while keeping the
// effect that is being measured. Cost per fragment, in lattice hashes:
//
//     LITE  8   ·   MID  24   ·   HEAVY  140
//
// If MID still sits far from its 30 fps target, the next dial is the octave
// count, then the warp amplitude. It is meant to be tuned against silicon
// rather than argued about — and on a 480x480 panel the arithmetic may simply
// not allow 30, which is itself worth knowing.

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 centerColor;
    vec4 outerColor;
    vec4 glints;
    float qt_Opacity;
    float t;
};

float hash(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Three counter-drifting octaves — the field morphs rather than slides, so it
// reads as alive at a calm speed.
float fbm3(vec2 p)
{
    return 0.55 * noise(p + vec2( t * 0.050, -t * 0.034))
         + 0.28 * noise(p * 2.03 + vec2(-t * 0.041, t * 0.057) + 17.0)
         + 0.14 * noise(p * 4.07 + vec2( t * 0.029, t * 0.046) + 43.0);
}

void main()
{
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    float r = length(uv);

    // ONE scalar warp. The field below cannot begin until this resolves —
    // that serialisation is the thing this phase exists to price.
    float w = fbm3(uv * 2.2 + 5.2);
    float v = fbm3(uv * 2.6 + vec2(w, -w) * 1.5);

    float glint = 0.18 * smoothstep(0.75, 0.0, length(uv - glints.xy))
                + 0.14 * smoothstep(0.65, 0.0, length(uv - glints.zw));

    float d = clamp(v + glint, 0.0, 1.0);

    vec3 col = mix(outerColor.rgb, centerColor.rgb, smoothstep(0.10, 0.92, d));
    // The warp tints as well as displaces, so the extra work is visible rather
    // than merely billed — a phase whose cost you cannot see reads as a bug.
    col = mix(col, centerColor.rgb, clamp(w * 0.40, 0.0, 1.0));
    col *= mix(0.70, 1.0, smoothstep(1.04, 0.66, r));

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
