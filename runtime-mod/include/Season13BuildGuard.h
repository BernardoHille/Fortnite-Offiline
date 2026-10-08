#pragma once
#include "PeImage.h"
namespace s13 {
struct BuildIdentity { PeImage pe; std::string hash; bool buildString{}, changelist{}; };
BuildIdentity ValidateTarget(const std::wstring& path);
BuildIdentity VerifyTargetBytes(std::span<const std::uint8_t> bytes);
std::string Sha256(std::span<const std::uint8_t> bytes);
}
