/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include "BufferRead.h"

#include <QMetaObject>
#include <QOpenGLContext>
#include <QOpenGLExtraFunctions>
#include <QOpenGLFramebufferObject>
#include <QQuickWindow>
#include <QRegExp>
#include <QVector>
#include <cmath>

static const int kEntries = 1024;   // 1024 vec4 = 16 KB, the smallest UBO a GPU must allow

// One triangle over the whole target, from gl_VertexID: no vertex buffer.
static const char *kVertex =
    "out vec2 uv;\n"
    "void main() {\n"
    "    vec2 p = vec2(float((gl_VertexID << 1) & 2), float(gl_VertexID & 2));\n"
    "    uv = p;\n"
    "    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);\n"
    "}\n";

// The first read follows a slow spiral, so the picture has a shape; every
// further index comes from the sum read so far, so each read waits for the
// one before and neighbouring pixels soon read different entries.
static const char *kFragment =
    "in vec2 uv;\n"
    "out vec4 fragColor;\n"
    "uniform float t;\n"
    "uniform float aspect;\n"
    "uniform int lookups;\n"
    "void main() {\n"
    "    vec2 p = uv * 2.0 - 1.0;\n"
    "    p.x *= aspect;\n"
    "    float r = length(p);\n"
    "    float a = atan(p.y, p.x) * 0.15915494;\n"
    "    float s = r * 1.3 + a * 2.0 - t * 0.04 + 0.08 * sin(t * 0.7 + r * 6.0);\n"
    "    int idx = int(fract(s) * 1024.0) & 1023;\n"
    "    vec4 first = READ(idx);\n"
    "    vec4 acc = first;\n"
    "    for (int i = 1; i < lookups; i++) {\n"
    "        idx = (idx + int(acc.w * 1024.0) + i) & 1023;\n"
    "        acc += READ(idx);\n"
    "    }\n"
    "    vec3 col = mix(first.rgb, acc.rgb / float(lookups), 0.35);\n"
    "    col *= mix(0.6, 1.0, smoothstep(1.4, 0.3, r));\n"
    "    fragColor = vec4(col, 1.0);\n"
    "}\n";

class BufferReadRenderer : public QQuickFramebufferObject::Renderer
{
public:
    ~BufferReadRenderer() override
    {
        // the render thread, with the context current
        QOpenGLContext *ctx = QOpenGLContext::currentContext();
        if (!ctx) return;
        QOpenGLExtraFunctions *f = ctx->extraFunctions();
        if (m_program) f->glDeleteProgram(m_program);
        if (m_buffer) f->glDeleteBuffers(1, &m_buffer);
        if (m_texture) f->glDeleteTextures(1, &m_texture);
    }

    QOpenGLFramebufferObject *createFramebufferObject(const QSize &size) override
    {
        return new QOpenGLFramebufferObject(size);
    }

    void synchronize(QQuickFramebufferObject *item) override
    {
        BufferRead *b = static_cast<BufferRead *>(item);
        m_window = item->window();
        if (m_mode.isEmpty()) m_mode = b->mode();   // fixed once it runs
        m_lookups = qBound(1, b->lookups(), 1024);
        m_t = float(b->t());
        if (!m_report.isEmpty()) {
            QMetaObject::invokeMethod(b, "setFailure", Qt::QueuedConnection, Q_ARG(QString, m_report));
            m_report.clear();
        }
    }

    void render() override
    {
        QOpenGLContext *ctx = QOpenGLContext::currentContext();
        QOpenGLExtraFunctions *f = ctx->extraFunctions();
        if (!m_tried) {
            m_tried = true;
            const QString why = init(ctx);
            if (!why.isEmpty()) {
                qWarning("Benchymark: %s stage cannot run: %s", qPrintable(m_mode), qPrintable(why));
                m_report = why;
                update();   // so synchronize hands the reason over
            }
        }
        const QSize size = framebufferObject()->size();
        f->glViewport(0, 0, size.width(), size.height());
        f->glDisable(GL_BLEND);
        f->glDisable(GL_DEPTH_TEST);
        f->glDisable(GL_STENCIL_TEST);
        f->glDisable(GL_SCISSOR_TEST);
        f->glClearColor(0, 0, 0, 1);
        f->glClear(GL_COLOR_BUFFER_BIT);
        if (m_program) {
            f->glUseProgram(m_program);
            f->glUniform1f(m_locT, m_t);
            f->glUniform1f(m_locAspect, size.height() > 0 ? float(size.width()) / size.height() : 1.0f);
            f->glUniform1i(m_locLookups, m_lookups);
            if (m_mode == QLatin1String("ubo")) {
                f->glBindBufferBase(GL_UNIFORM_BUFFER, 0, m_buffer);
            } else if (m_mode == QLatin1String("ssbo")) {
                f->glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, m_buffer);
            } else {
                f->glActiveTexture(GL_TEXTURE0);
                f->glBindTexture(GL_TEXTURE_2D, m_texture);
            }
            // the scene graph's attribute arrays would point into its memory
            for (GLuint a = 0; a < 8; a++) f->glDisableVertexAttribArray(a);
            f->glBindBuffer(GL_ARRAY_BUFFER, 0);
            f->glDrawArrays(GL_TRIANGLES, 0, 3);
            if (m_mode == QLatin1String("ubo")) f->glBindBufferBase(GL_UNIFORM_BUFFER, 0, 0);
            else if (m_mode == QLatin1String("ssbo")) f->glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, 0);
            else f->glBindTexture(GL_TEXTURE_2D, 0);
            f->glUseProgram(0);
        }
        if (m_window) m_window->resetOpenGLState();
    }

private:
    // empty when it can run, else why not
    QString init(QOpenGLContext *ctx)
    {
        if (!ctx->isOpenGLES()) return QStringLiteral("not OpenGL ES");
        QOpenGLFunctions *g = ctx->functions();
        const GLubyte *v = g->glGetString(GL_VERSION);
        QRegExp re(QStringLiteral("OpenGL ES (\\d+)\\.(\\d+)"));
        int version = 20;
        if (v && re.indexIn(QString::fromLatin1(reinterpret_cast<const char *>(v))) >= 0)
            version = re.cap(1).toInt() * 10 + re.cap(2).toInt();
        const bool ssbo = m_mode == QLatin1String("ssbo");
        // UBOs and texelFetch came with ES 3.0, storage buffers with 3.1
        const int need = ssbo ? 31 : 30;
        if (version < need)
            return QStringLiteral("needs OpenGL ES %1.%2").arg(need / 10).arg(need % 10);
        // the ES 3.0 calls are only resolved past the version check
        QOpenGLExtraFunctions *f = ctx->extraFunctions();
        if (ssbo) {
            // optional in fragment shaders: ES 3.1 only promises them in compute
            GLint blocks = 0;
            f->glGetIntegerv(GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS, &blocks);
            if (blocks < 1) return QStringLiteral("no storage buffers in fragment shaders");
        } else if (m_mode == QLatin1String("ubo")) {
            GLint bytes = 0;
            f->glGetIntegerv(GL_MAX_UNIFORM_BLOCK_SIZE, &bytes);
            if (bytes < kEntries * 16) return QStringLiteral("uniform blocks under 16 KB");
        }

        QByteArray head = ssbo ? "#version 310 es\n" : "#version 300 es\n";
        head += "precision highp float;\nprecision highp int;\n";
        QByteArray decl;
        if (m_mode == QLatin1String("ubo"))
            decl = "layout(std140) uniform Table { vec4 table[1024]; };\n#define READ(i) table[i]\n";
        else if (ssbo)
            decl = "layout(std430, binding = 0) readonly buffer Table { vec4 table[1024]; };\n#define READ(i) table[i]\n";
        else
            decl = "uniform highp sampler2D tableTex;\n#define READ(i) texelFetch(tableTex, ivec2((i), 0), 0)\n";
        const GLuint vs = compile(f, GL_VERTEX_SHADER, head + kVertex);
        const GLuint fs = compile(f, GL_FRAGMENT_SHADER, head + decl + kFragment);
        if (!vs || !fs) {
            if (vs) f->glDeleteShader(vs);
            if (fs) f->glDeleteShader(fs);
            return QStringLiteral("the shader does not compile");
        }
        m_program = f->glCreateProgram();
        f->glAttachShader(m_program, vs);
        f->glAttachShader(m_program, fs);
        f->glLinkProgram(m_program);
        f->glDeleteShader(vs);
        f->glDeleteShader(fs);
        GLint linked = 0;
        f->glGetProgramiv(m_program, GL_LINK_STATUS, &linked);
        if (!linked) {
            char log[1024] = { 0 };
            f->glGetProgramInfoLog(m_program, sizeof(log) - 1, nullptr, log);
            qWarning("Benchymark: buffer stage link: %s", log);
            f->glDeleteProgram(m_program);
            m_program = 0;
            return QStringLiteral("the shader does not link");
        }
        m_locT = f->glGetUniformLocation(m_program, "t");
        m_locAspect = f->glGetUniformLocation(m_program, "aspect");
        m_locLookups = f->glGetUniformLocation(m_program, "lookups");

        // The table: the app's blues in bands with a thin gold stripe, and in
        // w a golden-ratio scramble that sends the walk across the table.
        QVector<float> table(kEntries * 4);
        for (int i = 0; i < kEntries; i++) {
            const float s = float(i) / kEntries;
            const float k = 0.5f + 0.5f * std::sin(6.2831853f * s * 4.0f);
            float r = 0.043f + (0.345f - 0.043f) * k, gr = 0.106f + (0.651f - 0.106f) * k,
                  b = 0.180f + (1.0f - 0.180f) * k;
            if (std::fmod(s * 8.0f, 1.0f) < 0.05f) { r = 0.94f; gr = 0.765f; b = 0.055f; }
            const double w = std::fmod(i * 0.6180339887, 1.0);
            table[i * 4] = r;
            table[i * 4 + 1] = gr;
            table[i * 4 + 2] = b;
            table[i * 4 + 3] = float(w);
        }
        if (m_mode == QLatin1String("texture")) {
            f->glGenTextures(1, &m_texture);
            f->glBindTexture(GL_TEXTURE_2D, m_texture);
            // float textures cannot be filtered; texelFetch does not filter anyway
            f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            f->glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, kEntries, 1, 0, GL_RGBA, GL_FLOAT, table.constData());
            f->glBindTexture(GL_TEXTURE_2D, 0);
            f->glUseProgram(m_program);
            f->glUniform1i(f->glGetUniformLocation(m_program, "tableTex"), 0);
            f->glUseProgram(0);
        } else {
            const GLenum target = ssbo ? GL_SHADER_STORAGE_BUFFER : GL_UNIFORM_BUFFER;
            f->glGenBuffers(1, &m_buffer);
            f->glBindBuffer(target, m_buffer);
            f->glBufferData(target, table.size() * sizeof(float), table.constData(), GL_STATIC_DRAW);
            f->glBindBuffer(target, 0);
            if (!ssbo) {
                // layout(binding) on a uniform block needs ES 3.1, so set it here
                const GLuint block = f->glGetUniformBlockIndex(m_program, "Table");
                if (block == GL_INVALID_INDEX) return QStringLiteral("the shader has no table block");
                f->glUniformBlockBinding(m_program, block, 0);
            }
        }
        const GLenum err = f->glGetError();
        if (err != GL_NO_ERROR) {
            f->glDeleteProgram(m_program);
            m_program = 0;
            return QStringLiteral("GL error 0x%1").arg(err, 0, 16);
        }
        return QString();
    }

    static GLuint compile(QOpenGLExtraFunctions *f, GLenum type, const QByteArray &src)
    {
        const GLuint s = f->glCreateShader(type);
        const char *p = src.constData();
        f->glShaderSource(s, 1, &p, nullptr);
        f->glCompileShader(s);
        GLint ok = 0;
        f->glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
        if (!ok) {
            char log[1024] = { 0 };
            f->glGetShaderInfoLog(s, sizeof(log) - 1, nullptr, log);
            qWarning("Benchymark: buffer stage shader: %s", log);
            f->glDeleteShader(s);
            return 0;
        }
        return s;
    }

    QQuickWindow *m_window = nullptr;
    QString m_mode;
    int m_lookups = 16;
    float m_t = 0;
    bool m_tried = false;
    QString m_report;
    GLuint m_program = 0;
    GLuint m_buffer = 0;
    GLuint m_texture = 0;
    GLint m_locT = -1, m_locAspect = -1, m_locLookups = -1;
};

BufferRead::BufferRead(QQuickItem *parent)
    : QQuickFramebufferObject(parent)
{
}

QQuickFramebufferObject::Renderer *BufferRead::createRenderer() const
{
    return new BufferReadRenderer;
}

void BufferRead::setMode(const QString &m)
{
    if (m == m_mode) return;
    m_mode = m;
    emit modeChanged();
}

void BufferRead::setLookups(int n)
{
    if (n == m_lookups) return;
    m_lookups = n;
    emit lookupsChanged();
    update();
}

void BufferRead::setT(qreal t)
{
    if (t == m_t) return;
    m_t = t;
    emit tChanged();
    update();
}

void BufferRead::setFailure(const QString &why)
{
    if (why == m_failure) return;
    m_failure = why;
    emit failureChanged();
}
