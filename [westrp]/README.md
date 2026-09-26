# [westrp] — West Roleplay Ecosystem

Bem-vindo ao repositório do **[westrp]**, uma solução de engenharia modular, de alta performance e ultra-segura para Red Dead Redemption 2 / RedM.

---

## 📖 Documentação e Especificação Mestra
Todo o desenvolvimento deste ecossistema segue rigorosamente a abordagem de **Spec-Driven Development (SDD)**.

A fonte única da verdade para arquitetura, diretrizes e plano diretor é:
* 📜 **[MASTER_ARCHITECTURE_PLAN.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/MASTER_ARCHITECTURE_PLAN.md)** — Arquitetura Mestra, Diagnóstico, Contratos e Plano de Execução em Fases.
*(Documentações históricas e detalhamentos antigos foram isolados em `docs_archive/`).*

---

## 📂 Estrutura do Ecossistema

```text
[westrp]/
├── MASTER_ARCHITECTURE_PLAN.md  # 📜 Especificação mestre, contratos de API e plano diretor
├── README.md                    # 📄 Este arquivo
├── docs_archive/                # 🗄️ Documentações legadas arquivadas
│
├── [assets]/                 # 🖼️ Recursos Estáticos & Repositório de Mídias
│   └── westrp_assets/        # Central de 2.122 ícones e índice de resolução automática
│
├── [core]/                   # ⚙️ Núcleo compartilhado / SDK e Motores
│   ├── westrp_core/          # Ponto de entrada (Bridges, TickManager, RPC, Security)
│   └── westrp_ui/            # Motor NUI Central (Dock Lateral, Panel Central, Toasts)
│
└── [systems]/                # 🎮 Módulos e Funcionalidades de Gameplay
    ├── westrp_admin/         # 🛡️ Sistema Administrativo, Auditoria, NoClip e Spawner
    ├── westrp_template/      # 📋 Boilerplate oficial para clonagem de novos resources
    └── westrp_interaction/   # 🎯 Interações Espaciais, Prompts e Comandos de Demonstração
```

---

## ⚡ Regras de Ouro
1. **0.00ms Resmon Target**: Nunca use loops cegos em `Wait(0)`. Use o `TickManager` adaptativo.
2. **Zero-Trust Client**: O cliente apenas expressa intenção. O servidor valida distâncias, estados e rate limits.
3. **Bridge Pattern**: Nunca chame o VORP diretamente nos módulos. Use `WestRP.Shared.Bridge`.
4. **Lifecycle**: Sempre limpe threads e prompts no `onResourceStop`.
