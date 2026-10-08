#pragma once
#include "Memory.h"
#include <functional>
namespace s13 {
using Reader=std::function<bool(std::uintptr_t,void*,std::size_t)>;
struct ObjectArray {
  std::uintptr_t address{}, chunks{}; std::int32_t count{},maxElements{},numChunks{},maxChunks{}; Reader reader;
  static ObjectArray Inspect(std::uintptr_t address,Reader reader);
  std::uintptr_t At(std::uint32_t index) const;
};
struct ObjectView {
  std::uintptr_t address{}, vtable{}, cls{}, outer{}; std::int32_t internalIndex{},nameIndex{}, nameNumber{};
  static ObjectView Inspect(std::uintptr_t address);
};
}
