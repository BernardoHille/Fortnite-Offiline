#include "Season13BuildGuard.h"
#include "Season13Runtime.h"
#include "Season13Target.h"
#include "PatternScanner.h"
#include "RuntimeAddresses.h"
#include "RuntimeLog.h"
#include <TlHelp32.h>
#include <filesystem>
#include <iostream>
#include <stdexcept>
namespace {
struct Handle {
  HANDLE h{}; explicit Handle(HANDLE v):h(v){} ~Handle(){if(h && h!=INVALID_HANDLE_VALUE) CloseHandle(h);}
  Handle(const Handle&)=delete; Handle& operator=(const Handle&)=delete;
};
MODULEENTRY32W Module(DWORD pid,const std::wstring& name) {
  Handle snap(CreateToolhelp32Snapshot(TH32CS_SNAPMODULE|TH32CS_SNAPMODULE32,pid));
  if(snap.h==INVALID_HANDLE_VALUE) throw std::runtime_error("MODULE_SNAPSHOT_ACCESS_DENIED_NO_WORKAROUND");
  MODULEENTRY32W m{};m.dwSize=sizeof(m);
  if(Module32FirstW(snap.h,&m)) do {if(!_wcsicmp(m.szModule,name.c_str())) return m;} while(Module32NextW(snap.h,&m));
  throw std::runtime_error("MODULE_NOT_FOUND");
}
std::uintptr_t SystemFunction(DWORD pid,const char* function) {
  auto fn=GetProcAddress(GetModuleHandleW(L"kernel32.dll"),function); HMODULE local{};
  if(!fn || !GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS|GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,reinterpret_cast<LPCWSTR>(fn),&local)) throw std::runtime_error("SYSTEM_FUNCTION");
  wchar_t path[32768]{};if(!GetModuleFileNameW(local,path,32768)) throw std::runtime_error("SYSTEM_MODULE_PATH");
  auto remote=Module(pid,std::filesystem::path(path).filename().wstring());
  if(_wcsicmp(s13::CanonicalPath(path).c_str(),s13::CanonicalPath(remote.szExePath).c_str())) throw std::runtime_error("SYSTEM_MODULE_PATH_MISMATCH");
  auto bytes=s13::ReadFileBytes(path); auto pe=s13::PeImage::Parse(bytes);
  auto rva=reinterpret_cast<std::uintptr_t>(fn)-reinterpret_cast<std::uintptr_t>(local);
  if(rva>=remote.modBaseSize || !pe.Executable(static_cast<std::uint32_t>(rva))) throw std::runtime_error("SYSTEM_FUNCTION_RVA");
  return reinterpret_cast<std::uintptr_t>(remote.modBaseAddr)+rva;
}
DWORD RemoteCall(HANDLE process,std::uintptr_t function,const void* data,std::size_t bytes) {
  auto parameter=VirtualAllocEx(process,nullptr,bytes,MEM_COMMIT|MEM_RESERVE,PAGE_READWRITE);
  if(!parameter) throw std::runtime_error("REMOTE_ALLOCATION_DENIED_NO_WORKAROUND");
  SIZE_T written{};
  if(!WriteProcessMemory(process,parameter,data,bytes,&written) || written!=bytes) {VirtualFreeEx(process,parameter,0,MEM_RELEASE);throw std::runtime_error("REMOTE_PARAMETER_WRITE");}
  Handle thread(CreateRemoteThread(process,nullptr,0,reinterpret_cast<LPTHREAD_START_ROUTINE>(function),parameter,0,nullptr));
  if(!thread.h) {VirtualFreeEx(process,parameter,0,MEM_RELEASE);throw std::runtime_error("REMOTE_THREAD_DENIED_NO_WORKAROUND");}
  auto status=WaitForSingleObject(thread.h,120000);
  if(status!=WAIT_OBJECT_0) {
    // Parameter remains owned by the running thread. Never free, terminate, retry or unload under it.
    throw std::runtime_error("REMOTE_THREAD_TIMEOUT_OR_WAIT_FAILED_STOP_TARGET_BEFORE_RETRY");
  }
  DWORD code{};bool ok=GetExitCodeThread(thread.h,&code)!=FALSE;
  if(!VirtualFreeEx(process,parameter,0,MEM_RELEASE)) throw std::runtime_error("REMOTE_PARAMETER_CLEANUP_FAILED_STOP_TARGET");
  if(!ok) throw std::runtime_error("REMOTE_THREAD_EXIT_QUERY");return code;
}
void Attach(DWORD pid,DWORD milestone) {
  Handle process(OpenProcess(PROCESS_QUERY_INFORMATION|PROCESS_VM_READ|PROCESS_VM_WRITE|PROCESS_VM_OPERATION|PROCESS_CREATE_THREAD|SYNCHRONIZE,FALSE,pid));
  if(!process.h) throw std::runtime_error("OPENPROCESS_DENIED_NO_PRIVILEGE_OR_ANTICHEAT_WORKAROUND");
  wchar_t exe[32768]{};DWORD length=32768;
  if(!QueryFullProcessImageNameW(process.h,0,exe,&length)) throw std::runtime_error("TARGET_PATH_QUERY");
  auto id=s13::ValidateTarget(exe);auto main=Module(pid,L"FortniteClient-Win64-Shipping.exe");
  std::uint8_t header[4096]{};SIZE_T read{};
  if(!ReadProcessMemory(process.h,main.modBaseAddr,header,sizeof(header),&read)||read!=sizeof(header)) throw std::runtime_error("TARGET_HEADERS_UNREADABLE");
  auto mapped=s13::PeImage::Parse(header);
  if(mapped.machine!=id.pe.machine||mapped.imageSize!=id.pe.imageSize||mapped.timestamp!=id.pe.timestamp||main.modBaseSize!=id.pe.imageSize) throw std::runtime_error("TARGET_LOADED_IMAGE_MISMATCH");
  wchar_t self[32768]{};if(!GetModuleFileNameW(nullptr,self,32768)) throw std::runtime_error("CONTROLLER_PATH");
  auto dll=(std::filesystem::path(self).parent_path()/L"Season13Runtime.dll").wstring();
  auto bytes=s13::ReadFileBytes(dll);auto pe=s13::PeImage::Parse(bytes);auto entry=pe.Export(bytes,"Season13Start");
  bool alreadyLoaded=false;
  try {Module(pid,L"Season13Runtime.dll");alreadyLoaded=true;} catch(const std::exception& e) {if(std::string(e.what())!="MODULE_NOT_FOUND") throw;}
  if(alreadyLoaded) throw std::runtime_error("DLL_ALREADY_LOADED_USE_FRESH_REVIEWED_RUN");
  s13::RuntimeLog log(s13::LogFile);
  log.Write("CONTROLLER","Validated target PID="+std::to_string(pid)+"; milestone R"+std::to_string(milestone)+"; original EXE unchanged");
  RemoteCall(process.h,SystemFunction(pid,"LoadLibraryW"),dll.c_str(),(dll.size()+1)*sizeof(wchar_t));
  auto loaded=Module(pid,L"Season13Runtime.dll");
  if(_wcsicmp(s13::CanonicalPath(loaded.szExePath).c_str(),s13::CanonicalPath(dll).c_str()) || loaded.modBaseSize!=pe.imageSize) throw std::runtime_error("LOADED_DLL_MISMATCH");
  s13::RuntimeRequest request;request.milestone=milestone;
  auto result=RemoteCall(process.h,reinterpret_cast<std::uintptr_t>(loaded.modBaseAddr)+entry,&request,sizeof(request));
  log.Write("CONTROLLER","Runtime result="+std::to_string(result)+"; DLL remains idle; end target normally before next run");
  if(result) throw std::runtime_error("RUNTIME_FAILED_SEE_LOG_STOP_TARGET");
}
}
int wmain(int argc,wchar_t** argv) {
  try {
    if(argc==3 && std::wstring(argv[1])==L"--inspect") {
      auto id=s13::ValidateTarget(argv[2]);auto b=s13::ReadFileBytes(argv[2]);
      std::cout<<"[Season13Runtime] OFFLINE FILE INSPECTION ONLY\nBuild: 13.40 CL 14113327\nSHA256: "<<id.hash<<"\nSizeOfImage: "<<s13::Hex(id.pe.imageSize)<<"\nTimestamp: "<<s13::Hex(id.pe.timestamp)<<"\n";
      for(auto item : {std::pair{"GObjects",s13::ObjectArrayPattern}, {"GObjectsAlternate",s13::ObjectArrayAlternate},{"NameToString",s13::NameToStringPattern},{"Realloc",s13::ReallocPattern}}) {
        auto r=s13::ScanImage(b,id.pe,item.second,false);
        std::cout<<item.first<<": file matches="<<r.matches.size()<<(r.matches.size()==2?"+":"")<<"\n";
        if(r.matches.size()==1) std::cout<<"Instruction/function RVA: "<<s13::Hex(r.matches[0])<<" (RuntimeValidated=NO)\n";
      }
      return 0;
    }
    if(argc==6 && std::wstring(argv[1])==L"--attach" && std::wstring(argv[3])==L"--milestone" && std::wstring(argv[5])==L"--permit-local-runtime") {
      std::size_t used{};auto pid=std::stoul(argv[2],&used);
      if(used!=wcslen(argv[2]) || !pid || pid>MAXDWORD || pid==GetCurrentProcessId()) throw std::runtime_error("INVALID_PID");
      std::wstring stage=argv[4];if(stage!=L"0" && stage!=L"1") throw std::runtime_error("ONLY_R0_R1_IMPLEMENTED");
      Attach(static_cast<DWORD>(pid),stage==L"1"?1:0);return 0;
    }
    std::cout<<"Offline: --inspect <exact-target-exe>\nFuture reviewed execution only: --attach <PID> --milestone <0|1> --permit-local-runtime\nNo launch, default attach, auth, security hooks, network, or other milestones.\n";return 2;
  } catch(const std::exception& e) {std::cerr<<"FAIL: "<<e.what()<<"\n";return 1;}
}
