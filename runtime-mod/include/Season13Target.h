#pragma once
#include <cstdint>
namespace s13 {
inline constexpr wchar_t TargetExe[] = L"D:\\Games\\FortniteLocal\\13.40-CL-14113327\\13.40\\FortniteGame\\Binaries\\Win64\\FortniteClient-Win64-Shipping.exe";
inline constexpr wchar_t LogFile[] = L"D:\\Games\\Fortnite-Local-C2S3\\runtime\\season13\\logs\\runtime.log";
inline constexpr char TargetSha256[] = "fb348e9a239a52170f2b46e99c225d4ec2bded53e40f8e7ff9daec3ac39a9f21";
inline constexpr std::size_t TargetFileSize = 174908672;
inline constexpr std::uint32_t TargetCL = 14113327;
inline constexpr char TargetBuild[] = "++Fortnite+Release-13.40";
// FES Season13BuildProfile / UnrealLayout, pinned in docs/SEASON13_ADDRESS_MAP.md.
inline constexpr std::uint32_t ClassOffset=0x10, NameOffset=0x18, OuterOffset=0x20;
inline constexpr std::uint32_t ItemStride=0x18, CountOffset=0x14;
// Reboot Main selects 0x10000 for 13.40. FES profile override conflicts: do not inherit it.
inline constexpr std::uint32_t ElementsPerChunk=0x10000;
}
