#include "inputpanelshell.h"

#include <QtWaylandClient/private/qwaylandwindow_p.h>
#include <QtWaylandClient/private/qwaylandscreen_p.h>
#include <QDebug>

InputPanelShellIntegration::InputPanelShellIntegration()
    : QWaylandShellIntegrationTemplate<InputPanelShellIntegration>(1)
{
}

InputPanelShellIntegration::~InputPanelShellIntegration()
{
    // zwp_input_panel_v1 has no destructor request
    if (object())
        wl_proxy_destroy(reinterpret_cast<wl_proxy *>(object()));
}

QtWaylandClient::QWaylandShellSurface *InputPanelShellIntegration::createShellSurface(QtWaylandClient::QWaylandWindow *window)
{
    return new InputPanelSurface(get_input_panel_surface(window->wlSurface()), window);
}

InputPanelShellIntegration *InputPanelShellIntegration::instance()
{
    static InputPanelShellIntegration *s_instance = nullptr;
    static bool s_tried = false;
    if (!s_tried) {
        s_tried = true;
        auto *integration = new InputPanelShellIntegration();
        if (integration->initialize(nullptr)) {
            s_instance = integration;
        } else {
            qInfo() << "zwp_input_panel_v1 not available (not launched by KWin as input method?)";
            delete integration;
        }
    }
    return s_instance;
}

InputPanelSurface::InputPanelSurface(::zwp_input_panel_surface_v1 *surface, QtWaylandClient::QWaylandWindow *window)
    : QtWaylandClient::QWaylandShellSurface(window)
    , QtWayland::zwp_input_panel_surface_v1(surface)
{
    // Toplevel keyboard panel, centred at the bottom of the output. KWin positions it.
    ::wl_output *output = window->waylandScreen() ? window->waylandScreen()->output() : nullptr;
    set_toplevel(output, position_center_bottom);
}

InputPanelSurface::~InputPanelSurface()
{
    // zwp_input_panel_surface_v1 has no destructor request
    if (object())
        wl_proxy_destroy(reinterpret_cast<wl_proxy *>(object()));
}
