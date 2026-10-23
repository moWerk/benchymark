/*
 * SPDX-FileCopyrightText: 2026 Sebastian Matkovich <github.com/smatkovi>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include "GlesBench.h"

#include <QElapsedTimer>
#include <QImage>
#include <QMetaObject>
#include <QVector>

#include <EGL/egl.h>
#include <GLES2/gl2.h>

namespace {

// Shader heavy's fragment shader (qml/stages/ShaderHigh.qml), character for
// character apart from qt_Opacity, which does not exist here. Only the
// headers differ between ES 2 and ES 3; the precision qualifier is the one
// the QML stage uses, otherwise this would compare fp16 against fp32 instead
// of the roads.
const char *vertexHeader(bool es3)
{
    return es3 ? "#version 300 es\n#define IN in\n#define OUT out\n"
               : "#define IN attribute\n#define OUT varying\n";
}

const char *fragmentHeader(bool es3)
{
    return es3 ? "#version 300 es\n"
                 "precision highp float;\n"
                 "#define IN in\n"
                 "out vec4 outColor;\n#define FRAGCOLOR outColor\n"
               : "#ifdef GL_FRAGMENT_PRECISION_HIGH\n"
                 "precision highp float;\n"
                 "#else\n"
                 "precision mediump float;\n"
                 "#endif\n"
                 "#define IN varying\n"
                 "#define FRAGCOLOR gl_FragColor\n";
}

const char *vertexSource =
    "IN vec2 pos;\n"
    "OUT vec2 uv;\n"
    "void main() { uv = pos; gl_Position = vec4(pos * 2.0 - 1.0, 0.0, 1.0); }\n";

const char *fragmentSource =
    "IN vec2 uv;\n"
    "uniform float t;\n"
    "float hash(vec2 p)\n"
    "{\n"
    "    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);\n"
    "}\n"
    "float noise(vec2 p)\n"
    "{\n"
    "    vec2 i = floor(p);\n"
    "    vec2 f = fract(p);\n"
    "    vec2 u = f * f * (3.0 - 2.0 * f);\n"
    "    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),\n"
    "               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);\n"
    "}\n"
    "float fbm(vec2 p)\n"
    "{\n"
    "    float v = 0.0;\n"
    "    float a = 0.5;\n"
    "    for (int i = 0; i < 7; ++i) {\n"
    "        v += a * noise(p);\n"
    "        p *= 2.03;\n"
    "        a *= 0.5;\n"
    "    }\n"
    "    return v;\n"
    "}\n"
    "void main()\n"
    "{\n"
    "    vec2 p = uv * 2.0 - 1.0;\n"
    "    float r = length(p);\n"
    "    vec2 q = vec2(fbm(p * 3.0 + t * 0.090), fbm(p * 3.0 - t * 0.066));\n"
    "    vec2 s = vec2(fbm(p * 3.0 + q * 2.5 + t * 0.042),\n"
    "                  fbm(p * 3.0 + q * 2.5 - t * 0.054));\n"
    "    float v = fbm(p * 4.0 + s * 3.0);\n"
    "    vec3 col = mix(vec3(0.05, 0.10, 0.25), vec3(0.35, 0.85, 0.95), v);\n"
    "    col = mix(col, vec3(0.95, 0.55, 0.25), clamp(s.x * 0.6, 0.0, 1.0));\n"
    "    col *= mix(0.70, 1.0, smoothstep(1.04, 0.66, r));\n"
    "    FRAGCOLOR = vec4(col, 1.0);\n"
    "}\n";

GLuint compile(GLenum type, const char *header, const char *body, QString *error)
{
    const char *parts[2] = { header, body };
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 2, parts, nullptr);
    glCompileShader(shader);
    GLint ok = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char log[2048] = { 0 };
        glGetShaderInfoLog(shader, sizeof log - 1, nullptr, log);
        *error = QStringLiteral("shader: %1").arg(QString::fromLatin1(log).simplified().left(120));
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

} // namespace

GlesEngine::GlesEngine(QObject *parent) : QObject(parent) {}

GlesEngine::~GlesEngine() { stop(); }

void GlesEngine::report(int phase, const QString &reason)
{
    {
        QMutexLocker lock(&m_lock);
        m_phase = phase;
        if (!reason.isEmpty())
            m_reason = reason;
    }
    QMetaObject::invokeMethod(this, "changed", Qt::QueuedConnection);
}

void GlesEngine::start(int w, int h)
{
    stop();
    if (w < 16 || h < 16) {
        report(-1, QStringLiteral("area too small"));
        return;
    }
    m_stop.store(0);
    m_thread = new FunctionThread([this, w, h] { work(w, h); });
    m_thread->start();
}

void GlesEngine::stop()
{
    m_stop.store(1);
    if (m_thread) {
        m_thread->wait();
        delete m_thread;
        m_thread = nullptr;
    }
}

void GlesEngine::work(int w, int h)
{
    const bool es3 = m_wanted >= 3;

    // The app's display. eglInitialize is reference counted, a second call
    // does no harm; eglTerminate is deliberately nowhere in this file, it
    // would close the display Qt is drawing on.
    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (display == EGL_NO_DISPLAY) {
        report(-1, QStringLiteral("no EGL display"));
        return;
    }
    EGLint major = 0, minor = 0;
    if (!eglInitialize(display, &major, &minor)) {
        report(-1, QStringLiteral("eglInitialize 0x%1").arg(eglGetError(), 0, 16));
        return;
    }

    EGLint configAttrs[] = { EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
                             EGL_RENDERABLE_TYPE, es3 ? 0x00000040 /* ES3 */ : EGL_OPENGL_ES2_BIT,
                             EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8,
                             EGL_ALPHA_SIZE, 8, EGL_NONE };
    EGLConfig config;
    EGLint configs = 0;
    if (!eglChooseConfig(display, configAttrs, &config, 1, &configs) || !configs) {
        report(-1, QStringLiteral("no pbuffer config for ES %1").arg(es3 ? 3 : 2));
        return;
    }
    EGLint pbufferAttrs[] = { EGL_WIDTH, 16, EGL_HEIGHT, 16, EGL_NONE };
    EGLSurface surface = eglCreatePbufferSurface(display, config, pbufferAttrs);
    EGLint contextAttrs[] = { EGL_CONTEXT_CLIENT_VERSION, es3 ? 3 : 2, EGL_NONE };
    EGLContext context = eglCreateContext(display, config, EGL_NO_CONTEXT, contextAttrs);
    if (surface == EGL_NO_SURFACE || context == EGL_NO_CONTEXT ||
        !eglMakeCurrent(display, surface, surface, context)) {
        report(-1, QStringLiteral("no ES %1 context").arg(es3 ? 3 : 2));
        if (context != EGL_NO_CONTEXT) eglDestroyContext(display, context);
        if (surface != EGL_NO_SURFACE) eglDestroySurface(display, surface);
        return;
    }

    const auto glString = [](GLenum name) {
        const GLubyte *v = glGetString(name);
        return v ? QString::fromLatin1(reinterpret_cast<const char *>(v)) : QString();
    };
    // GPU time is an extension in GLES; without it the wall clock around
    // glFinish() has to do.
    void (*glGenQueriesEXT)(GLsizei, GLuint *) = nullptr;
    void (*glBeginQueryEXT)(GLenum, GLuint) = nullptr;
    void (*glEndQueryEXT)(GLenum) = nullptr;
    void (*glGetQueryObjectui64vEXT)(GLuint, GLenum, quint64 *) = nullptr;
    GLuint timeQuery = 0;
    if (glString(GL_EXTENSIONS).contains(QLatin1String("GL_EXT_disjoint_timer_query"))) {
        glGenQueriesEXT = reinterpret_cast<void (*)(GLsizei, GLuint *)>(eglGetProcAddress("glGenQueriesEXT"));
        glBeginQueryEXT = reinterpret_cast<void (*)(GLenum, GLuint)>(eglGetProcAddress("glBeginQueryEXT"));
        glEndQueryEXT = reinterpret_cast<void (*)(GLenum)>(eglGetProcAddress("glEndQueryEXT"));
        glGetQueryObjectui64vEXT = reinterpret_cast<void (*)(GLuint, GLenum, quint64 *)>(
                                       eglGetProcAddress("glGetQueryObjectui64vEXT"));
        if (glGenQueriesEXT && glBeginQueryEXT && glEndQueryEXT && glGetQueryObjectui64vEXT)
            glGenQueriesEXT(1, &timeQuery);
    }
    {
        QMutexLocker lock(&m_lock);
        m_glVersion = glString(GL_VERSION);
    }

    const auto giveUp = [&](const QString &reason) {
        report(-1, reason);
        eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroyContext(display, context);
        eglDestroySurface(display, surface);
    };

    // The target: a framebuffer in memory, the size of the stage area
    GLuint texture = 0, fbo = 0;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        giveUp(QStringLiteral("framebuffer incomplete"));
        return;
    }
    glViewport(0, 0, w, h);

    QString error;
    GLuint vert = compile(GL_VERTEX_SHADER, vertexHeader(es3), vertexSource, &error);
    GLuint frag = vert ? compile(GL_FRAGMENT_SHADER, fragmentHeader(es3), fragmentSource, &error) : 0;
    GLuint program = 0;
    if (vert && frag) {
        program = glCreateProgram();
        glAttachShader(program, vert);
        glAttachShader(program, frag);
        glBindAttribLocation(program, 0, "pos");
        glLinkProgram(program);
        GLint ok = 0;
        glGetProgramiv(program, GL_LINK_STATUS, &ok);
        if (!ok) {
            char log[2048] = { 0 };
            glGetProgramInfoLog(program, sizeof log - 1, nullptr, log);
            error = QStringLiteral("program: %1").arg(QString::fromLatin1(log).simplified().left(120));
            program = 0;
        }
    }
    if (!program) {
        giveUp(error.isEmpty() ? QStringLiteral("shader rejected") : error);
        return;
    }
    glUseProgram(program);
    const GLint uniformT = glGetUniformLocation(program, "t");

    static const GLfloat triangle[] = { 0.0f, 0.0f, 2.0f, 0.0f, 0.0f, 2.0f };
    GLuint vbo = 0;
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof triangle, triangle, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, nullptr);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);

    QVector<uchar> pixels(size_t(w) * h * 4);
    QElapsedTimer clock;
    clock.start();
    QElapsedTimer preview;
    preview.start();
    report(2);

    while (!m_stop.load()) {
        // t as in Shader heavy: one unit per second
        const float t = float(clock.elapsed()) / 1000.0f;
        QElapsedTimer wall;
        wall.start();
        if (timeQuery)
            glBeginQueryEXT(0x88BF /* GL_TIME_ELAPSED_EXT */, timeQuery);
        glClearColor(0.02f, 0.04f, 0.10f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        glUniform1f(uniformT, t);
        glDrawArrays(GL_TRIANGLES, 0, 3);
        if (timeQuery)
            glEndQueryEXT(0x88BF);
        glFinish();
        double ms = double(wall.nsecsElapsed()) / 1.0e6;
        if (timeQuery) {
            quint64 ns = 0;
            glGetQueryObjectui64vEXT(timeQuery, 0x8866 /* GL_QUERY_RESULT */, &ns);
            if (ns)
                ms = double(ns) / 1.0e6;
        }

        m_since.ref();
        {
            QMutexLocker lock(&m_lock);
            if (qint64(ms * 1.0e6) > m_worstNs)
                m_worstNs = qint64(ms * 1.0e6);
        }

        if (m_view && preview.elapsed() >= 1000) {
            preview.restart();
            glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, pixels.data());
            // GL starts at the bottom: flip while shrinking
            m_view->setPicture(OffscreenView::shrink(pixels.constData(), w, h, 4, true));
        }
    }

    glDeleteBuffers(1, &vbo);
    glDeleteProgram(program);
    glDeleteShader(vert);
    glDeleteShader(frag);
    glDeleteFramebuffers(1, &fbo);
    glDeleteTextures(1, &texture);
    eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    eglDestroyContext(display, context);
    eglDestroySurface(display, surface);
    report(3);
}
