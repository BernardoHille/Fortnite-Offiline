#include "Memory.h"
#include <limits>
#include <stdexcept>
namespace s13 {
bool Readable(std::uintptr_t at,std::size_t length,bool executable) {
  if(!at || !length || length>std::numeric_limits<std::uintptr_t>::max()-at) return false;
  auto end=at+length;
  while(at<end) {
    MEMORY_BASIC_INFORMATION m{};
    if(VirtualQuery(reinterpret_cast<void*>(at),&m,sizeof(m))!=sizeof(m) || m.State!=MEM_COMMIT || (m.Protect&(PAGE_GUARD|PAGE_NOACCESS))) return false;
    auto protection=m.Protect&0xff;
    bool read=protection==PAGE_READONLY || protection==PAGE_READWRITE || protection==PAGE_WRITECOPY || protection==PAGE_EXECUTE_READ || protection==PAGE_EXECUTE_READWRITE || protection==PAGE_EXECUTE_WRITECOPY;
    bool exec=protection==PAGE_EXECUTE_READ || protection==PAGE_EXECUTE_READWRITE || protection==PAGE_EXECUTE_WRITECOPY;
    if(!read || (executable && !exec)) return false;
    auto next=reinterpret_cast<std::uintptr_t>(m.BaseAddress)+m.RegionSize;
    if(next<=at) return false; at=next;
  }
  return true;
}
bool ReadMemory(std::uintptr_t at,void* output,std::size_t length) {
  if(!Readable(at,length)) return false; SIZE_T copied{};
  return ReadProcessMemory(GetCurrentProcess(),reinterpret_cast<void*>(at),output,length,&copied) && copied==length;
}
std::vector<std::uint8_t> SnapshotExecutable(std::uintptr_t base,const PeImage& pe) {
  std::vector<std::uint8_t> bytes(pe.imageSize);
  for(auto& s:pe.sections) if(s.flags&IMAGE_SCN_MEM_EXECUTE) {
    if(!ReadMemory(base+s.rva,bytes.data()+s.rva,s.virtualSize)) throw std::runtime_error("IMAGE_NOT_READABLE_NO_RETRY");
  }
  return bytes;
}
}
