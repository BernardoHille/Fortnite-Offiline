#include "PeImage.h"
#include <cstring>
#include <filesystem>
#include <fstream>
#include <stdexcept>
namespace s13 {
template<class T> static T At(std::span<const std::uint8_t> b, std::size_t at) {
  if(at>b.size() || sizeof(T)>b.size()-at) throw std::runtime_error("PE_TRUNCATED");
  T v{}; std::memcpy(&v,b.data()+at,sizeof(v)); return v;
}
PeImage PeImage::Parse(std::span<const std::uint8_t> b) {
  auto dos=At<IMAGE_DOS_HEADER>(b,0);
  if(dos.e_magic!=IMAGE_DOS_SIGNATURE || dos.e_lfanew<sizeof(dos)) throw std::runtime_error("PE_DOS");
  auto nt=static_cast<std::size_t>(dos.e_lfanew);
  if(At<DWORD>(b,nt)!=IMAGE_NT_SIGNATURE) throw std::runtime_error("PE_NT");
  auto f=At<IMAGE_FILE_HEADER>(b,nt+4);
  if(f.Machine!=IMAGE_FILE_MACHINE_AMD64 || !f.NumberOfSections || f.NumberOfSections>96 || f.SizeOfOptionalHeader<sizeof(IMAGE_OPTIONAL_HEADER64)) throw std::runtime_error("PE_ARCH_OR_SECTIONS");
  auto o=At<IMAGE_OPTIONAL_HEADER64>(b,nt+24);
  if(o.Magic!=IMAGE_NT_OPTIONAL_HDR64_MAGIC || !o.SizeOfImage || o.SizeOfImage>512u*1024*1024 || o.SizeOfHeaders>o.SizeOfImage || o.NumberOfRvaAndSizes<=IMAGE_DIRECTORY_ENTRY_EXPORT) throw std::runtime_error("PE_OPTIONAL");
  PeImage p; p.machine=f.Machine; p.timestamp=f.TimeDateStamp; p.imageSize=o.SizeOfImage;
  p.headersSize=o.SizeOfHeaders; p.preferredBase=o.ImageBase;
  p.exportRva=o.DataDirectory[0].VirtualAddress; p.exportSize=o.DataDirectory[0].Size;
  const auto start=nt+24+f.SizeOfOptionalHeader;
  for(unsigned i=0;i<f.NumberOfSections;++i) {
    auto s=At<IMAGE_SECTION_HEADER>(b,start+i*sizeof(IMAGE_SECTION_HEADER));
    if(s.VirtualAddress>p.imageSize || s.Misc.VirtualSize>p.imageSize-s.VirtualAddress) throw std::runtime_error("PE_SECTION_RANGE");
    char name[9]{}; std::memcpy(name,s.Name,8);
    p.sections.push_back({name,s.VirtualAddress,s.Misc.VirtualSize,s.PointerToRawData,s.SizeOfRawData,s.Characteristics});
  }
  return p;
}
std::size_t PeImage::FileOffset(std::uint32_t rva,std::size_t length) const {
  if(rva<headersSize && length<=headersSize-rva) return rva;
  for(auto& s:sections) if(rva>=s.rva && rva-s.rva<s.rawSize && length<=s.rawSize-(rva-s.rva)) return static_cast<std::size_t>(s.raw)+rva-s.rva;
  throw std::runtime_error("PE_RVA_NOT_FILE_BACKED");
}
bool PeImage::Executable(std::uint32_t rva) const {
  for(auto& s:sections) if(rva>=s.rva && rva-s.rva<s.virtualSize && (s.flags&IMAGE_SCN_MEM_EXECUTE)) return true;
  return false;
}
std::uint32_t PeImage::Export(std::span<const std::uint8_t> b,const char* name) const {
  if(!exportRva) throw std::runtime_error("PE_NO_EXPORTS");
  auto e=At<IMAGE_EXPORT_DIRECTORY>(b,FileOffset(exportRva,sizeof(IMAGE_EXPORT_DIRECTORY)));
  if(e.NumberOfNames>65536 || e.NumberOfFunctions>65536) throw std::runtime_error("PE_EXPORT_COUNT");
  for(DWORD i=0;i<e.NumberOfNames;++i) {
    auto nrva=At<DWORD>(b,FileOffset(e.AddressOfNames+i*4,4)); auto n=FileOffset(nrva);
    std::string text;
    for(std::size_t j=0;j<256;++j) { char c=static_cast<char>(At<std::uint8_t>(b,n+j)); if(!c) break; text+=c; }
    if(text!=name) continue;
    auto ordinal=At<WORD>(b,FileOffset(e.AddressOfNameOrdinals+i*2,2));
    if(ordinal>=e.NumberOfFunctions) throw std::runtime_error("PE_EXPORT_ORDINAL");
    auto rva=At<DWORD>(b,FileOffset(e.AddressOfFunctions+ordinal*4,4));
    if((rva>=exportRva && rva-exportRva<exportSize) || !Executable(rva)) throw std::runtime_error("PE_FORWARDED_OR_NONCODE_EXPORT");
    return rva;
  }
  throw std::runtime_error("PE_EXPORT_NOT_FOUND");
}
std::vector<std::uint8_t> ReadFileBytes(const std::wstring& path) {
  std::ifstream f(std::filesystem::path(path),std::ios::binary|std::ios::ate);
  if(!f) throw std::runtime_error("FILE_OPEN"); auto length=f.tellg();
  if(length<0 || length>512ll*1024*1024) throw std::runtime_error("FILE_SIZE_LIMIT");
  std::vector<std::uint8_t> b(static_cast<std::size_t>(length)); f.seekg(0);
  if(!f.read(reinterpret_cast<char*>(b.data()),length)) throw std::runtime_error("FILE_READ"); return b;
}
std::wstring CanonicalPath(const std::wstring& path) {
  HANDLE h=CreateFileW(path.c_str(),0,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,nullptr,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,nullptr);
  if(h==INVALID_HANDLE_VALUE) throw std::runtime_error("PATH_OPEN");
  wchar_t value[32768]{}; DWORD n=GetFinalPathNameByHandleW(h,value,32768,FILE_NAME_NORMALIZED|VOLUME_NAME_DOS); CloseHandle(h);
  if(!n || n>=32768) throw std::runtime_error("PATH_CANONICAL"); return value;
}
}
