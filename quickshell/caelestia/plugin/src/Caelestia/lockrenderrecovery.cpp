#include "lockrenderrecovery.hpp"

#include <QGuiApplication>
#include <QLoggingCategory>
#include <QMutexLocker>
#include <QQuickWindow>
#include <QThread>
#include <QtWaylandClient/private/qwaylandwindow_p.h>

Q_LOGGING_CATEGORY(lcLockRender, "caelestia.lock.render", QtInfoMsg)

namespace caelestia {
namespace {

// This workaround uses Qt's private frame bookkeeping. Keep it confined to
// the Qt minor whose layout was checked, and reject runtime/build mismatches.
// A new Qt minor needs review, not an unchecked cast into its private state.
#if QT_VERSION >= QT_VERSION_CHECK(6, 12, 0) && QT_VERSION < QT_VERSION_CHECK(6, 13, 0)
constexpr bool supported = true;

// Form pointers to inherited protected members; apply those pointers to the
// actual QWaylandWindow. No downcast to a fabricated subclass is involved.
struct FrameAccess : QtWaylandClient::QWaylandWindow {
    static constexpr auto callback = &FrameAccess::mFrameCallback;
    static constexpr auto mutex = &FrameAccess::mFrameSyncMutex;
    static constexpr auto wait = &FrameAccess::mFrameSyncWait;
    static constexpr auto elapsed = &FrameAccess::mFrameCallbackElapsedTimer;
    static constexpr auto timeout = &FrameAccess::mFrameCallbackTimedOut;
    static constexpr auto timer = &FrameAccess::mFrameCallbackCheckIntervalTimerId;
};
#else
constexpr bool supported = false;
#endif

QtWaylandClient::QWaylandWindow* lockWindow(QQuickItem* target) {
    if (!supported || qstrcmp(qVersion(), QT_VERSION_STR) != 0 || !target)
        return nullptr;
    auto* window = target->window();
    if (!window || window->thread() != QThread::currentThread() || !window->isVisible())
        return nullptr;

    // Quickshell attaches this opaque extension only to WlSessionLockSurface
    // windows. Do not touch normal application windows or layer-shell panels.
    const auto extension = window->property("sessionlock_ext");
    if (!extension.isValid() || extension.isNull()
        || QByteArray(extension.metaType().name()) != "LockWindowExtension*")
        return nullptr;

    return dynamic_cast<QtWaylandClient::QWaylandWindow*>(window->handle());
}

bool recover(QQuickItem* target, bool resumed) {
#if QT_VERSION >= QT_VERSION_CHECK(6, 12, 0) && QT_VERSION < QT_VERSION_CHECK(6, 13, 0)
    auto* platform = lockWindow(target);
    if (!platform)
        return false;

    bool pending;
    bool timedOut;
    {
        QMutexLocker locker(&(platform->*FrameAccess::mutex));
        auto& callback = platform->*FrameAccess::callback;
        timedOut = platform->*FrameAccess::timeout;
        pending = callback != nullptr;
        if (!resumed && !timedOut)
            return false;

        // Match QWaylandWindow::resetFrameCallback(), without resetting the
        // surface role. A callback registered across suspend may never arrive;
        // ordinary update()/focus requests are still gated on that callback.
        if (callback) {
            wl_callback_destroy(callback);
            callback = nullptr;
        }
        (platform->*FrameAccess::elapsed).invalidate();
        (platform->*FrameAccess::wait).wakeAll();
    }

    auto& timer = platform->*FrameAccess::timer;
    if (timer != -1) {
        platform->killTimer(timer);
        timer = -1;
    }
    platform->*FrameAccess::timeout = false;

    // Preserve queued updates and dirty state; only remove the stale frame
    // gate, restore exposure, and ask Qt Quick to present its current content.
    platform->updateExposure();
    target->window()->update();
    if (pending || timedOut)
        qCInfo(lcLockRender) << "Recovered lock frame" << (resumed ? "after resume" : "after timeout")
                            << "pending:" << pending << "timedOut:" << timedOut;
    return pending || timedOut;
#else
    Q_UNUSED(target)
    Q_UNUSED(resumed)
    return false;
#endif
}

} // namespace

QVariantMap LockRenderRecovery::state(QQuickItem* target) {
    QVariantMap result {
        { "supported", supported && qstrcmp(qVersion(), QT_VERSION_STR) == 0 },
        { "qtBuild", QT_VERSION_STR },
        { "qtRuntime", qVersion() },
        { "lockWindow", false },
    };
    auto* platform = lockWindow(target);
    if (!platform)
        return result;

    result.insert("lockWindow", true);
    result.insert("exposed", target->window()->isExposed());
    result.insert("platformExposed", platform->isExposed());
#if QT_VERSION >= QT_VERSION_CHECK(6, 12, 0) && QT_VERSION < QT_VERSION_CHECK(6, 13, 0)
    QMutexLocker locker(&(platform->*FrameAccess::mutex));
    result.insert("framePending", (platform->*FrameAccess::callback) != nullptr);
    result.insert("callbackTimedOut", (platform->*FrameAccess::timeout).load());
#endif
    return result;
}

bool LockRenderRecovery::afterResume(QQuickItem* target) { return recover(target, true); }
bool LockRenderRecovery::ifStalled(QQuickItem* target) { return recover(target, false); }

} // namespace caelestia
