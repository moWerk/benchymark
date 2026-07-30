// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// The FRUGAL cloud — the GPU baseline, and the candidate stock wallpaper.
//
// Same scene as cloud-heavy, built to the opposite brief: as close to the
// panel's ceiling as a procedural cloud can get while still reading as
// drifting cloud. Four things make it cheap, and they are the four that make
// the heavy one expensive:
//
//  1. NO sin() in the hash. The classic sin(dot(p,k))*43758 costs a
//     transcendental per lattice corner — four per noise lookup. These GPUs
//     are ALU-poor, so that alone dominates.
//  2. NO domain warp. Warping multiplies the heavy shader's fBm count by
//     five, and worse it is SERIAL: each warp must finish before the next
//     starts, a dependency chain the GPU cannot hide behind latency.
//  3. TWO octaves. On a 320-480 px panel the later octaves land below the
//     pixel pitch — detail nobody can resolve, paid for per fragment.
//  4. NO transcendentals for the glints. Their centres are uniforms now,
//     computed once per frame on the CPU instead of four sin/cos per PIXEL.
//     They never depended on uv, so this was pure waste.
//
// MOTION. The first cut drifted the whole field by t*0.020, and since t
// advances one unit per second that is 0.2 units over a ten-second phase — in
// a field scaled 2.6, well under one feature width. It read as a still image
// (moWerk). Speed alone is the wrong fix: a slowly TRANSLATING noise field is
// genuinely hard to perceive. So the octaves drift in different directions and
// the field MORPHS rather than slides, which is far more visible per unit of
// motion and costs two extra MADs. Calm, but alive.

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 centerColor;
    vec4 outerColor;
    vec4 glints;                  // xy = first centre, zw = second
    float qt_Opacity;
    float t;
};

// Plain arithmetic, no transcendentals.
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

// Two octaves, counter-drifting, unrolled: no loop counter, no dynamic branch.
float fbm2(vec2 p)
{
    return 0.62 * noise(p + vec2( t * 0.055, -t * 0.038))
         + 0.30 * noise(p * 2.03 + vec2(-t * 0.044, t * 0.061) + 17.0);
}

void main()
{
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    float r = length(uv);

    float v = fbm2(uv * 2.4);

    // Two slow highlights on long, mutually prime periods: at any moment one
    // is usually near its peak, so the eye is drawn somewhere slightly
    // different each time it lands on the watch.
    float glint = 0.20 * smoothstep(0.75, 0.0, length(uv - glints.xy))
                + 0.15 * smoothstep(0.65, 0.0, length(uv - glints.zw));

    float d = clamp(v + glint, 0.0, 1.0);

    // outerColor at the rim, centerColor in the middle, the cloud field
    // modulating between them — the same reading FlatMesh gives an app.
    vec3 col = mix(outerColor.rgb, centerColor.rgb, smoothstep(0.10, 0.92, d));
    col = mix(col, centerColor.rgb, (1.0 - smoothstep(0.0, 1.15, r)) * 0.30);

    // A HINT of a rim, not a black hole. The first cut faded from r=0.30 all
    // the way to black at r=1.06 — three quarters of the radius spent going
    // dark, which swallowed the scene and looked wrong as a wallpaper
    // (moWerk). Half the width, and it only dims rather than extinguishes.
    col *= mix(0.70, 1.0, smoothstep(1.04, 0.66, r));

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
