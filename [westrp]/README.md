# [westrp] — West Roleplay Ecosystem

Bem-vindo ao repositório do **[westrp]**, uma solução de engenharia modular, de alta performance e ultra-segura para Red Dead Redemption 2 / RedM.

---

## 📖 Documentação e Especificações Mestras
Todo o desenvolvimento deste ecossistema segue rigorosamente a abordagem de **Spec-Driven Development (SDD)**.

Antes de desenvolver ou modificar qualquer recurso, consulte as documentações específicas:
* 📜 **[SPECIFICATION.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/SPECIFICATION.md)** — Arquitetura Mestra, Contratos e Regras Inegociáveis.
* 🎨 **[Manual do Motor de UI (`westrp_ui`)](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/README.md)** — Guia Completo do Desenvolvedor para Dock, Panel, Toasts e Web Audio.
* 🖼️ **[Manual da Central de Assets (`westrp_assets`)](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[assets]/westrp_assets/README.md)** — Guia do Acervo de 2.100+ Ícones e Resolução Automática.

---

## 📂 Estrutura do Ecossistema

```text
[westrp]/
├── SPECIFICATION.md          # 📜 Especificação arquitetural, contratos de API e regras inegociáveis
├── README.md                 # 📄 Este arquivo
│
├── [assets]/                 # 🖼️ Recursos Estáticos & Repositório de Mídias
│   └── westrp_assets/        # Central de 2.122 ícones e índice de resolução automática
│
├── [core]/                   # ⚙️ Núcleo compartilhado / SDK e Motores
│   ├── westrp_core/          # Ponto de entrada (Bridges, TickManager, RPC, Security)
│   └── westrp_ui/            # Motor NUI Central (Dock Lateral, Panel Central, Toasts)
│
└── [systems]/                # 🎮 Módulos e Funcionalidades de Gameplay
    ├── westrp_template/      # 📋 Boilerplate oficial para clonagem de novos resources
    └── westrp_interaction/   # 🎯 Interações Espaciais, Prompts e Comandos de Demonstração
```

---

## ⚡ Regras de Ouro
1. **0.00ms Resmon Target**: Nunca use loops cegos em `Wait(0)`. Use o `TickManager` adaptativo.
2. **Zero-Trust Client**: O cliente apenas expressa intenção. O servidor valida distâncias, estados e rate limits.
3. **Bridge Pattern**: Nunca chame o VORP diretamente nos módulos. Use `WestRP.Shared.Bridge`.
4. **Lifecycle**: Sempre limpe threads e prompts no `onResourceStop`.
