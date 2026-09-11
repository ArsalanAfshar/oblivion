#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // The desktop shell settles on a phone-like 440x700 frame once Dart takes
  // over; start at that size, centred, so the window never visibly jumps.
  const int width = 440;
  const int height = 700;
  const int screen_width = ::GetSystemMetrics(SM_CXSCREEN);
  const int screen_height = ::GetSystemMetrics(SM_CYSCREEN);
  Win32Window::Point origin(
      (screen_width > width) ? (screen_width - width) / 2 : 0,
      (screen_height > height) ? (screen_height - height) / 2 : 0);
  Win32Window::Size size(width, height);
  if (!window.Create(L"Oblivion", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
