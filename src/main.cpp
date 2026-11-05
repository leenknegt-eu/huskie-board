#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <KLocalizedString>
#include <QFile>
#include <QStandardPaths>

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
    app.setApplicationName("huskie-board");
    app.setDesktopFileName("huskie-board");

    // One-time settings migration from the old "tastiera" name
    {
        const QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/KDE/");
        const QString oldConf = dir + QStringLiteral("tastiera.conf");
        const QString newConf = dir + QStringLiteral("huskie-board.conf");
        if (!QFile::exists(newConf) && QFile::exists(oldConf) && QFile::copy(oldConf, newConf))
            qInfo() << "Migrated settings from" << oldConf;
    }

    qmlRegisterType<KeyboardController>("HuskieBoard", 1, 0, "KeyboardController");
    qmlRegisterType<WaylandVirtualKeyboard>("HuskieBoard", 1, 0, "WaylandVirtualKeyboard");
    qmlRegisterType<GestureEngine>("HuskieBoard", 1, 0, "GestureEngine");
    qmlRegisterType<KlipperIntegration>("HuskieBoard", 1, 0, "KlipperIntegration");

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

    engine.loadFromModule("HuskieBoard", "Main");

    return app.exec();
}
