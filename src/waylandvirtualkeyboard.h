#ifndef WAYLANDVIRTUALKEYBOARD_H
#define WAYLANDVIRTUALKEYBOARD_H

#include <QObject>
#include <QString>
#include <wayland-client.h>

struct zwp_virtual_keyboard_manager_v1;
struct zwp_virtual_keyboard_v1;
struct zwp_input_method_v1;
struct zwp_input_method_context_v1;

class WaylandVirtualKeyboard : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionChanged)
    // True when KWin launched us as its input method (zwp_input_method_v1 available)
    Q_PROPERTY(bool hasInputMethod READ hasInputMethod NOTIFY connectionChanged)
    // True while a text field is focused (KWin sent activate, not yet deactivate)
    Q_PROPERTY(bool imActive READ imActive NOTIFY imActiveChanged)
    // True when the focused field is a password / sensitive-data field
    Q_PROPERTY(bool sensitiveInput READ sensitiveInput NOTIFY sensitiveInputChanged)

public:
    explicit WaylandVirtualKeyboard(QObject *parent = nullptr);
    ~WaylandVirtualKeyboard();

    bool isConnected() const { return m_virtualKeyboard != nullptr || m_inputMethod != nullptr; }
    bool hasInputMethod() const { return m_inputMethod != nullptr; }
    bool imActive() const { return m_imContext != nullptr; }
    bool sensitiveInput() const { return m_sensitiveInput; }

    Q_INVOKABLE void sendKey(uint32_t keycode, bool pressed = true);
    Q_INVOKABLE void pressAndReleaseKey(uint32_t keycode);
    Q_INVOKABLE void sendKeySym(uint32_t keysym);
    Q_INVOKABLE void sendText(const QString &text);
    Q_INVOKABLE void sendEmoji(const QString &emoji);
    Q_INVOKABLE void sendCombo(uint32_t modifier, uint32_t keycode);
    Q_INVOKABLE void sendBackspace();
    Q_INVOKABLE void sendCtrlBackspace();
    Q_INVOKABLE void sendMouseMove(int dx, int dy);
    Q_INVOKABLE void sendMouseClick(int button = 1, bool pressed = true);
    Q_INVOKABLE void sendMouseScroll(int deltaX, int deltaY);

signals:
    void connectionChanged();
    void imActiveChanged();
    void sensitiveInputChanged();

private:
    void initWayland();
    void createKeymap();
    static void registryHandleGlobal(void *data, struct wl_registry *registry, uint32_t name, const char *interface, uint32_t version);
    static void registryHandleGlobalRemove(void *data, struct wl_registry *registry, uint32_t name);

    struct wl_display *m_display{nullptr};
    struct wl_registry *m_registry{nullptr};
    struct wl_seat *m_seat{nullptr};
    struct zwp_virtual_keyboard_manager_v1 *m_manager{nullptr};
    struct zwp_virtual_keyboard_v1 *m_virtualKeyboard{nullptr};
    int m_keymapFd{-1};
    size_t m_keymapSize{0};
    int m_uinputFd{-1};
    bool m_uinputTried{false};
    void ensureUinput();   // lazily created: only used when no text field is active
    void sendUinputKey(uint32_t keycode, bool pressed);

    // input-method-unstable-v1 (KWin's protocol for the virtual keyboard process)
    struct zwp_input_method_v1 *m_inputMethod{nullptr};
    struct zwp_input_method_context_v1 *m_imContext{nullptr};
    uint32_t m_imSerial{0};
    bool m_sensitiveInput{false};
    bool imSendKey(uint32_t evdevKeycode, uint32_t modifier);
    void setSensitiveInput(bool sensitive);

public:
    // C callbacks (public so the static listener tables can reference them)
    static void imActivate(void *data, struct zwp_input_method_v1 *im, struct zwp_input_method_context_v1 *ctx);
    static void imDeactivate(void *data, struct zwp_input_method_v1 *im, struct zwp_input_method_context_v1 *ctx);
    static void ctxSurroundingText(void *, struct zwp_input_method_context_v1 *, const char *, uint32_t, uint32_t) {}
    static void ctxReset(void *, struct zwp_input_method_context_v1 *) {}
    static void ctxContentType(void *data, struct zwp_input_method_context_v1 *ctx, uint32_t hint, uint32_t purpose);
    static void ctxInvokeAction(void *, struct zwp_input_method_context_v1 *, uint32_t, uint32_t) {}
    static void ctxCommitState(void *data, struct zwp_input_method_context_v1 *ctx, uint32_t serial);
    static void ctxPreferredLanguage(void *, struct zwp_input_method_context_v1 *, const char *) {}
};

#endif // WAYLANDVIRTUALKEYBOARD_H
