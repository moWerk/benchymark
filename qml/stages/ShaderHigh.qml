// SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// SHADER HIGH: a doubly domain-warped fBm field (the watch's CLOUDHEAVY):
// four fBm sums of `octaves` noise lookups per pixel, every frame. GPU
// bound, scales with pixels. SailfishOS: inline GLSL ES 1.00 for Qt 5.6.
import QtQuick 2.6

Item {
    id: stage
    anchors.fill: parent

    // sfos-2.0: the warped field computed `load` times per pixel at offsets, the
    // first one drawn as before; the score counts rendered pixels x load
    readonly property var ladder: [1, 2, 4, 8, 16, 32]
    property int load: 1
    readonly property bool perPixel: true
    //% "Mpx/s"
    readonly property string unit: qsTrId("id-unit-mpx")

    // A driver that cannot compile a heavy step draws nothing and reads as
    // a fast GPU: it climbs to the heaviest step, and the results mark it as
    // a lower bound. ShaderEffect.status cannot tell: Qt 5.6 reports Error
    // with an empty log for shaders that compile and draw (XA2, night audit).
    ShaderEffect {
        id: fx
        anchors.fill: parent

        property real t: 0

        NumberAnimation on t {
            from: 0; to: 10000; duration: 10000000
            loops: Animation.Infinite
            running: fx.visible
        }

        fragmentShader: "#define N " + stage.load + "
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
varying vec2 qt_TexCoord0;
uniform float qt_Opacity;
uniform float t;

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
    vec2 s0 = vec2(0.0), s = vec2(0.0);
    float v0 = 0.0, v = 0.0;
    for (int k = 0; k < N; k++) {
        vec2 o = vec2(float(k) * 1.37, float(k) * -0.71);
        vec2 q = vec2(fbm(uv * 3.0 + o + t * 0.090), fbm(uv * 3.0 + o - t * 0.066));
        vec2 sk = vec2(fbm(uv * 3.0 + o + q * 2.5 + t * 0.042),
                       fbm(uv * 3.0 + o + q * 2.5 - t * 0.054));
        float vk = fbm(uv * 4.0 + o + sk * 3.0);
        if (k == 0) { s0 = sk; v0 = vk; }
        s += sk;
        v += vk;
    }
    s = mix(s0, s / float(N), 0.25);
    v = mix(v0, v / float(N), 0.25);
    vec3 col = mix(vec3(0.05, 0.10, 0.25), vec3(0.35, 0.85, 0.95), v);
    col = mix(col, vec3(0.95, 0.55, 0.25), clamp(s.x * 0.6, 0.0, 1.0));
    col *= mix(0.70, 1.0, smoothstep(1.04, 0.66, r));
    gl_FragColor = vec4(col, 1.0) * qt_Opacity;
}"
    }
}
