#include "ObjectArray.h"
#include "Season13Target.h"
#include <stdexcept>
namespace s13 {
ObjectArray ObjectArray::Inspect(std::uintptr_t at,Reader r) {
  ObjectArray array; array.address=at; array.reader=std::move(r);
  // Reboot FChunkedFixedUObjectArray layout: capacities are counts, not bytes.
  if(!array.reader(at,&array.chunks,8)||!array.reader(at+CountOffset,&array.count,4)||!array.reader(at+0x10,&array.maxElements,4)||!array.reader(at+0x18,&array.maxChunks,4)||!array.reader(at+0x1c,&array.numChunks,4)||!array.chunks || array.count<8 || array.count>2000000 || array.maxElements<array.count || array.maxElements>5000000 || array.numChunks<1 || array.numChunks>64 || array.maxChunks<array.numChunks || array.maxChunks>128 || (static_cast<std::uint32_t>(array.count)+ElementsPerChunk-1)/ElementsPerChunk>static_cast<std::uint32_t>(array.numChunks)) throw std::runtime_error("OBJECT_ARRAY_STRUCTURE");
  std::uintptr_t chunk{}; if(!array.reader(array.chunks,&chunk,8)||!chunk) throw std::runtime_error("OBJECT_ARRAY_CHUNK");
  return array;
}
std::uintptr_t ObjectArray::At(std::uint32_t index) const {
  if(index>=static_cast<std::uint32_t>(count)) throw std::runtime_error("OBJECT_ARRAY_INDEX");
  std::uintptr_t chunk{}, object{};
  if(!reader(chunks+(index/ElementsPerChunk)*8,&chunk,8)||!chunk||!reader(chunk+(index%ElementsPerChunk)*ItemStride,&object,8)) throw std::runtime_error("OBJECT_ARRAY_READ");
  return object;
}
ObjectView ObjectView::Inspect(std::uintptr_t at) {
  ObjectView o; o.address=at;
  if(!at || at%8 || !Read(at,o.vtable)||!Read(at+0xc,o.internalIndex)||!Read(at+ClassOffset,o.cls)||!Read(at+OuterOffset,o.outer)||!Read(at+NameOffset,o.nameIndex)||!Read(at+NameOffset+4,o.nameNumber)) throw std::runtime_error("UOBJECT_READ");
  std::uintptr_t entry{};
  if(!o.cls || o.internalIndex<0 || o.internalIndex>=2000000 || !Readable(o.cls,0x28) || o.nameIndex<0 || o.nameNumber<0 || !Read(o.vtable,entry)||!Readable(entry,1,true)) throw std::runtime_error("UOBJECT_STRUCTURE");
  return o;
}
}
