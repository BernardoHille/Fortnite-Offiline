#pragma once
#include <Windows.h>
#include <string>
namespace s13 {
class RuntimeLog {
  HANDLE file_=INVALID_HANDLE_VALUE;
public:
  explicit RuntimeLog(const wchar_t* path);
  ~RuntimeLog();
  RuntimeLog(const RuntimeLog&)=delete; RuntimeLog& operator=(const RuntimeLog&)=delete;
  void Write(const char* tag,const std::string& message);
};
std::string Hex(std::uintptr_t value);
}
