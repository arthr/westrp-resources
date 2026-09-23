# [westrp] — West Roleplay Ecosystem

Bem-vindo ao repositório do **[westrp]**, uma solução de engenharia modular, de alta performance e ultra-segura para Red Dead Redemption 2 / RedM.

---

## 📖 Documentação e Especificação Mestra
Todo o desenvolvimento deste ecossistema segue rigorosamente a abordagem de **Spec-Driven Development (SDD)**.

Antes de desenvolver ou modificar qualquer recurso, consulte a especificação completa em:
👉 **[SPECIFICATION.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/SPECIFICATION.md)**

---

## 📂 Estrutura do Ecossistema

```text
[westrp]/
├── SPECIFICATION.md          # 📜 Especificação arquitetural, contratos de API e regras inegociáveis
├── README.md                 # 📄 Este arquivo
│
├── [core]/                   # ⚙️ Núcleo compartilhado / SDK
│   └── westrp_core/          # Ponto de entrada (Bridges, TickManager, RPC, Security)
│
└── [systems]/                # 🎮 Módulos e Funcionalidades de Gameplay
    ├── westrp_template/      # 📋 Boilerplate oficial para clonagem de novos resources
    └── westrp_interaction/   # 🎯 Sistema de Interações e Pontos de Interesse (Validação)
```

---

## ⚡ Regras de Ouro
1. **0.00ms Resmon Target**: Nunca use loops cegos em `Wait(0)`. Use o `TickManager` adaptativo.
2. **Zero-Trust Client**: O cliente apenas expressa intenção. O servidor valida distâncias, estados e rate limits.
3. **Bridge Pattern**: Nunca chame o VORP diretamente nos módulos. Use `WestRP.Shared.Bridge`.
4. **Lifecycle**: Sempre limpe threads e prompts no `onResourceStop`.
