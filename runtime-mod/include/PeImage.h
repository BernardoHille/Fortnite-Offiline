#pragma once
#include <Windows.h>
#include <cstdint>
#include <span>
#include <string>
#include <vector>
namespace s13 {
struct Section { std::string name; std::uint32_t rva, virtualSize, raw, rawSize, flags; };
struct PeImage {
  std::uint16_t machine{}; std::uint32_t timestamp{}, imageSize{}, headersSize{};
  std::uint64_t preferredBase{}; std::uint32_t exportRva{}, exportSize{};
  std::vector<Section> sections;
  static PeImage Parse(std::span<const std::uint8_t> bytes);
  std::size_t FileOffset(std::uint32_t rva, std::size_t length=1) const;
  bool Executable(std::uint32_t rva) const;
  std::uint32_t Export(std::span<const std::uint8_t> bytes, const char* name) const;
};
std::vector<std::uint8_t> ReadFileBytes(const std::wstring& path);
std::wstring CanonicalPath(const std::wstring& path);
}
