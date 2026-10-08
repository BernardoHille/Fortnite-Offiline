#pragma once
#include "PeImage.h"
namespace s13 {
struct ScanResult { std::vector<std::uint32_t> matches; std::uint32_t Unique() const; };
std::vector<int> ParsePattern(const std::string& pattern);
ScanResult ScanBuffer(std::span<const std::uint8_t> bytes,const std::vector<int>& pattern,std::uint32_t baseRva=0);
ScanResult ScanImage(std::span<const std::uint8_t> bytes,const PeImage& pe,const std::string& pattern,bool mapped);
std::uint32_t RipTarget(std::span<const std::uint8_t> instruction,std::uint32_t instructionRva,std::size_t operand,std::size_t length,std::uint32_t imageSize);
}
