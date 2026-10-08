#pragma once
#include <Windows.h>
#include <cstdint>
namespace s13 {
inline constexpr std::uint32_t RequestMagic=0x53313352;
struct RuntimeRequest {std::uint32_t magic=RequestMagic;std::uint32_t milestone=0;};
DWORD Initialize(const RuntimeRequest& request);
}
