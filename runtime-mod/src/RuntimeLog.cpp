#include "RuntimeLog.h"
#include <filesystem>
#include <format>
#include <stdexcept>
namespace s13 {
RuntimeLog::RuntimeLog(const wchar_t* path) {
  std::filesystem::create_directories(std::filesystem::path(path).parent_path());
  file_=CreateFileW(path,FILE_APPEND_DATA,FILE_SHARE_READ|FILE_SHARE_WRITE,nullptr,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,nullptr);
  if(file_==INVALID_HANDLE_VALUE) throw std::runtime_error("LOG_OPEN");
}
RuntimeLog::~RuntimeLog() {if(file_!=INVALID_HANDLE_VALUE) CloseHandle(file_);}
void RuntimeLog::Write(const char* tag,const std::string& msg) {
  SYSTEMTIME t{}; GetLocalTime(&t);
  auto line=std::format("[{:02}:{:02}:{:02}.{:03}] [PID {}] [{}] {}\r\n",t.wHour,t.wMinute,t.wSecond,t.wMilliseconds,GetCurrentProcessId(),tag,msg);
  DWORD n{}; if(!WriteFile(file_,line.data(),static_cast<DWORD>(line.size()),&n,nullptr) || n!=line.size() || !FlushFileBuffers(file_)) throw std::runtime_error("LOG_WRITE");
}
std::string Hex(std::uintptr_t value) {return std::format("0x{:x}",value);}
}
