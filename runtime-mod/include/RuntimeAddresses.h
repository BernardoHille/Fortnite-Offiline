#pragma once
#include "PatternScanner.h"
namespace s13 {
inline constexpr char ObjectArrayPattern[]="48 8B 05 ? ? ? ? 48 8B 0C C8 48 8B 04 D1";
inline constexpr char ObjectArrayAlternate[]="48 8B 05 ? ? ? ? 48 8B 0C C8 48 8D 04 D1";
inline constexpr char NameToStringPattern[]="48 89 5C 24 ? 57 48 83 EC 40 83 79 04 00 48 8B DA 48 8B F9";
inline constexpr char ReallocPattern[]="48 89 5C 24 08 48 89 74 24 10 57 48 83 EC ? 48 8B F1 41 8B D8 48 8B 0D ? ? ? ?";
struct RuntimeAddresses {
  std::uintptr_t imageBase{}, objectArray{}, nameToString{}, realloc{};
  // GWorld/ProcessEvent are deliberately not populated by invented RVAs.
  static RuntimeAddresses Resolve(std::uintptr_t base,const PeImage& pe,std::span<const std::uint8_t> snapshot);
};
}
