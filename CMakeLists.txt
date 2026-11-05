cmake_minimum_required(VERSION 3.22)

project(huskie-board VERSION 0.91 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

find_package(ECM 6.0.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml DBus GuiPrivate WaylandClient WaylandClientPrivate)
find_package(KF6CoreAddons REQUIRED)
find_package(KF6I18n REQUIRED)
find_package(PkgConfig REQUIRED)
find_package(Wayland REQUIRED COMPONENTS Client)

pkg_check_modules(WAYLAND_CLIENT REQUIRED wayland-client)
find_program(WAYLAND_SCANNER_EXECUTABLE NAMES wayland-scanner REQUIRED)

# Generate Wayland virtual keyboard protocol C/H files
set(PROTOCOL_XML "${CMAKE_CURRENT_SOURCE_DIR}/src/protocols/virtual-keyboard-unstable-v1.xml")
set(PROTOCOL_CODE "${CMAKE_CURRENT_BINARY_DIR}/virtual-keyboard-unstable-v1-protocol.c")
set(PROTOCOL_HEADER "${CMAKE_CURRENT_BINARY_DIR}/virtual-keyboard-unstable-v1-client-protocol.h")

add_custom_command(
    OUTPUT ${PROTOCOL_HEADER}
    COMMAND ${WAYLAND_SCANNER_EXECUTABLE} client-header ${PROTOCOL_XML} ${PROTOCOL_HEADER}
    DEPENDS ${PROTOCOL_XML}
)

add_custom_command(
    OUTPUT ${PROTOCOL_CODE}
    COMMAND ${WAYLAND_SCANNER_EXECUTABLE} private-code ${PROTOCOL_XML} ${PROTOCOL_CODE}
    DEPENDS ${PROTOCOL_XML}
)

# input-method-unstable-v1: KWin's protocols for the virtual keyboard process
# (zwp_input_method_v1 for typing, zwp_input_panel_v1 for the keyboard surface)
pkg_get_variable(WAYLAND_PROTOCOLS_DIR wayland-protocols pkgdatadir)
set(IM_XML "${WAYLAND_PROTOCOLS_DIR}/unstable/input-method/input-method-unstable-v1.xml")

# Optional LayerShellQt support
find_package(LayerShellQt)

qt_add_executable(huskie-board
    src/main.cpp
    src/securebuffer.h
    src/keyboardcontroller.cpp
    src/keyboardcontroller.h
    src/waylandvirtualkeyboard.cpp
    src/waylandvirtualkeyboard.h
    src/gestureengine.cpp
    src/gestureengine.h
    src/klipperintegration.cpp
    src/klipperintegration.h
    ${PROTOCOL_CODE}
    ${PROTOCOL_HEADER}
    src/inputpanelshell.cpp
    src/inputpanelshell.h
)

qt6_generate_wayland_protocol_client_sources(huskie-board PRIVATE_CODE NO_INCLUDE_CORE_ONLY FILES ${IM_XML})

target_include_directories(huskie-board PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(huskie-board PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::GuiPrivate
    Qt6::Quick
    Qt6::Qml
    Qt6::DBus
    Qt6::WaylandClient
    Qt6::WaylandClientPrivate
    KF6::CoreAddons
    KF6::I18n
    Wayland::Client
)

if(LayerShellQt_FOUND)
    target_link_libraries(huskie-board PRIVATE LayerShellQt::Interface)
    target_compile_definitions(huskie-board PRIVATE HAVE_LAYERSHELLQT=1)
endif()

# Embed QML under qrc:/qt/qml/ (Qt's default import path). With the old "/" prefix the
# module is only found when the binary runs from its build directory.
qt_policy(SET QTP0001 NEW)

qt_add_qml_module(huskie-board
    URI "HuskieBoard"
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/KeyButton.qml
        qml/SwipeCanvas.qml
        qml/TouchBarView.qml
        qml/OptionPill.qml
        qml/IconButton.qml
        qml/ExtendedLayout.qml
        qml/QwertyLayout.qml
        qml/KeyIcon.qml
        qml/ValueSlider.qml
        qml/Elevation.qml
        qml/M3Switch.qml
        qml/M3Segmented.qml
        qml/Accents.js
        qml/themes/KdeAuto.qml
        qml/themes/BreezeLight.qml
        qml/themes/BreezeDark.qml
        qml/themes/TeenageOP1.qml
        qml/themes/NothingDark.qml
        qml/themes/NothingLight.qml
        qml/themes/HackerMatrix.qml
        qml/themes/Cyberpunk2077.qml
        qml/themes/DraculaDark.qml
        qml/themes/NordFrost.qml
)

include(GNUInstallDirs)
install(TARGETS huskie-board RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES huskie-board.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)

# Make the Plasma Login Manager greeter use Huskie-board (it hard-codes plasma-keyboard)
option(HUSKIE_LOGIN_SCREEN "Install a drop-in so Plasma Login Manager uses Huskie-board" ON)
if(HUSKIE_LOGIN_SCREEN)
    install(FILES packaging/plasma-login/huskie-board.conf
            DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/systemd/user/plasma-login-kwin_wayland.service.d)
endif()
