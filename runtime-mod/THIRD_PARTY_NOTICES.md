# Proveniência das referências

Código próprio de controller/guard/scanner/logger e adaptação mínima de signatures/layouts/ABI para diagnóstico da única build 13.40. Nenhum binário upstream foi incorporado ao módulo.

- FortExternalServer, season-13, commit `e42ecddbce59163c6a60ab7506766c2a0adfe580`: signatures GObjects/NameToString/Realloc, offsets de UObject e contrato de conversão FString. Copyright (c) 2026 Alpha OGFN, MIT. [Texto integral](licenses/FortExternalServer-MIT.txt), [fonte](https://github.com/OGFN-Open-sourceing/FortExternalServer/tree/e42ecddbce59163c6a60ab7506766c2a0adfe580).
- Project Reboot 3.0, commit `10c659028ad9d6816f78226483f11a884bf81f57`: referência de acesso interno, layout chunked e 65536 elementos por chunk na 13.4. BSD 3-Clause; copyright e condições preservados no [texto integral](licenses/Reboot-BSD-3-Clause.txt), [fonte](https://github.com/Milxnor/Project-Reboot-3.0/tree/10c659028ad9d6816f78226483f11a884bf81f57).

Alterações/adaptações: guard de SHA/caminho único, validação estrutural/bounds, scans únicos, chunk count corrigido em relação ao override FES divergente, amostra limitada e export explícito. Nenhum entrypoint, inicializador de servidor ou módulo de segurança upstream foi copiado. As [auditorias](../docs/FES_RUNTIME_TRACE.md) e o [mapa](../docs/SEASON13_ADDRESS_MAP.md) distinguem fonte declarada de validação runtime, que permanece pendente.
