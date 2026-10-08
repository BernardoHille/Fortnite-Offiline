#include "FName.h"
#include "Memory.h"
namespace s13 {
struct Name {std::int32_t comparison,number;};
struct String {std::uintptr_t data;std::int32_t count,capacity;};
// FES GetNameString ABI, isolated from C++ stack unwinding. Runtime/thread safety is NOT TESTED.
static bool Convert(const RuntimeAddresses* a,const Name* name,String* out,DWORD* code,std::uintptr_t* fault) {
  __try { reinterpret_cast<void(*)(const Name*,String*)>(a->nameToString)(name,out); return true; }
  __except((*code=GetExceptionCode(),*fault=reinterpret_cast<std::uintptr_t>(GetExceptionInformation()->ExceptionRecord->ExceptionAddress),EXCEPTION_EXECUTE_HANDLER)) {return false;}
}
static bool Release(const RuntimeAddresses* a,std::uintptr_t data,DWORD* code,std::uintptr_t* fault) {
  __try { reinterpret_cast<void*(*)(void*,std::uint64_t,std::uint32_t)>(a->realloc)(reinterpret_cast<void*>(data),0,0); return true; }
  __except((*code=GetExceptionCode(),*fault=reinterpret_cast<std::uintptr_t>(GetExceptionInformation()->ExceptionRecord->ExceptionAddress),EXCEPTION_EXECUTE_HANDLER)) {return false;}
}
NameResult ReadName(const ObjectView& o,const RuntimeAddresses& a) {
  NameResult result; Name n{o.nameIndex,o.nameNumber}; String text{};
  if(!Convert(&a,&n,&text,&result.exception,&result.fault)) return result;
  bool valid=text.count>0 && text.count<=256 && text.capacity>=text.count && text.capacity<=4096 && text.data;
  if(valid) {
    std::wstring value(static_cast<std::size_t>(text.count),L'\0');
    valid=ReadMemory(text.data,value.data(),value.size()*2) && value.back()==L'\0';
    if(valid) {value.pop_back();valid=!value.empty();for(auto c:value) if(c<32 || c==127) valid=false; result.text=std::move(value);}
  }
  // Only free a pointer returned by the verified conversion function, never a stack/foreign buffer.
  if(!valid || !Readable(text.data,static_cast<std::size_t>(text.capacity)*2)) return result;
  if(text.data && !Release(&a,text.data,&result.exception,&result.fault)) return result;
  result.ok=valid; return result;
}
}
