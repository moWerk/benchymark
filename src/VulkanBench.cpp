/*
 * SPDX-FileCopyrightText: 2026 Sebastian Matkovich <github.com/smatkovi>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include "VulkanBench.h"

#include <QElapsedTimer>
#include <QMetaObject>
#include <QPainter>
#include <QVector>
#include <dlfcn.h>
#include <vulkan/vulkan.h>

#include "vulkan-spv.h"

// The entry points, fetched at run time: nothing is linked, so the app still
// starts where libvulkan is missing.
#define VK_LIST(X)                                                             \
    X(vkCreateInstance) X(vkDestroyInstance) X(vkEnumeratePhysicalDevices)     \
    X(vkGetPhysicalDeviceProperties) X(vkGetPhysicalDeviceQueueFamilyProperties)\
    X(vkGetPhysicalDeviceMemoryProperties) X(vkCreateDevice) X(vkDestroyDevice)\
    X(vkGetDeviceQueue) X(vkDeviceWaitIdle) X(vkCreateCommandPool)             \
    X(vkDestroyCommandPool) X(vkAllocateCommandBuffers) X(vkBeginCommandBuffer)\
    X(vkEndCommandBuffer) X(vkResetCommandBuffer) X(vkCreateFence)             \
    X(vkDestroyFence) X(vkWaitForFences) X(vkResetFences) X(vkQueueSubmit)     \
    X(vkCreateQueryPool) X(vkDestroyQueryPool) X(vkCmdResetQueryPool)          \
    X(vkCmdWriteTimestamp) X(vkGetQueryPoolResults) X(vkCreateImage)           \
    X(vkDestroyImage) X(vkGetImageMemoryRequirements) X(vkAllocateMemory)      \
    X(vkFreeMemory) X(vkBindImageMemory) X(vkCreateImageView)                  \
    X(vkDestroyImageView) X(vkCreateRenderPass) X(vkDestroyRenderPass)         \
    X(vkCreateFramebuffer) X(vkDestroyFramebuffer) X(vkCreateBuffer)           \
    X(vkDestroyBuffer) X(vkGetBufferMemoryRequirements) X(vkBindBufferMemory)  \
    X(vkMapMemory) X(vkUnmapMemory) X(vkCreateShaderModule)                    \
    X(vkDestroyShaderModule) X(vkCreatePipelineLayout)                         \
    X(vkDestroyPipelineLayout) X(vkCreateGraphicsPipelines) X(vkDestroyPipeline)\
    X(vkCmdBeginRenderPass) X(vkCmdEndRenderPass) X(vkCmdBindPipeline)         \
    X(vkCmdPushConstants) X(vkCmdDraw) X(vkCmdCopyImageToBuffer)

namespace {

struct Api {
#define ENTRY(n) PFN_##n n = nullptr;
    VK_LIST(ENTRY)
#undef ENTRY
    void *lib = nullptr;

    bool load(QString *reason)
    {
        lib = dlopen("libvulkan.so.1", RTLD_NOW | RTLD_LOCAL);
        if (!lib)
            lib = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
        if (!lib) {
            *reason = QStringLiteral("no libvulkan.so.1");
            return false;
        }
#define FETCH(n)                                                               \
    n = reinterpret_cast<PFN_##n>(dlsym(lib, #n));                             \
    if (!n) { *reason = QStringLiteral(#n " missing"); return false; }
        VK_LIST(FETCH)
#undef FETCH
        return true;
    }

    void close()
    {
        if (lib) {
            dlclose(lib);
            lib = nullptr;
        }
    }
};

// Everything one run holds, so that tearing down is in one place.
struct Run {
    Api vk;
    VkInstance instance = VK_NULL_HANDLE;
    VkPhysicalDevice phys = VK_NULL_HANDLE;
    VkDevice dev = VK_NULL_HANDLE;
    VkQueue queue = VK_NULL_HANDLE;
    VkCommandPool pool = VK_NULL_HANDLE;
    VkCommandBuffer cmd = VK_NULL_HANDLE;
    VkCommandBuffer copyCmd = VK_NULL_HANDLE;
    VkFence fence = VK_NULL_HANDLE;
    VkQueryPool queries = VK_NULL_HANDLE;
    VkImage image = VK_NULL_HANDLE;
    VkDeviceMemory imageMem = VK_NULL_HANDLE;
    VkImageView imageView = VK_NULL_HANDLE;
    VkRenderPass pass = VK_NULL_HANDLE;
    VkFramebuffer fb = VK_NULL_HANDLE;
    VkBuffer readBuf = VK_NULL_HANDLE;
    VkDeviceMemory readMem = VK_NULL_HANDLE;
    void *readMap = nullptr;
    VkPipelineLayout layout = VK_NULL_HANDLE;
    VkPipeline pipeline = VK_NULL_HANDLE;
    float timestampNs = 1.0f;
    bool hasTimestamps = false;

    uint32_t memoryType(uint32_t mask, VkMemoryPropertyFlags want) const
    {
        VkPhysicalDeviceMemoryProperties mp;
        vk.vkGetPhysicalDeviceMemoryProperties(phys, &mp);
        for (uint32_t i = 0; i < mp.memoryTypeCount; i++)
            if ((mask & (1u << i)) && (mp.memoryTypes[i].propertyFlags & want) == want)
                return i;
        return UINT32_MAX;
    }

    void teardown()
    {
        if (dev) {
            vk.vkDeviceWaitIdle(dev);
            if (pipeline) vk.vkDestroyPipeline(dev, pipeline, nullptr);
            if (layout) vk.vkDestroyPipelineLayout(dev, layout, nullptr);
            if (readMap) vk.vkUnmapMemory(dev, readMem);
            if (readBuf) vk.vkDestroyBuffer(dev, readBuf, nullptr);
            if (readMem) vk.vkFreeMemory(dev, readMem, nullptr);
            if (fb) vk.vkDestroyFramebuffer(dev, fb, nullptr);
            if (pass) vk.vkDestroyRenderPass(dev, pass, nullptr);
            if (imageView) vk.vkDestroyImageView(dev, imageView, nullptr);
            if (image) vk.vkDestroyImage(dev, image, nullptr);
            if (imageMem) vk.vkFreeMemory(dev, imageMem, nullptr);
            if (queries) vk.vkDestroyQueryPool(dev, queries, nullptr);
            if (fence) vk.vkDestroyFence(dev, fence, nullptr);
            if (pool) vk.vkDestroyCommandPool(dev, pool, nullptr);
            vk.vkDestroyDevice(dev, nullptr);
            dev = VK_NULL_HANDLE;
        }
        if (instance)
            vk.vkDestroyInstance(instance, nullptr);
        instance = VK_NULL_HANDLE;
        vk.close();
    }
};

VkShaderModule shaderModule(Run &r, const uint32_t *words, size_t bytes)
{
    VkShaderModuleCreateInfo ci = {};
    ci.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    ci.codeSize = bytes;
    ci.pCode = words;
    VkShaderModule m = VK_NULL_HANDLE;
    if (r.vk.vkCreateShaderModule(r.dev, &ci, nullptr, &m) != VK_SUCCESS)
        return VK_NULL_HANDLE;
    return m;
}

} // namespace

// ---- OffscreenView ------------------------------------------------------
OffscreenView::OffscreenView(QQuickItem *parent) : QQuickPaintedItem(parent)
{
    setOpaquePainting(true);
}

void OffscreenView::paint(QPainter *painter)
{
    QImage picture;
    {
        QMutexLocker lock(&m_lock);
        picture = m_picture;
    }
    if (picture.isNull()) {
        painter->fillRect(boundingRect(), QColor(8, 14, 30));
        return;
    }
    painter->setRenderHint(QPainter::SmoothPixmapTransform, true);
    painter->drawImage(boundingRect(), picture);
}

QImage OffscreenView::shrink(const uchar *pixels, int w, int h, int step, bool flip)
{
    const int sw = qMax(1, w / step);
    const int sh = qMax(1, h / step);
    QImage small(sw, sh, QImage::Format_RGBA8888);
    for (int y = 0; y < sh; y++) {
        const int sy = flip ? (h - 1 - y * step) : (y * step);
        const uchar *row = pixels + qint64(sy) * w * 4;
        uchar *dst = small.scanLine(y);
        for (int x = 0; x < sw; x++)
            memcpy(dst + x * 4, row + qint64(x) * step * 4, 4);
    }
    return small;
}

void OffscreenView::setPicture(const QImage &picture)
{
    {
        QMutexLocker lock(&m_lock);
        m_picture = picture;
    }
    QMetaObject::invokeMethod(this, "update", Qt::QueuedConnection);
}

// ---- VulkanEngine -------------------------------------------------------
VulkanEngine::VulkanEngine(QObject *parent) : QObject(parent) {}

VulkanEngine::~VulkanEngine() { stop(); }

void VulkanEngine::report(int phase, const QString &reason)
{
    {
        QMutexLocker lock(&m_lock);
        m_phase = phase;
        if (!reason.isEmpty())
            m_reason = reason;
    }
    QMetaObject::invokeMethod(this, "changed", Qt::QueuedConnection);
}

void VulkanEngine::start(int w, int h)
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

void VulkanEngine::stop()
{
    m_stop.store(1);
    if (m_thread) {
        m_thread->wait();
        delete m_thread;
        m_thread = nullptr;
    }
}

void VulkanEngine::work(int w, int h)
{
    Run r;
    QString reason;
    if (!r.vk.load(&reason)) {
        report(-1, reason);
        return;
    }

    VkApplicationInfo ai = {};
    ai.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    ai.pApplicationName = "harbour-benchymark";
    ai.apiVersion = VK_API_VERSION_1_0;
    VkInstanceCreateInfo ici = {};
    ici.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    ici.pApplicationInfo = &ai;
    VkResult res = r.vk.vkCreateInstance(&ici, nullptr, &r.instance);
    if (res != VK_SUCCESS) {
        report(-1, QStringLiteral("vkCreateInstance %1").arg(int(res)));
        r.teardown();
        return;
    }

    uint32_t count = 0;
    r.vk.vkEnumeratePhysicalDevices(r.instance, &count, nullptr);
    if (!count) {
        report(-1, QStringLiteral("no Vulkan device"));
        r.teardown();
        return;
    }
    QVector<VkPhysicalDevice> devices;
    devices.resize(int(count));
    r.vk.vkEnumeratePhysicalDevices(r.instance, &count, devices.data());
    r.phys = devices[0];

    VkPhysicalDeviceProperties props;
    r.vk.vkGetPhysicalDeviceProperties(r.phys, &props);
    r.timestampNs = props.limits.timestampPeriod;
    {
        QMutexLocker lock(&m_lock);
        m_device = QString::fromLatin1(props.deviceName);
        m_api = QStringLiteral("%1.%2.%3").arg(VK_VERSION_MAJOR(props.apiVersion))
                    .arg(VK_VERSION_MINOR(props.apiVersion)).arg(VK_VERSION_PATCH(props.apiVersion));
    }

    uint32_t families = 0;
    r.vk.vkGetPhysicalDeviceQueueFamilyProperties(r.phys, &families, nullptr);
    QVector<VkQueueFamilyProperties> fams;
    fams.resize(int(families));
    r.vk.vkGetPhysicalDeviceQueueFamilyProperties(r.phys, &families, fams.data());
    uint32_t family = UINT32_MAX;
    for (uint32_t i = 0; i < families; i++)
        if (fams[int(i)].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
            family = i;
            r.hasTimestamps = fams[int(i)].timestampValidBits > 0;
            break;
        }
    if (family == UINT32_MAX) {
        report(-1, QStringLiteral("no graphics queue"));
        r.teardown();
        return;
    }

    const float priority = 1.0f;
    VkDeviceQueueCreateInfo qci = {};
    qci.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    qci.queueFamilyIndex = family;
    qci.queueCount = 1;
    qci.pQueuePriorities = &priority;
    VkDeviceCreateInfo dci = {};
    dci.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    dci.queueCreateInfoCount = 1;
    dci.pQueueCreateInfos = &qci;
    if (r.vk.vkCreateDevice(r.phys, &dci, nullptr, &r.dev) != VK_SUCCESS) {
        report(-1, QStringLiteral("vkCreateDevice failed"));
        r.teardown();
        return;
    }
    r.vk.vkGetDeviceQueue(r.dev, family, 0, &r.queue);

    VkCommandPoolCreateInfo pci = {};
    pci.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    pci.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    pci.queueFamilyIndex = family;
    r.vk.vkCreateCommandPool(r.dev, &pci, nullptr, &r.pool);
    VkCommandBufferAllocateInfo cbi = {};
    cbi.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    cbi.commandPool = r.pool;
    cbi.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    cbi.commandBufferCount = 1;
    r.vk.vkAllocateCommandBuffers(r.dev, &cbi, &r.cmd);
    r.vk.vkAllocateCommandBuffers(r.dev, &cbi, &r.copyCmd);
    VkFenceCreateInfo fci = {};
    fci.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    r.vk.vkCreateFence(r.dev, &fci, nullptr, &r.fence);
    VkQueryPoolCreateInfo qpi = {};
    qpi.sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO;
    qpi.queryType = VK_QUERY_TYPE_TIMESTAMP;
    qpi.queryCount = 2;
    if (r.hasTimestamps)
        r.vk.vkCreateQueryPool(r.dev, &qpi, nullptr, &r.queries);

    // The target: an image in memory, the size of the stage area
    VkImageCreateInfo imi = {};
    imi.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
    imi.imageType = VK_IMAGE_TYPE_2D;
    imi.format = VK_FORMAT_R8G8B8A8_UNORM;
    imi.extent.width = uint32_t(w);
    imi.extent.height = uint32_t(h);
    imi.extent.depth = 1;
    imi.mipLevels = 1;
    imi.arrayLayers = 1;
    imi.samples = VK_SAMPLE_COUNT_1_BIT;
    imi.tiling = VK_IMAGE_TILING_OPTIMAL;
    imi.usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
    imi.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    if (r.vk.vkCreateImage(r.dev, &imi, nullptr, &r.image) != VK_SUCCESS) {
        report(-1, QStringLiteral("vkCreateImage failed"));
        r.teardown();
        return;
    }
    VkMemoryRequirements need;
    r.vk.vkGetImageMemoryRequirements(r.dev, r.image, &need);
    VkMemoryAllocateInfo mai = {};
    mai.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    mai.allocationSize = need.size;
    mai.memoryTypeIndex = r.memoryType(need.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
    if (mai.memoryTypeIndex == UINT32_MAX ||
        r.vk.vkAllocateMemory(r.dev, &mai, nullptr, &r.imageMem) != VK_SUCCESS) {
        report(-1, QStringLiteral("no image memory"));
        r.teardown();
        return;
    }
    r.vk.vkBindImageMemory(r.dev, r.image, r.imageMem, 0);

    VkImageViewCreateInfo ivi = {};
    ivi.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
    ivi.image = r.image;
    ivi.viewType = VK_IMAGE_VIEW_TYPE_2D;
    ivi.format = VK_FORMAT_R8G8B8A8_UNORM;
    ivi.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    ivi.subresourceRange.levelCount = 1;
    ivi.subresourceRange.layerCount = 1;
    r.vk.vkCreateImageView(r.dev, &ivi, nullptr, &r.imageView);

    // After the pass the image is ready as a transfer source, so fetching the
    // preview needs no barrier of its own.
    VkAttachmentDescription att = {};
    att.format = VK_FORMAT_R8G8B8A8_UNORM;
    att.samples = VK_SAMPLE_COUNT_1_BIT;
    att.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
    att.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
    att.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    att.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    att.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    att.finalLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
    VkAttachmentReference ref = {};
    ref.attachment = 0;
    ref.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
    VkSubpassDescription sub = {};
    sub.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
    sub.colorAttachmentCount = 1;
    sub.pColorAttachments = &ref;
    VkSubpassDependency dep[2] = {};
    dep[0].srcSubpass = VK_SUBPASS_EXTERNAL;
    dep[0].dstSubpass = 0;
    dep[0].srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    dep[0].dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    dep[0].dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
    dep[1].srcSubpass = 0;
    dep[1].dstSubpass = VK_SUBPASS_EXTERNAL;
    dep[1].srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    dep[1].dstStageMask = VK_PIPELINE_STAGE_TRANSFER_BIT;
    dep[1].srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
    dep[1].dstAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
    VkRenderPassCreateInfo rpi = {};
    rpi.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
    rpi.attachmentCount = 1;
    rpi.pAttachments = &att;
    rpi.subpassCount = 1;
    rpi.pSubpasses = &sub;
    rpi.dependencyCount = 2;
    rpi.pDependencies = dep;
    r.vk.vkCreateRenderPass(r.dev, &rpi, nullptr, &r.pass);

    VkFramebufferCreateInfo fbi = {};
    fbi.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
    fbi.renderPass = r.pass;
    fbi.attachmentCount = 1;
    fbi.pAttachments = &r.imageView;
    fbi.width = uint32_t(w);
    fbi.height = uint32_t(h);
    fbi.layers = 1;
    r.vk.vkCreateFramebuffer(r.dev, &fbi, nullptr, &r.fb);

    // buffer for the preview
    VkBufferCreateInfo bci = {};
    bci.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bci.size = VkDeviceSize(w) * h * 4;
    bci.usage = VK_BUFFER_USAGE_TRANSFER_DST_BIT;
    bci.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    r.vk.vkCreateBuffer(r.dev, &bci, nullptr, &r.readBuf);
    r.vk.vkGetBufferMemoryRequirements(r.dev, r.readBuf, &need);
    mai.allocationSize = need.size;
    mai.memoryTypeIndex = r.memoryType(need.memoryTypeBits,
                                       VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
                                       VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    if (mai.memoryTypeIndex != UINT32_MAX &&
        r.vk.vkAllocateMemory(r.dev, &mai, nullptr, &r.readMem) == VK_SUCCESS) {
        r.vk.vkBindBufferMemory(r.dev, r.readBuf, r.readMem, 0);
        r.vk.vkMapMemory(r.dev, r.readMem, 0, VK_WHOLE_SIZE, 0, &r.readMap);
    }

    // pipeline: full-screen triangle, Shader heavy's field
    VkShaderModule vert = shaderModule(r, kSpvFullscreenVert, sizeof kSpvFullscreenVert);
    VkShaderModule frag = shaderModule(r, kSpvCloudFrag, sizeof kSpvCloudFrag);
    if (!vert || !frag) {
        report(-1, QStringLiteral("shader rejected"));
        r.teardown();
        return;
    }
    VkPushConstantRange push = {};
    push.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT;
    push.size = sizeof(float);
    VkPipelineLayoutCreateInfo pli = {};
    pli.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    pli.pushConstantRangeCount = 1;
    pli.pPushConstantRanges = &push;
    r.vk.vkCreatePipelineLayout(r.dev, &pli, nullptr, &r.layout);

    VkPipelineShaderStageCreateInfo stages[2] = {};
    stages[0].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    stages[0].stage = VK_SHADER_STAGE_VERTEX_BIT;
    stages[0].module = vert;
    stages[0].pName = "main";
    stages[1].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    stages[1].stage = VK_SHADER_STAGE_FRAGMENT_BIT;
    stages[1].module = frag;
    stages[1].pName = "main";
    VkPipelineVertexInputStateCreateInfo vin = {};
    vin.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
    VkPipelineInputAssemblyStateCreateInfo asm_ = {};
    asm_.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
    asm_.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
    VkViewport viewport = { 0, 0, float(w), float(h), 0.0f, 1.0f };
    VkRect2D scissor = { { 0, 0 }, { uint32_t(w), uint32_t(h) } };
    VkPipelineViewportStateCreateInfo vp = {};
    vp.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
    vp.viewportCount = 1;
    vp.pViewports = &viewport;
    vp.scissorCount = 1;
    vp.pScissors = &scissor;
    VkPipelineRasterizationStateCreateInfo ras = {};
    ras.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
    ras.polygonMode = VK_POLYGON_MODE_FILL;
    ras.cullMode = VK_CULL_MODE_NONE;
    ras.frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE;
    ras.lineWidth = 1.0f;
    VkPipelineMultisampleStateCreateInfo ms = {};
    ms.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
    ms.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;
    VkPipelineColorBlendAttachmentState blendAtt = {};
    blendAtt.colorWriteMask = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT |
                              VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT;
    VkPipelineColorBlendStateCreateInfo blend = {};
    blend.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
    blend.attachmentCount = 1;
    blend.pAttachments = &blendAtt;
    VkGraphicsPipelineCreateInfo gpi = {};
    gpi.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
    gpi.stageCount = 2;
    gpi.pStages = stages;
    gpi.pVertexInputState = &vin;
    gpi.pInputAssemblyState = &asm_;
    gpi.pViewportState = &vp;
    gpi.pRasterizationState = &ras;
    gpi.pMultisampleState = &ms;
    gpi.pColorBlendState = &blend;
    gpi.layout = r.layout;
    gpi.renderPass = r.pass;
    VkResult pres = r.vk.vkCreateGraphicsPipelines(r.dev, VK_NULL_HANDLE, 1, &gpi, nullptr,
                                                   &r.pipeline);
    r.vk.vkDestroyShaderModule(r.dev, vert, nullptr);
    r.vk.vkDestroyShaderModule(r.dev, frag, nullptr);
    if (pres != VK_SUCCESS) {
        report(-1, QStringLiteral("pipeline %1").arg(int(pres)));
        r.teardown();
        return;
    }

    QElapsedTimer clock;
    clock.start();
    QElapsedTimer preview;
    preview.start();
    report(2);

    while (!m_stop.load()) {
        // t as in Shader heavy: the QML animation runs 0..10000 over 10000
        // seconds, so one unit per second.
        const float t = float(clock.elapsed()) / 1000.0f;

        r.vk.vkResetCommandBuffer(r.cmd, 0);
        VkCommandBufferBeginInfo begin = {};
        begin.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
        r.vk.vkBeginCommandBuffer(r.cmd, &begin);
        if (r.queries) {
            r.vk.vkCmdResetQueryPool(r.cmd, r.queries, 0, 2);
            r.vk.vkCmdWriteTimestamp(r.cmd, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, r.queries, 0);
        }
        VkClearValue clear = {};
        clear.color.float32[0] = 0.02f;
        clear.color.float32[1] = 0.04f;
        clear.color.float32[2] = 0.10f;
        clear.color.float32[3] = 1.0f;
        VkRenderPassBeginInfo rbi = {};
        rbi.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
        rbi.renderPass = r.pass;
        rbi.framebuffer = r.fb;
        rbi.renderArea = scissor;
        rbi.clearValueCount = 1;
        rbi.pClearValues = &clear;
        r.vk.vkCmdBeginRenderPass(r.cmd, &rbi, VK_SUBPASS_CONTENTS_INLINE);
        r.vk.vkCmdBindPipeline(r.cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, r.pipeline);
        r.vk.vkCmdPushConstants(r.cmd, r.layout, VK_SHADER_STAGE_FRAGMENT_BIT, 0,
                                sizeof(float), &t);
        r.vk.vkCmdDraw(r.cmd, 3, 1, 0, 0);
        r.vk.vkCmdEndRenderPass(r.cmd);
        if (r.queries)
            r.vk.vkCmdWriteTimestamp(r.cmd, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, r.queries, 1);
        r.vk.vkEndCommandBuffer(r.cmd);

        QElapsedTimer wall;
        wall.start();
        VkSubmitInfo si = {};
        si.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
        si.commandBufferCount = 1;
        si.pCommandBuffers = &r.cmd;
        if (r.vk.vkQueueSubmit(r.queue, 1, &si, r.fence) != VK_SUCCESS) {
            report(-1, QStringLiteral("vkQueueSubmit failed"));
            r.teardown();
            return;
        }
        r.vk.vkWaitForFences(r.dev, 1, &r.fence, VK_TRUE, 5000000000ull);
        r.vk.vkResetFences(r.dev, 1, &r.fence);
        double ms = double(wall.nsecsElapsed()) / 1.0e6;
        if (r.queries) {
            uint64_t stamps[2] = { 0, 0 };
            if (r.vk.vkGetQueryPoolResults(r.dev, r.queries, 0, 2, sizeof stamps, stamps,
                                           sizeof(uint64_t), VK_QUERY_RESULT_64_BIT) == VK_SUCCESS &&
                stamps[1] > stamps[0])
                ms = double(stamps[1] - stamps[0]) * double(r.timestampNs) / 1.0e6;
        }

        m_since.ref();
        {
            QMutexLocker lock(&m_lock);
            if (qint64(ms * 1.0e6) > m_worstNs)
                m_worstNs = qint64(ms * 1.0e6);
        }

        // once a second: fetch the picture for the preview
        if (r.readMap && m_view && preview.elapsed() >= 1000) {
            preview.restart();
            VkCommandBufferBeginInfo cb = {};
            cb.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
            cb.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
            r.vk.vkResetCommandBuffer(r.copyCmd, 0);
            r.vk.vkBeginCommandBuffer(r.copyCmd, &cb);
            VkBufferImageCopy copy = {};
            copy.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
            copy.imageSubresource.layerCount = 1;
            copy.imageExtent.width = uint32_t(w);
            copy.imageExtent.height = uint32_t(h);
            copy.imageExtent.depth = 1;
            r.vk.vkCmdCopyImageToBuffer(r.copyCmd, r.image, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                                        r.readBuf, 1, &copy);
            r.vk.vkEndCommandBuffer(r.copyCmd);
            VkSubmitInfo cs = {};
            cs.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
            cs.commandBufferCount = 1;
            cs.pCommandBuffers = &r.copyCmd;
            r.vk.vkQueueSubmit(r.queue, 1, &cs, r.fence);
            r.vk.vkWaitForFences(r.dev, 1, &r.fence, VK_TRUE, 5000000000ull);
            r.vk.vkResetFences(r.dev, 1, &r.fence);
            m_view->setPicture(OffscreenView::shrink(
                reinterpret_cast<const uchar *>(r.readMap), w, h, 4, false));
        }
    }

    report(3);
    r.teardown();
}
