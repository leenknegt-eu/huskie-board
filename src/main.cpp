#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <KLocalizedString>

#include "keyboardcontroller.h"
#include "waylandvirtualkeyboard.h"
#include "gestureengine.h"
#include "klipperintegration.h"


#include <sys/prctl.h>
#include <sys/resource.h>

static void setupProcessSecurity() {
    // Impedisce la creazione di crash dump contenenti la RAM del processo
    prctl(PR_SET_DUMPABLE, 0);

    // Imposta la dimensione massima dei coredump a 0
    rlimit rl = {0, 0};
    setrlimit(RLIMIT_CORE, &rl);
}

int main(int argc, char *argv[])
{
    setvbuf(stdout, NULL, _IONBF, 0);
    setupProcessSecurity();

    // Wayland-only application: never fall back to xcb when launched from a bare environment
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM"))
        qputenv("QT_QPA_PLATFORM", "wayland");

    QGuiApplication app(argc, argv);
    app.setOrganizationName("KDE");
    app.setOrganizationDomain("kde.org");
    app.setApplicationName("tastiera");
    app.setDesktopFileName("tastiera");

    qmlRegisterType<KeyboardController>("Tastiera", 1, 0, "KeyboardController");
    qmlRegisterType<WaylandVirtualKeyboard>("Tastiera", 1, 0, "WaylandVirtualKeyboard");
    qmlRegisterType<GestureEngine>("Tastiera", 1, 0, "GestureEngine");
    qmlRegisterType<KlipperIntegration>("Tastiera", 1, 0, "KlipperIntegration");

    QQmlApplicationEngine engine;

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [](QObject *obj, const QUrl &) {
        if (!obj) {
            QCoreApplication::exit(-1);
            return;
        }

        auto *window = qobject_cast<QQuickWindow *>(obj);
        if (window) {
            // Explicitly set window flags to bypass tiling window managers (Krohnkite, Bspwm, etc.)
            window->setFlags(Qt::Window | Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint | Qt::BypassWindowManagerHint | Qt::WindowDoesNotAcceptFocus);

            // QML picks the surface role (input panel / layer shell) and whether to show now
            QMetaObject::invokeMethod(window, "start");
        }
    }, Qt::QueuedConnection);

    engine.loadFromModule("Tastiera", "Main");

    return app.exec();
}
