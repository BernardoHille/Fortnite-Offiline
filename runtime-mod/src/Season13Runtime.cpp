#include "Season13Runtime.h"
#include "Season13BuildGuard.h"
#include "Season13Target.h"
#include "RuntimeAddresses.h"
#include "RuntimeLog.h"
#include "ObjectArray.h"
#include "FName.h"
#include <exception>
#include <memory>
#include <stdexcept>
namespace s13 {
DWORD Initialize(const RuntimeRequest& req) {
  std::unique_ptr<RuntimeLog> log;
  try {
    log=std::make_unique<RuntimeLog>(LogFile); log->Write("BOOT","Season13Runtime entered; milestone R"+std::to_string(req.milestone));
    wchar_t exe[32768]{}; if(!GetModuleFileNameW(nullptr,exe,32768)) throw std::runtime_error("EXE_PATH");
    auto id=ValidateTarget(exe); auto base=reinterpret_cast<std::uintptr_t>(GetModuleHandleW(nullptr));
    std::uint8_t header[4096]{}; if(!ReadMemory(base,header,sizeof(header))) throw std::runtime_error("IMAGE_HEADERS");
    auto mapped=PeImage::Parse(header);
    if(mapped.imageSize!=id.pe.imageSize || mapped.timestamp!=id.pe.timestamp) throw std::runtime_error("LOADED_HEADER_MISMATCH");
    log->Write("BUILD","13.40 CL 14113327; exact path/file size/AMD64/full SHA256/build strings validated");
    log->Write("PE","BaseAddress="+Hex(base)+" ImageSize="+Hex(id.pe.imageSize)+" Timestamp="+Hex(id.pe.timestamp));
    log->Write("R0","PASS; no gameplay changes"); if(req.milestone==0) return 0;
    auto snapshot=SnapshotExecutable(base,id.pe);
    auto a=RuntimeAddresses::Resolve(base,id.pe,snapshot);
    log->Write("ADDRESS","GObjects="+Hex(a.objectArray)+" source=FES signature/RIP; NameToString="+Hex(a.nameToString)+" Realloc="+Hex(a.realloc));
    auto array=ObjectArray::Inspect(a.objectArray,ReadMemory);
    unsigned valid=0;
    // Only inspect a bounded early sample, avoiding a full object/name dump.
    for(unsigned i=0;i<256 && i<static_cast<unsigned>(array.count) && valid<8;++i) {
      auto object=array.At(i); if(!object) continue;
      auto view=ObjectView::Inspect(object); auto cls=ObjectView::Inspect(view.cls);
      if(view.internalIndex!=static_cast<std::int32_t>(i)) throw std::runtime_error("OBJECT_INDEX_MISMATCH");
      auto name=ReadName(view,a); auto className=ReadName(cls,a);
      if(!name.ok || !className.ok) {
        auto failed=!name.ok?name:className;
        log->Write("EXCEPTION","FName diagnostic failed code="+Hex(failed.exception)+" address="+Hex(failed.fault)+(failed.fault>=base && failed.fault-base<id.pe.imageSize ? " Shipping+RVA="+Hex(failed.fault-base):""));
        throw std::runtime_error("FNAME_DIAGNOSTIC_FAILED_NO_RETRY");
      }
      // Restrict log to short ASCII names; never emit arbitrary memory, request bodies or credentials.
      auto narrow=[](const std::wstring& text) {std::string out;for(auto c:text) out+=(c>=32 && c<127)?static_cast<char>(c):'?';std::string lower=out;for(auto& c:lower) if(c>='A' && c<='Z') c=static_cast<char>(c-'A'+'a');for(const char* sensitive:{"auth","token","password","credential","secret"}) if(lower.find(sensitive)!=std::string::npos) return std::string("[redacted name]");return out.substr(0,96);};
      log->Write("OBJECT","index="+std::to_string(i)+" name="+narrow(name.text)+" class="+narrow(className.text)); ++valid;
    }
    if(valid<8) throw std::runtime_error("OBJECT_SAMPLE_INSUFFICIENT");
    std::int32_t countNow{}; if(!Read(a.objectArray+CountOffset,countNow) || countNow<array.count) throw std::runtime_error("OBJECT_ARRAY_CHANGED_RETRY_NEXT_RUN");
    log->Write("R1","PASS; coherent readable chunked array, count="+std::to_string(array.count)+", 8 objects/classes/names; sampling is not a synchronized snapshot");
    log->Write("STOP","R2-R5 pending; no GWorld claim, no ProcessEvent calls/hooks, no world travel");return 0;
  } catch(const std::exception& e) {
    try {if(log) log->Write("FAIL",e.what());} catch(...) {} return 1;
  } catch(...) {try {if(log) log->Write("FAIL","UNEXPECTED_EXCEPTION");} catch(...) {}return 1;}
}
}
