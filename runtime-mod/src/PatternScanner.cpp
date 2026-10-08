#include "PatternScanner.h"
#include <cstring>
#include <sstream>
#include <stdexcept>
namespace s13 {
std::uint32_t ScanResult::Unique() const {
  if(matches.empty()) throw std::runtime_error("SIGNATURE_ZERO_MATCHES");
  if(matches.size()!=1) throw std::runtime_error("SIGNATURE_AMBIGUOUS"); return matches[0];
}
std::vector<int> ParsePattern(const std::string& p) {
  std::vector<int> out; std::istringstream stream(p); std::string token; bool concrete=false;
  while(stream>>token) {
    if(token=="?" || token=="??") out.push_back(-1);
    else {
      if(token.size()!=2 || token.find_first_not_of("0123456789abcdefABCDEF")!=std::string::npos) throw std::runtime_error("SIGNATURE_INVALID");
      out.push_back(std::stoi(token,nullptr,16)); concrete=true;
    }
    if(out.size()>256) throw std::runtime_error("SIGNATURE_TOO_LONG");
  }
  if(out.empty() || !concrete) throw std::runtime_error("SIGNATURE_EMPTY_OR_ALL_WILDCARD"); return out;
}
ScanResult ScanBuffer(std::span<const std::uint8_t> b,const std::vector<int>& p,std::uint32_t rva) {
  if(b.size()>UINT32_MAX-rva) throw std::runtime_error("SIGNATURE_RVA_OVERFLOW");
  ScanResult result; if(p.empty() || p.size()>b.size()) return result;
  for(std::size_t i=0;i<=b.size()-p.size();++i) {
    bool hit=true; for(std::size_t j=0;j<p.size();++j) if(p[j]>=0 && b[i+j]!=p[j]) {hit=false;break;}
    if(hit) { result.matches.push_back(rva+static_cast<std::uint32_t>(i)); if(result.matches.size()==2) break; }
  }
  return result;
}
ScanResult ScanImage(std::span<const std::uint8_t> b,const PeImage& pe,const std::string& text,bool mapped) {
  ScanResult result; auto p=ParsePattern(text);
  for(auto& s:pe.sections) {
    if(!(s.flags&IMAGE_SCN_MEM_EXECUTE)) continue;
    const auto offset=mapped?s.rva:s.raw; const auto length=mapped?s.virtualSize:std::min(s.rawSize,s.virtualSize);
    if(offset>b.size() || length>b.size()-offset) throw std::runtime_error("SIGNATURE_SECTION_UNREADABLE");
    auto found=ScanBuffer(b.subspan(offset,length),p,s.rva);
    result.matches.insert(result.matches.end(),found.matches.begin(),found.matches.end());
    if(result.matches.size()>1) {result.matches.resize(2);break;}
  }
  return result;
}
std::uint32_t RipTarget(std::span<const std::uint8_t> b,std::uint32_t rva,std::size_t operand,std::size_t length,std::uint32_t size) {
  if(operand>b.size() || 4>b.size()-operand || length>b.size() || operand+4>length) throw std::runtime_error("RIP_TRUNCATED");
  std::int32_t displacement{}; std::memcpy(&displacement,b.data()+operand,4);
  auto target=static_cast<std::int64_t>(rva)+static_cast<std::int64_t>(length)+displacement;
  if(target<0 || target>=size) throw std::runtime_error("RIP_OUT_OF_IMAGE"); return static_cast<std::uint32_t>(target);
}
}
