// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// SHADER LOW: a domain-warped noise field, cheaply (the watch's CLOUDLIGHT):
// one scalar warp and two three-octave sums per pixel. SailfishOS: the
// watch's Qt 6 shader as inline GLSL ES 1.00, which Qt 5.6 compiles itself.
import QtQuick 2.6

Item {
    id: stage
    anchors.fill: parent

    ShaderEffect {
        id: fx
        anchors.fill: parent

        property real t: 0
        property color centerColor: "#58a6ff"
        property color outerColor: "#0b1b2e"
        property vector4d glints: Qt.vector4d(
            Math.cos(t * 0.11) * 0.55, Math.sin(t * 0.079) * 0.55,
            Math.cos(t * -0.063 + 2.1) * 0.62, Math.sin(t * 0.094 + 1.3) * 0.62)

        NumberAnimation on t {
            from: 0; to: 10000; duration: 10000000
            loops: Animation.Infinite
            running: fx.visible
        }

        fragmentShader: "
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
varying vec2 qt_TexCoord0;
uniform float qt_Opacity;
uniform float t;
uniform vec4 centerColor;
uniform vec4 outerColor;
uniform vec4 glints;

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
    float w = fbm3(uv * 2.2 + 5.2);
    float v = fbm3(uv * 2.6 + vec2(w, -w) * 1.5);
    float glint = 0.18 * smoothstep(0.75, 0.0, length(uv - glints.xy))
                + 0.14 * smoothstep(0.65, 0.0, length(uv - glints.zw));
    float d = clamp(v + glint, 0.0, 1.0);
    vec3 col = mix(outerColor.rgb, centerColor.rgb, smoothstep(0.10, 0.92, d));
    col = mix(col, centerColor.rgb, clamp(w * 0.40, 0.0, 1.0));
    col *= mix(0.70, 1.0, smoothstep(1.04, 0.66, r));
    gl_FragColor = vec4(col, 1.0) * qt_Opacity;
}"
    }
}
