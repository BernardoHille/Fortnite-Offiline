#include "RuntimeAddresses.h"
#include "Memory.h"
#include <stdexcept>
namespace s13 {
RuntimeAddresses RuntimeAddresses::Resolve(std::uintptr_t base,const PeImage& pe,std::span<const std::uint8_t> b) {
  RuntimeAddresses a; a.imageBase=base;
  auto objects=ScanImage(b,pe,ObjectArrayPattern,true);
  if(objects.matches.empty()) objects=ScanImage(b,pe,ObjectArrayAlternate,true);
  auto instruction=objects.Unique();
  auto arrayRva=RipTarget(b.subspan(instruction,7),instruction,3,7,pe.imageSize);
  a.objectArray=base+arrayRva;
  auto names=ScanImage(b,pe,NameToStringPattern,true).Unique();
  auto realloc=ScanImage(b,pe,ReallocPattern,true).Unique();
  if(!pe.Executable(names)||!pe.Executable(realloc)||!Readable(base+names,32,true)||!Readable(base+realloc,32,true)||!Readable(a.objectArray,0x18)) throw std::runtime_error("ADDRESS_REGION_INVALID");
  a.nameToString=base+names; a.realloc=base+realloc; return a;
}
}
