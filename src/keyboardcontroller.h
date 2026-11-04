#ifndef KEYBOARDCONTROLLER_H
#define KEYBOARDCONTROLLER_H

#include <QObject>
#include <QString>
#include <QTimer>

class KeyboardController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString sizeMode READ sizeMode WRITE setSizeMode NOTIFY sizeModeChanged)
    Q_PROPERTY(QString layoutMode READ layoutMode WRITE setLayoutMode NOTIFY layoutModeChanged)
    Q_PROPERTY(QString activeTheme READ activeTheme WRITE setActiveTheme NOTIFY activeThemeChanged)
    Q_PROPERTY(bool keyboardVisible READ keyboardVisible WRITE setKeyboardVisible NOTIFY keyboardVisibleChanged)
    Q_PROPERTY(bool isSplit READ isSplit WRITE setSplit NOTIFY isSplitChanged)
    Q_PROPERTY(bool isTerminalMode READ isTerminalMode WRITE setIsTerminalMode NOTIFY isTerminalModeChanged)
    Q_PROPERTY(bool isPasswordMode READ isPasswordMode WRITE setIsPasswordMode NOTIFY isPasswordModeChanged)
    Q_PROPERTY(bool isHardwareKeyboardConnected READ isHardwareKeyboardConnected NOTIFY hardwareKeyboardStatusChanged)
    Q_PROPERTY(bool backspaceDeletingWord READ backspaceDeletingWord NOTIFY backspaceDeletingWordChanged)
    // True while the Plasma lock screen is active (org.freedesktop.ScreenSaver)
    Q_PROPERTY(bool screenLocked READ screenLocked NOTIFY screenLockedChanged)
    // "panel" (zwp_input_panel_surface_v1, KWin-managed) or "layer" (wlr-layer-shell overlay)
    Q_PROPERTY(QString surfaceRole READ surfaceRole NOTIFY surfaceRoleChanged)
    // Whether the panel role can be used at all (only when KWin launched us)
    Q_PROPERTY(bool panelRoleAvailable READ panelRoleAvailable CONSTANT)

public:
    explicit KeyboardController(QObject *parent = nullptr);

    bool isPasswordMode() const { return m_isPasswordMode; }
    void setIsPasswordMode(bool passwordMode);
    Q_INVOKABLE void setContentHint(uint32_t flags);

    QString sizeMode() const { return m_sizeMode; }
    void setSizeMode(const QString &mode);

    QString layoutMode() const { return m_layoutMode; }
    void setLayoutMode(const QString &mode);

    QString activeTheme() const { return m_activeTheme; }
    void setActiveTheme(const QString &theme);

    bool isSplit() const { return m_isSplit; }
    void setSplit(bool split);

    bool isHardwareKeyboardConnected() const { return m_isHardwareKeyboardConnected; }
    bool backspaceDeletingWord() const { return m_backspaceDeletingWord; }

    bool isTerminalMode() const { return m_isTerminalMode; }
    void setIsTerminalMode(bool termMode);

    bool keyboardVisible() const { return m_keyboardVisible; }
    void setKeyboardVisible(bool visible);

    Q_INVOKABLE void startBackspaceTimer();
    Q_INVOKABLE void stopBackspaceTimer();
    Q_INVOKABLE void startKeyRepeat(uint32_t keycode);
    Q_INVOKABLE void stopKeyRepeat();
    Q_INVOKABLE void updateInputMask(QObject *windowObj, int x, int y, int width, int height);

    bool screenLocked() const { return m_screenLocked; }
    QString surfaceRole() const { return m_surfaceRole; }
    bool panelRoleAvailable() const;
    // Give the window the requested Wayland role, recreating its surface if needed.
    // The window keeps its visibility state.
    Q_INVOKABLE void applySurfaceRole(QObject *windowObj, const QString &role);

signals:
    void sizeModeChanged();
    void layoutModeChanged();
    void isSplitChanged();
    void isTerminalModeChanged();
    void isPasswordModeChanged();
    void activeThemeChanged();
    void keyboardVisibleChanged();
    void hardwareKeyboardStatusChanged();
    void backspaceDeletingWordChanged();
    void screenLockedChanged();
    void surfaceRoleChanged();
    void triggerBackspace();
    void triggerWordBackspace();
    void triggerKeyRepeat(uint32_t keycode);

private Q_SLOTS:
    void onScreenSaverActiveChanged(bool active);

private:
    void checkHardwareKeyboard();
    void watchScreenLock();
    bool m_screenLocked = false;
    QString m_surfaceRole;

    QString m_sizeMode{"normal"}; // "normal", "full", "onehand"
    QString m_layoutMode{"abc"};  // "abc", "accenti", "symbols", "numpad", "emoji", "klipper"
    QString m_activeTheme{"Auto"}; // "Auto" (KDE color scheme) or a file name in qml/themes/
    bool m_isSplit = false;
    bool m_isTerminalMode = false;
    bool m_isPasswordMode = false;
    bool m_isHardwareKeyboardConnected = false;
    bool m_backspaceDeletingWord = false;
    bool m_keyboardVisible = true;
    QTimer m_backspaceHoldTimer;
    QTimer m_backspaceRepeatTimer;
    int m_backspaceRepeatInterval = 100;
    QTimer m_keyRepeatHoldTimer;
    QTimer m_keyRepeatTimer;
    int m_keyRepeatInterval = 100;
    uint32_t m_currentRepeatKeycode = 0;
};

#endif // KEYBOARDCONTROLLER_H
