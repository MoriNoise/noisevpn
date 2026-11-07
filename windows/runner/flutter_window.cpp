#include "flutter_window.h"

#include <optional>

#include <flutter_windows.h>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Smallest window, in logical pixels.
constexpr int kMinWidth = 960;
constexpr int kMinHeight = 640;

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  // Attach the view to this window BEFORE registering plugins. Flutter
  // creates the view under HWND_MESSAGE; flutter_vless looks up the main
  // window once, at registration, with GetAncestor(view, GA_ROOT), and posts
  // every start/stop result and status update there. Registered first, it
  // caches the wrong window, its messages are dropped, and the app waits
  // forever on "connecting" while the native side has already started.
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  RegisterPlugins(flutter_controller_->engine());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      if (flutter_controller_) {
        flutter_controller_->engine()->ReloadSystemFonts();
      }
      break;
    case WM_GETMINMAXINFO: {
      // Below this the desktop layout (sidebar + hero card) gets cramped.
      // Logical pixels, scaled to the monitor the window is on.
      const UINT dpi = FlutterDesktopGetDpiForMonitor(
          MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST));
      auto* info = reinterpret_cast<MINMAXINFO*>(lparam);
      info->ptMinTrackSize.x = MulDiv(kMinWidth, dpi, 96);
      info->ptMinTrackSize.y = MulDiv(kMinHeight, dpi, 96);
      return 0;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
