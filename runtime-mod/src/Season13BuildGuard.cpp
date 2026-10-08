#include "Season13BuildGuard.h"
#include "Season13Target.h"
#include <bcrypt.h>
#include <algorithm>
#include <stdexcept>
namespace s13 {
std::string Sha256(std::span<const std::uint8_t> b) {
  BCRYPT_ALG_HANDLE alg{}; BCRYPT_HASH_HANDLE hash{}; std::uint8_t digest[32]{};
  if(BCryptOpenAlgorithmProvider(&alg,BCRYPT_SHA256_ALGORITHM,nullptr,0)<0) throw std::runtime_error("SHA_OPEN");
  auto status=BCryptCreateHash(alg,&hash,nullptr,0,nullptr,0,0);
  if(status>=0) { for(std::size_t at=0;at<b.size() && status>=0;at+=1024*1024) status=BCryptHashData(hash,const_cast<PUCHAR>(b.data()+at),static_cast<ULONG>(std::min<std::size_t>(1024*1024,b.size()-at)),0); }
  if(status>=0) status=BCryptFinishHash(hash,digest,32,0);
  if(hash) BCryptDestroyHash(hash); BCryptCloseAlgorithmProvider(alg,0);
  if(status<0) throw std::runtime_error("SHA_FAILED");
  std::string result; constexpr char hex[]="0123456789abcdef";
  for(auto v:digest) { result+=hex[v>>4]; result+=hex[v&15]; } return result;
}
static bool Contains(std::span<const std::uint8_t> bytes,const char* text,bool wide) {
  std::vector<std::uint8_t> needle;
  for(;*text;++text) { needle.push_back(static_cast<std::uint8_t>(*text)); if(wide) needle.push_back(0); }
  return std::search(bytes.begin(),bytes.end(),needle.begin(),needle.end())!=bytes.end();
}
BuildIdentity ValidateTarget(const std::wstring& path) {
  if(_wcsicmp(CanonicalPath(path).c_str(),CanonicalPath(TargetExe).c_str())) throw std::runtime_error("GUARD_WRONG_PATH");
  auto b=ReadFileBytes(path);
  return VerifyTargetBytes(b);
}
BuildIdentity VerifyTargetBytes(std::span<const std::uint8_t> b) {
  if(b.size()!=TargetFileSize) throw std::runtime_error("GUARD_FILE_SIZE");
  BuildIdentity id; id.pe=PeImage::Parse(b); id.hash=Sha256(b);
  if(id.hash!=TargetSha256) throw std::runtime_error("GUARD_SHA256");
  // Exact full SHA is the authoritative build identity. Embedded strings are additional evidence.
  id.buildString=Contains(b,TargetBuild,false)||Contains(b,TargetBuild,true);
  id.changelist=Contains(b,"14113327",false)||Contains(b,"14113327",true);
  if(!id.buildString || !id.changelist) throw std::runtime_error("GUARD_BUILD_STRING_OR_CL");
  return id;
}
}
