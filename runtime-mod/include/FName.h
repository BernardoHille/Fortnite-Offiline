#pragma once
#include "RuntimeAddresses.h"
#include "ObjectArray.h"
namespace s13 {
struct NameResult { std::wstring text; DWORD exception{}; std::uintptr_t fault{}; bool ok{}; };
NameResult ReadName(const ObjectView& object,const RuntimeAddresses& addresses);
}
