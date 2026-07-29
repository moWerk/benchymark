// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// The MID cloud — the middle rung, aimed at roughly 30 fps.
//
// Same scene and the same cheap hash as cloud-frugal, with the two things
// added back that cost the most, one step at a time:
//
//  * ONE domain warp instead of none. This is the interesting half: the warp
//    is a SERIAL dependency (q must resolve before the field that uses it),
//    so it costs more than its instruction count suggests. Comparing this
//    phase against the frugal one isolates warp cost specifically.
//  * FOUR octaves instead of three.
//
// 3 fBm x 4 octaves = 12 lattice-hash evaluations... x4 corners = 48 per
// fragment, against the frugal shader's 12 and the heavy one's 140. Still no
// sin() anywhere: the heavy shader keeps that, so the three phases together
// separate transcendental cost from warp cost from octave count.
//
// If this lands far from 30 fps, the dial is the octave count first and the
// warp strength second — both are one-line changes, and the phase exists to
// be tuned against real silicon rather than argued about.

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

float fbm4(vec2 p)
{
    return 0.5000 * noise(p)
         + 0.2500 * noise(p * 2.03 + 17.0)
         + 0.1250 * noise(p * 4.07 + 43.0)
         + 0.0625 * noise(p * 8.11 + 91.0);
}

void main()
{
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    float r = length(uv);

    // The warp: two fBm evaluations whose RESULT feeds the third. The GPU
    // cannot start the third until both land, which is the whole point.
    vec2 q = vec2(fbm4(uv * 2.4 + vec2(t * 0.021, 0.0)),
                  fbm4(uv * 2.4 + vec2(0.0, t * -0.017) + 5.2));
    float v = fbm4(uv * 2.8 + q * 1.6 + vec2(t * 0.013, t * 0.009));

    vec2 g1 = vec2(cos(t * 0.11), sin(t * 0.079)) * 0.55;
    vec2 g2 = vec2(cos(t * -0.063 + 2.1), sin(t * 0.094 + 1.3)) * 0.62;
    float glint = 0.20 * smoothstep(0.75, 0.0, length(uv - g1))
                + 0.15 * smoothstep(0.65, 0.0, length(uv - g2));

    float d = clamp(v + glint, 0.0, 1.0);

    vec3 col = mix(outerColor.rgb, centerColor.rgb, smoothstep(0.12, 0.95, d));
    // The warp field also tints, so the extra work is visible and not just
    // billed — a phase whose cost you cannot see reads as a bug.
    col = mix(col, centerColor.rgb, clamp(q.x * 0.45, 0.0, 1.0));
    col *= smoothstep(1.06, 0.30, r);

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
