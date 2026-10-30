#pragma once

#include <QObject>
#include <QQuickItem>
#include <QVariantMap>
#include <qqmlintegration.h>

namespace caelestia {

// Recovery is restricted to Quickshell's session-lock windows. It never
// changes visibility, the Wayland surface role, or authentication state.
class LockRenderRecovery : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    Q_INVOKABLE static QVariantMap state(QQuickItem* target);
    Q_INVOKABLE static bool afterResume(QQuickItem* target);
    Q_INVOKABLE static bool ifStalled(QQuickItem* target);
};

} // namespace caelestia
