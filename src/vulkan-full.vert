#version 450
// Full-screen triangle without a vertex buffer; uv covers 0..1 over the
// visible area, exactly like qt_TexCoord0 in the Shader heavy effect.
layout(location = 0) out vec2 uv;

void main()
{
    vec2 p = vec2(float((gl_VertexIndex << 1) & 2), float(gl_VertexIndex & 2));
    uv = p;
    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
}
