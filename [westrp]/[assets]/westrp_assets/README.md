# WestRP Assets — Central de Assets & Ícones

O **WestRP Assets** (`westrp_assets`) é o repositório estático centralizado de recursos visuais do ecossistema WestRP. Ele desacopla imagens e mídias do código-fonte dos scripts, eliminando redundâncias e centralizando mais de **2.100 ícones originais do Red Dead Redemption 2** com resolução automática para toda a interface.

---

## 📑 Índice
1. [Propósito & Vantagens da Centralização](#1-propósito--vantagens-da-centralização)
2. [Estrutura das 34 Categorias](#2-estrutura-das-34-categorias)
3. [Mecanismo de Resolução Automática (index.json)](#3-mecanismo-de-resolução-automática-indexjson)
4. [Como Consumir Ícones em Scripts Lua](#4-como-consumir-ícones-em-scripts-lua)
5. [Como Adicionar Novos Ícones ao Acervo](#5-como-adicionar-novos-ícones-ao-acervo)
6. [Regeneração do Índice (index.json)](#6-regeneração-do-índice-indexjson)
7. [Boas Práticas de Nomenclatura & Formato](#7-boas-práticas-de-nomenclatura--formato)

---

## 1. Propósito & Vantagens da Centralização

Em servidores FiveM e RedM convencionais, é comum que cada resource (`loja`, `inventario`, `crafting`, `garagem`) duplique centenas de imagens PNG dentro de suas próprias pastas `html/`, causando:
* Desperdício de memória RAM e VRAM no cliente.
* Download repetido de centenas de megabytes pelos jogadores.
* Inconsistência visual (o mesmo item possui ícones diferentes dependendo do menu).

No WestRP:
* **Fonte Única da Verdade:** Todos os ícones residem em `westrp_assets/html/icons/`.
* **Zero Código Lua:** O recurso é 100% estático, servindo apenas arquivos via protocolo CEF (`https://cfx-nui-westrp_assets/`).
* **Zero Overhead de CPU:** 0.00ms constante, sem threads ou eventos.

---

## 2. Estrutura das 34 Categorias

Os 2.122 ícones estão organizados em pastas limpas, sem caracteres de colchetes `[...]` para evitar conflito com o escaneamento de categorias do CitizenFX:

| Categoria | Descrição do Conteúdo | Exemplos de Itens |
| :--- | :--- | :--- |
| `weapons/` | Armas de fogo, arremesso, laços e miras | `weapon_thrown_tomahawk`, `weapon_melee_hammer`, `weapon_lasso_reinforced` |
| `ammo/` | Cartuchos, balas especiais e flechas | `ammo_revolver_split_point`, `ammo_shotgun_slug`, `ammo_arrow_dynamite` |
| `tools/` | Ferramentas de trabalho, facas e chaves | `tool_resource_knife`, `tool_hammer_blacksmith`, `lockpick`, `coffee_pot` |
| `gunsmith/` | Peças, moldes e óleos de manutenção | `gunoil3`, `riflemold`, `pistolgrip`, `riflebarrel` |
| `materials-crafting/` | Insumos manufaturados e químicos | `acid`, `resource_wagon_wheel`, `gold_nugget_small` |
| `materials-mining/` | Minérios brutos, carvão e gemas | `resource_coal`, `resource_iron_dirty`, `resource_emerald` |
| `materials-lumber/` | Madeiras nobres, tábuas e resinas | `lumber_pine_wood_plank`, `lumber_cedar_hardwood`, `resource_resin` |
| `consumable-food/` | Pratos assados, pães e doces | `consumable_meat_prime_beef_wild_mint_cooked`, `consumable_bread6` |
| `consumable-alcohol/`| Bebidas destiladas, conhaques e cervejas | `consumable_alcohol_bourbon`, `consumable_alcohol_beer_pint_amber` |
| `consumable-smoking/`| Charutos, caixas de tabaco e fósforos | `cigar1`, `cigar_box_preimium`, `lighter`, `cigarette` |
| `consumable-medical/`| Tônicos de saúde, óleos e remédios | `consumable_med_herbal_tonic`, `consumable_med_special_snake_oil` |
| `consumable-plants/` | Frutas silvestres, vegetais e ervas | `herb_desert_sage`, `black_berry`, `lemon`, `rice_sack` |
| `seeds/` | Sementes agrícolas para plantio | `seed_hop`, `seed_apple`, `seed_potato`, `seed_tobacco` |
| `resources-animal-...`| Peles, couros e partes de animais | `resource_skin_buck_star_1`, `resource_hide_cow1_star_3` |
| `collector-items/` | Fósseis, pontas de flecha e dentes | `collector_fossil_common_petrified_wood`, `resource_tooth_cougar` |
| `documents/` | Mapas, cartas e plantas arquitetônicas| `blueprint`, `document_map`, `letter_generic`, `stack_letters` |
| `jewelry/` | Joias, relicários e anéis de ouro | `provision_necklace_amethyst_richelieu`, `provision_necklace_gold_cross` |
| `clothing-...` | Bandanas, chapéus e acessórios | `clothing_bandana_blue`, `clothing_bandana_purple` |

*(Totalizando 34 categorias especializadas cobrindo todos os sistemas do ecossistema).*

---

## 3. Mecanismo de Resolução Automática (`index.json`)

O arquivo estático `html/index.json` contém um mapa associativo chave-valor que indexa cada nome de item para seu respectivo caminho relativo:

```json
{
  "weapon_thrown_tomahawk": "icons/weapons/weapon_thrown_tomahawk.png",
  "tool_resource_knife": "icons/tools/tool_resource_knife.png",
  "consumable_alcohol_bourbon": "icons/consumable-alcohol/consumable_alcohol_bourbon.png",
  "resource_iron_dirty": "icons/materials-mining/resource_iron_dirty.png"
}
```

Quando o motor `westrp_ui` carrega, ele busca esse índice via HTTP local:
`https://cfx-nui-westrp_assets/html/index.json`

A função JavaScript `resolveItemIcon(item)` verifica se o item possui um `id` ou `icon` correspondente no mapa. Se encontrar, monta automaticamente a URL:
`https://cfx-nui-westrp_assets/html/icons/...`

---

## 4. Como Consumir Ícones em Scripts Lua

Você **não precisa digitar o caminho da pasta**. Apenas informe o identificador nativo do item:

### No Dock Lateral
```lua
{
    id = 'consumable_alcohol_bourbon',
    label = 'Bourbon Envelhecido',
    badge = '$ 3.50',
    description = 'Destilado forte que recupera o fôlego.'
}
```

### Na Vitrine do Panel (Grid)
```lua
{
    id = 'weapon_thrown_tomahawk',
    title = 'Tomahawk de Caça',
    subtitle = 'Forjado em aço carbono balanceado.',
    price = 35.0,
    stock = 10
}
```

### Nas Receitas de Crafting
```lua
{
    id = 'tool_resource_knife',
    title = 'Faca de Caça Rústica',
    requirements = {
        { item = 'resource_iron_dirty', label = 'Minério de Ferro', current = 4, required = 2 },
        { item = 'resource_coal', label = 'Carvão Mineral', current = 10, required = 1 }
    }
}
```

---

## 5. Como Adicionar Novos Ícones ao Acervo

1. Nomeie sua imagem em formato PNG seguindo o padrão `snake_case` (ex: `meu_item_personalizado.png`).
2. Salve o arquivo na categoria apropriada dentro de:
   `resources/[westrp]/[assets]/westrp_assets/html/icons/<categoria>/`
3. Execute a regeneração do índice conforme a seção abaixo.

---

## 6. Regeneração do Índice (`index.json`)

Sempre que adicionar ou renomear arquivos no acervo, o `index.json` precisa ser atualizado.

### Script de Regeneração Automática (Node.js)
Execute o comando abaixo via PowerShell a partir da pasta raiz do `westrp_assets`:

```bash
node -e "
const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, 'html', 'icons');
const output = {};

function scanDir(dir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      scanDir(fullPath);
    } else if (file.toLowerCase().endsWith('.png')) {
      const key = path.basename(file, '.png').toLowerCase();
      const relPath = path.relative(path.join(__dirname, 'html'), fullPath).replace(/\\\\/g, '/');
      output[key] = relPath;
    }
  }
}

scanDir(baseDir);

const jsonContent = JSON.stringify(output, null, 2);
fs.writeFileSync(path.join(__dirname, 'html', 'index.json'), jsonContent, 'utf8');
console.log('Índice regenerado com sucesso! Total de itens indexados:', Object.keys(output).length);
"
```

> **IMPORTANTE:** O arquivo `index.json` **deve ser gravado em UTF-8 puro (sem BOM)**. O uso de `Out-File` do PowerShell antigo pode introduzir cabeçalhos UTF-16 ou UTF-8 BOM que causam erros de parse no motor Chromium (CEF) do RedM.

---

## 7. Boas Práticas de Nomenclatura & Formato

* **Extensão Obrigatória:** `.png` com fundo transparente.
* **Resolução Recomendada:** Imagens entre `64x64px` e `128x128px`. Imagens com mais de `256x256px` consomem memória de textura desnecessária para ícones de inventário.
* **Padrão de Nomenclatura:** `snake_case` sem caracteres especiais, espaços ou acentuação:
  * ❌ `Faca de Caça (1).png`
  * ❌ `item-faca.png`
  * ✅ `tool_resource_knife.png`
  * ✅ `consumable_coffee.png`
