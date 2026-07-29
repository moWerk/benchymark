// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// The FRUGAL cloud — the GPU baseline, and the candidate stock wallpaper.
//
// Same scene as cloud-heavy, built to the opposite brief: hold 60 fps on a
// watch SoC while still reading as drifting cloud. Three things make it cheap,
// and they are the three that make the heavy one expensive:
//
//  1. NO sin() in the hash. The classic sin(dot(p,k))*43758 costs a
//     transcendental per lattice corner — four per noise lookup. These GPUs
//     are ALU-poor, so that alone dominates. The fract-multiply hash below is
//     plain arithmetic.
//  2. NO domain warp. Warping is what multiplies the heavy shader's fBm count
//     by five, and worse it is SERIAL: each warp must finish before the next
//     starts, a dependency chain the GPU cannot hide behind latency.
//  3. THREE octaves, not seven. On a 320-480 px panel the later octaves land
//     below the pixel pitch — you pay for detail nobody can resolve.
//
// Cost ladder across the three cloud phases, in lattice-hash evaluations per
// fragment:  frugal 12  ·  mid 48  ·  heavy 140.
//
// The motion is deliberately slow — a breathing drift rather than a boil,
// which is both cheaper to look at and what FlatMesh established as the house
// style. Two slow GLINTS drift through the field so different spots catch the
// eye at different moments (moWerk): glance attraction without animating the
// whole field faster.
//
// centerColor / outerColor mirror FlatMesh's property names exactly, because
// apps identify themselves by that pair and any second stock wallpaper has to
// honour the same contract.

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 centerColor;
    vec4 outerColor;
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

// Three octaves, unrolled: no loop counter, no dynamic branch.
float fbm3(vec2 p)
{
    return 0.5000 * noise(p)
         + 0.2500 * noise(p * 2.03 + 17.0)
         + 0.1250 * noise(p * 4.07 + 43.0);
}

void main()
{
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    float r = length(uv);

    // One field, drifting slowly on two axes at different rates so it never
    // visibly repeats its motion.
    float v = fbm3(uv * 2.6 + vec2(t * 0.020, t * -0.013));

    // Two glints on long, mutually prime periods: at any moment usually one is
    // near its peak, so the eye is drawn somewhere slightly different each
    // time it lands on the watch. Four cheap ops, no extra noise lookup.
    vec2 g1 = vec2(cos(t * 0.11), sin(t * 0.079)) * 0.55;
    vec2 g2 = vec2(cos(t * -0.063 + 2.1), sin(t * 0.094 + 1.3)) * 0.62;
    float glint = 0.22 * smoothstep(0.75, 0.0, length(uv - g1))
                + 0.16 * smoothstep(0.65, 0.0, length(uv - g2));

    float d = clamp(v + glint, 0.0, 1.0);

    // outerColor at the rim, centerColor in the middle, the cloud field
    // modulating between them — the same reading FlatMesh gives an app.
    vec3 col = mix(outerColor.rgb, centerColor.rgb, smoothstep(0.15, 0.95, d));
    col = mix(col, centerColor.rgb, (1.0 - smoothstep(0.0, 1.15, r)) * 0.35);
    col *= smoothstep(1.06, 0.30, r);          // fade into the round panel

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
