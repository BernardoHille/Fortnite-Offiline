#include "Season13Runtime.h"
#include "Memory.h"
#include <atomic>
static std::atomic_flag entered=ATOMIC_FLAG_INIT;
extern "C" __declspec(dllexport) DWORD WINAPI Season13Start(void* parameter) {
  s13::RuntimeRequest request{};
  if(!s13::ReadMemory(reinterpret_cast<std::uintptr_t>(parameter),&request,sizeof(request)) || request.magic!=s13::RequestMagic || request.milestone>1) return 2;
  if(entered.test_and_set()) return 3;
  return s13::Initialize(request);
}
BOOL WINAPI DllMain(HINSTANCE instance,DWORD reason,LPVOID) {
  if(reason==DLL_PROCESS_ATTACH) DisableThreadLibraryCalls(instance);
  return TRUE; // No scan, UE calls, thread, logging, hooks, networking or gameplay under loader lock.
}
