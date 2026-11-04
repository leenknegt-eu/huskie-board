#ifndef INPUTPANELSHELL_H
#define INPUTPANELSHELL_H

// Qt Wayland shell integration that gives a QWindow the zwp_input_panel_surface_v1
// role (input-method-unstable-v1). This is the surface type KWin treats as "the
// virtual keyboard": it is placed at the bottom of the screen, apps are moved out
// of its way, and it is the only kind of keyboard surface shown on the lock screen.
// KDE's own plasma-keyboard and Maliit use the same approach.

#include <QtWaylandClient/private/qwaylandshellintegration_p.h>
#include <QtWaylandClient/private/qwaylandshellsurface_p.h>

#include "qwayland-input-method-unstable-v1.h"

class InputPanelShellIntegration
    : public QtWaylandClient::QWaylandShellIntegrationTemplate<InputPanelShellIntegration>,
      public QtWayland::zwp_input_panel_v1
{
public:
    InputPanelShellIntegration();
    ~InputPanelShellIntegration() override;

    QtWaylandClient::QWaylandShellSurface *createShellSurface(QtWaylandClient::QWaylandWindow *window) override;

    // Shared instance; nullptr if the compositor doesn't offer zwp_input_panel_v1
    // (KWin only offers it to the input method process it launched).
    static InputPanelShellIntegration *instance();
};

class InputPanelSurface : public QtWaylandClient::QWaylandShellSurface,
                          public QtWayland::zwp_input_panel_surface_v1
{
public:
    InputPanelSurface(::zwp_input_panel_surface_v1 *surface, QtWaylandClient::QWaylandWindow *window);
    ~InputPanelSurface() override;
};

#endif // INPUTPANELSHELL_H
