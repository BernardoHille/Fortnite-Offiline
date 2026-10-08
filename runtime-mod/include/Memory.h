#pragma once
#include "PeImage.h"
namespace s13 {
bool Readable(std::uintptr_t address,std::size_t length,bool executable=false);
bool ReadMemory(std::uintptr_t address,void* output,std::size_t length);
template<class T> bool Read(std::uintptr_t address,T& out) { return ReadMemory(address,&out,sizeof(out)); }
std::vector<std::uint8_t> SnapshotExecutable(std::uintptr_t base,const PeImage& pe);
}
