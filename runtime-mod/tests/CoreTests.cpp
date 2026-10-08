#include "PeImage.h"
#include "PatternScanner.h"
#include "Season13BuildGuard.h"
#include "ObjectArray.h"
#include "Season13Target.h"
#include "RuntimeLog.h"
#include <filesystem>
#include <cstring>
#include <iostream>
#include <stdexcept>
using namespace s13;
static void Require(bool value,const char* label) {if(!value) throw std::runtime_error(label);}
template<class F> void Reject(F f,const char* label){bool rejected=false;try{f();}catch(const std::exception&){rejected=true;}Require(rejected,label);}
template<class T> void Put(std::vector<std::uint8_t>& bytes,std::size_t at,const T& value){std::memcpy(bytes.data()+at,&value,sizeof(value));}
int main() {
  try {
    Require(Sha256(std::span<const std::uint8_t>{})=="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","SHA vector");
    Reject([&]{VerifyTargetBytes(std::span<const std::uint8_t>{});},"guard wrong size accepted");
    std::uint8_t b[]{0x48,0x8b,0x01,0x48,0x8b,0x02};auto p=ParsePattern("48 8B ?");
    Reject([&]{ScanBuffer(b,p).Unique();},"ambiguous scan accepted");
    Reject([&]{ScanBuffer(b,ParsePattern("FF EE")).Unique();},"zero scan accepted");
    Require(ScanBuffer(b,ParsePattern("8B 02"),0x1000).Unique()==0x1004,"unique scan RVA");
    Reject([&]{ParsePattern("GG");},"bad pattern");Reject([&]{ParsePattern("? ?");},"wildcard pattern");
    std::uint8_t rip[]{0x48,0x8b,0x05,0xf9,0xff,0xff,0xff};
    Require(RipTarget(rip,0x1000,3,7,0x3000)==0x1000,"signed RIP decode");
    Reject([&]{RipTarget(std::span(rip,3),0,3,7,0x3000);},"truncated RIP accepted");
    std::vector<std::uint8_t> image(0x600);IMAGE_DOS_HEADER dos{};dos.e_magic=IMAGE_DOS_SIGNATURE;dos.e_lfanew=0x80;Put(image,0,dos);
    DWORD signature=IMAGE_NT_SIGNATURE;Put(image,0x80,signature);IMAGE_FILE_HEADER f{};f.Machine=IMAGE_FILE_MACHINE_AMD64;f.NumberOfSections=2;f.SizeOfOptionalHeader=sizeof(IMAGE_OPTIONAL_HEADER64);Put(image,0x84,f);
    IMAGE_OPTIONAL_HEADER64 opt{};opt.Magic=IMAGE_NT_OPTIONAL_HDR64_MAGIC;opt.SizeOfImage=0x4000;opt.SizeOfHeaders=0x200;opt.NumberOfRvaAndSizes=16;Put(image,0x98,opt);
    IMAGE_SECTION_HEADER sec{};sec.VirtualAddress=0x1000;sec.Misc.VirtualSize=0x100;sec.PointerToRawData=0x200;sec.SizeOfRawData=0x100;sec.Characteristics=IMAGE_SCN_MEM_EXECUTE;Put(image,0x98+sizeof(opt),sec);
    sec.VirtualAddress=0x2000;sec.PointerToRawData=0x300;sec.Characteristics=IMAGE_SCN_MEM_READ;Put(image,0x98+sizeof(opt)+sizeof(sec),sec);
    image[0x210]=0xaa;image[0x211]=0xbb;image[0x310]=0xaa;image[0x311]=0xbb;
    auto pe=PeImage::Parse(image);Require(pe.FileOffset(0x1010)==0x210,"PE RVA conversion");
    auto altered=image;altered.resize(TargetFileSize);Reject([&]{VerifyTargetBytes(altered);},"guard wrong full hash accepted");altered.clear();altered.shrink_to_fit();
    Require(ScanImage(image,pe,"AA BB",false).Unique()==0x1010,"non-code section scanned");
    Reject([&]{PeImage::Parse(std::span(image).first(32));},"truncated PE accepted");
    f.Machine=IMAGE_FILE_MACHINE_I386;Put(image,0x84,f);Reject([&]{PeImage::Parse(image);},"x86 accepted");
    std::vector<std::uint8_t> fake(0x1000);std::uintptr_t base=0x100000, chunks=base+0x100,chunk0=base+0x200,chunk1=base+0x300, object0=base+0x500,object1=base+0x600;
    std::int32_t count=65537,capacity=131072,chunkCount=2;Put(fake,0,chunks);Put(fake,0x10,capacity);Put(fake,CountOffset,count);Put(fake,0x18,chunkCount);Put(fake,0x1c,chunkCount);Put(fake,0x100,chunk0);Put(fake,0x108,chunk1);Put(fake,0x200,object0);Put(fake,0x300,object1);
    Reader reader=[&](std::uintptr_t at,void* out,std::size_t n){if(at<base||at-base>fake.size()||n>fake.size()-(at-base)) return false;std::memcpy(out,fake.data()+at-base,n);return true;};
    auto array=ObjectArray::Inspect(base,reader);Require(array.At(0)==object0 && array.At(65536)==object1,"chunk boundary must use 65536 elements");
    Reject([&]{array.At(65537);},"object array out of bounds");count=-1;Put(fake,CountOffset,count);Reject([&]{ObjectArray::Inspect(base,reader);},"negative object count");count=65537;Put(fake,CountOffset,count);chunkCount=1;Put(fake,0x1c,chunkCount);Reject([&]{ObjectArray::Inspect(base,reader);},"chunk capacity incoherent");
    auto self=reinterpret_cast<std::uintptr_t>(fake.data());Require(Readable(self,fake.size()),"memory readable fixture");Require(!Readable(0,8),"null readable");
    auto logPath=(std::filesystem::current_path()/L"fixture-runtime.log").wstring();
    {RuntimeLog log(logPath.c_str());log.Write("TEST","Logger fixture first line, no game process");}
    auto first=std::filesystem::file_size(logPath);
    {RuntimeLog log(logPath.c_str());log.Write("TEST","Logger fixture append and flush");}
    Require(std::filesystem::file_size(logPath)>first,"logger did not append/flush");
    std::cout<<"PASS: SHA256, scanner zero/unique/ambiguous, signed RIP, truncated PE, architecture, section scope, chunk boundary, invalid count, memory probes. No Fortnite launch/attach/DLL load.\n";return 0;
  }catch(const std::exception& e){std::cerr<<"FAIL: "<<e.what()<<"\n";return 1;}
}
