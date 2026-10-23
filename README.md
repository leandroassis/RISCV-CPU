# RISC-V CPU — Pipeline de 5 estágios com extensão vetorial (SIMD)

Processador de 32 bits que implementa um subconjunto da ISA **RV32I**, organizado em um **pipeline clássico de 5 estágios** (IF, ID, EX, MEM, WB), com **unidade de forwarding**, **unidade de detecção de hazards** e uma **extensão vetorial (SIMD)** própria para operações empacotadas sobre registradores de 32 bits.

Cada bloco da CPU é descrito em **VHDL** (`src/`) e a CPU completa é montada no **Logisim-evolution** (`logisim/`), onde os blocos VHDL são instanciados e interligados com memórias, multiplexadores e o clock do simulador.

---

## Sumário

1. [Estrutura do repositório](#estrutura-do-repositório)
2. [Visão geral da arquitetura](#visão-geral-da-arquitetura)
3. [Pipeline](#pipeline)
4. [Registradores de pipeline](#registradores-de-pipeline)
5. [Descrição dos arquivos VHDL](#descrição-dos-arquivos-vhdl)
6. [Formatos de dados](#formatos-de-dados)
7. [Formatos de instrução e instruções suportadas](#formatos-de-instrução-e-instruções-suportadas)
8. [Unidade de controle](#unidade-de-controle)
9. [ALU e controle da ALU](#alu-e-controle-da-alu)
10. [Extensão vetorial (SIMD)](#extensão-vetorial-simd)
11. [Unidade de forwarding](#unidade-de-forwarding)
12. [Unidade de hazards e tratamento de desvios](#unidade-de-hazards-e-tratamento-de-desvios)
13. [Programa de exemplo](#programa-de-exemplo)
14. [Como simular](#como-simular)
15. [Limitações e pontos de atenção](#limitações-e-pontos-de-atenção)
16. [Referências](#referências)

---

## Estrutura do repositório

```
RISCV-CPU/
├── src/                      # Blocos da CPU em VHDL
│   ├── prog_count.vhd        # Contador de programa (PC)
│   ├── IF_ID.vhd             # Registrador de pipeline IF/ID
│   ├── ctrl_unit.vhd         # Unidade de controle principal
│   ├── reg_file.vhd          # Banco de registradores (32 x 32 bits)
│   ├── imm_gen.vhd           # Gerador de imediatos
│   ├── hzd_unit.vhd          # Unidade de detecção de hazards (load-use)
│   ├── ID_EX.vhd             # Registrador de pipeline ID/EX
│   ├── alu_ctrl.vhd          # Controle da ALU (+ detecção de instrução vetorial)
│   ├── alu.vhd               # ALU escalar
│   ├── alu_simd.vhd          # ALU vetorial (SIMD)
│   ├── CLA_4.vhd             # Somador carry-lookahead de 4 bits (bloco da ALU SIMD)
│   ├── fwd_unit.vhd          # Unidade de forwarding
│   ├── EX_MEM.vhd            # Registrador de pipeline EX/MEM
│   ├── mem_br_taken.vhd      # Lógica de desvio tomado / flush
│   └── MEM_WB.vhd            # Registrador de pipeline MEM/WB
├── logisim/
│   ├── circuito_cpu_no_pipeline.circ   # CPU monociclo (sem pipeline)
│   ├── circuito_cpu.circ               # CPU com pipeline, forwarding e hazards
│   └── circuito_cpu_com_SIMD.circ      # CPU com pipeline + ALU vetorial (versão final)
├── bin/
│   ├── programa_teste.txt    # Programa de teste em assembly + codificação binária
│   └── fill_memory.txt       # Mesmo programa em hexadecimal (imagem da ROM)
├── test/
│   ├── files/                # Testbenches VHDL e scripts auxiliares
│   └── waveforms/            # Formas de onda geradas (GHW)
├── docs/
│   ├── doc_instruções_vetoriais   # Codificação das instruções vetoriais
│   ├── riscv-spec-v2.2.pdf
│   └── riscv-user-isa.pdf
└── Makefile                  # Análise/simulação com GHDL
```

---

## Visão geral da arquitetura

| Característica            | Valor                                                                  |
|---------------------------|------------------------------------------------------------------------|
| Largura de dados          | 32 bits                                                                |
| Banco de registradores    | 32 registradores de 32 bits (`x0`–`x31`), `x0` fixo em zero            |
| Organização de memória    | Harvard: ROM de programa e RAM de dados separadas                      |
| Memória de programa (ROM) | 2²⁴ palavras de 32 bits (endereço de 24 bits)                          |
| Memória de dados (RAM)    | 2²⁴ palavras de 32 bits (endereço de 24 bits)                          |
| Endereçamento             | **Por palavra** — o PC avança de 1 em 1 e cada endereço é uma palavra de 32 bits |
| Pipeline                  | 5 estágios: IF → ID → EX → MEM → WB                                    |
| Forwarding                | EX/MEM → EX e MEM/WB → EX (operandos da ALU) e EX/MEM → dado de store  |
| Hazards de dados          | Detecção de load-use com stall                                         |
| Desvios                   | Resolvidos no estágio MEM, predição estática "não tomado", flush de IF/ID e ID/EX |
| Extensão vetorial         | add, sub, sll, srl (R) e addi, slli, srli (I) sobre 8×4, 4×8, 2×16 ou 1×32 bits |
| Clock                     | Registradores de pipeline e PC na borda de **subida**; banco de registradores e RAM escrevem na borda de **descida** |

### Diagrama de blocos

```
          IF                 ID                       EX                         MEM                 WB
  ┌──────────────┐ ┌────┐ ┌──────────────┐ ┌────┐ ┌──────────────────────┐ ┌─────┐ ┌───────────┐ ┌─────┐ ┌──────────┐
  │  prog_count  │ │    │ │  ctrl_unit   │ │    │ │ fwd mux A ─┐         │ │     │ │           │ │     │ │          │
  │      │       │ │ I  │ │  reg_file ◄──┼─┼─ I ┼─┼─ fwd mux B │         │ │  E  │ │  data_mem │ │  M  │ │ mux      │
  │      ▼       │ │ F  │ │  imm_gen     │ │ D  │ │    │       ▼         │ │  X  │ │   (RAM)   │ │  E  │ │ mem_to_  │
  │ program_mem  │─┤ /  ├─┤  hzd_unit    ├─┤ /  ├─┤  pc/rs1  rs2/imm    ├─┤  /  ├─┤           ├─┤  M  ├─┤ reg ─────┼──► reg_file
  │    (ROM)     │ │ I  │ │              │ │ E  │ │    ▼       ▼         │ │  M  │ │ mem_br_   │ │  /  │ │          │   (write)
  │              │ │ D  │ │              │ │ X  │ │  alu   alu_simd     │ │  E  │ │  taken    │ │  W  │ │          │
  │              │ │    │ │              │ │    │ │    └─mux vetorial──┐ │ │  M  │ │  (flush)  │ │  B  │ │          │
  └──────▲───────┘ └────┘ └──────────────┘ └────┘ │   alu_ctrl  fwd_unit │ └─────┘ └─────┬─────┘ └─────┘ └──────────┘
         │                                        └──────────────────────┘               │
         └──────────────── alvo do desvio (EX/MEM.pc | EX/MEM.rs1) + EX/MEM.imm ─────────┘
```

---

## Pipeline

### IF — Busca de instrução

**Arquivos:** [prog_count.vhd](src/prog_count.vhd), [IF_ID.vhd](src/IF_ID.vhd), ROM `program_mem` (Logisim).

- O `prog_count` mantém o PC. A cada borda de subida, se `pc_write = 1`:
  - sem desvio: `PC ← PC + 1` (próxima palavra);
  - com desvio tomado (`branch = 1`): `PC ← EX/MEM.pc + EX/MEM.imm` (beq, bne, jal) ou `PC ← EX/MEM.rs1 + EX/MEM.imm` (jalr), conforme o sinal `pc_reg_mux` (`pc_reg_branch`).
- Os 24 bits menos significativos do PC endereçam a ROM de programa, que entrega a instrução de 32 bits.
- Instrução e PC são gravados no registrador **IF/ID**, que possui *write enable* (controlado pela hazard unit) e *flush* (zera o conteúdo quando um desvio é tomado).

### ID — Decodificação e leitura de registradores

**Arquivos:** [ctrl_unit.vhd](src/ctrl_unit.vhd), [reg_file.vhd](src/reg_file.vhd), [imm_gen.vhd](src/imm_gen.vhd), [hzd_unit.vhd](src/hzd_unit.vhd), [ID_EX.vhd](src/ID_EX.vhd).

- A `ctrl_unit` decodifica o `opcode` (bits 6:0) e gera os sinais de controle de EX, MEM e WB.
- O `reg_file` lê `rs1` (bits 19:15) e `rs2` (bits 24:20) de forma combinacional. A escrita (vinda de WB) ocorre na **borda de descida**, de modo que um registrador escrito em WB pode ser lido corretamente em ID no mesmo ciclo (escrita na primeira metade, leitura na segunda).
- O `imm_gen` extrai e estende o sinal do imediato conforme o formato da instrução.
- A `hzd_unit` compara `rs1`/`rs2` da instrução em ID com o `rd` da instrução em EX para detectar dependências load-use e, se necessário, congela PC e IF/ID.
- Instrução, PC, valores de `rs1`/`rs2`, imediato e sinais de controle seguem para **ID/EX**.

### EX — Execução

**Arquivos:** [alu_ctrl.vhd](src/alu_ctrl.vhd), [alu.vhd](src/alu.vhd), [alu_simd.vhd](src/alu_simd.vhd), [CLA_4.vhd](src/CLA_4.vhd), [fwd_unit.vhd](src/fwd_unit.vhd), [EX_MEM.vhd](src/EX_MEM.vhd).

Caminho de dados do estágio (multiplexadores implementados no Logisim):

```
 ID/EX.rs1 ─┐
 MEM/WB.res ┤ mux fwd_a ──► mux pc_reg_alu (0: rs1, 1: PC) ──► entrada A ─┬─► alu ──────┐
 EX/MEM.alu ┤  (4:1)                                                      │             ├─► mux vetorial ─► EX/MEM.alu_result
 0 ─────────┘                                                             └─► alu_simd ─┘    (0: alu, 1: simd)
 ID/EX.rs2 ─┐
 MEM/WB.res ┤ mux fwd_b ──► mux alu_src (0: rs2, 1: imm) ──────► entrada B ──► alu / alu_simd
 EX/MEM.alu ┤  (4:1)
 0 ─────────┘
 ID/EX.rs2 ─┐ mux fwd_c ──► EX/MEM.reg_b (dado a ser escrito por sw)
 EX/MEM.alu ┘  (2:1)
```

- A `alu_ctrl` combina o `alu_op` (vindo da unidade de controle) com `funct3`/`funct7`/`opcode` da instrução e gera o código de operação de 4 bits da ALU e o sinal `vetorial`.
- A ALU escalar (`alu`) e a ALU vetorial (`alu_simd`) recebem os mesmos operandos e operam em paralelo; o sinal `vetorial` seleciona qual resultado segue para EX/MEM.
- A saída `aux_br` da ALU escalar indica a condição de desvio (igualdade, desigualdade ou salto incondicional).
- A `fwd_unit` controla os multiplexadores de forwarding (ver [Unidade de forwarding](#unidade-de-forwarding)).
- O `rd` (bits 11:7 da instrução em ID/EX) é propagado como endereço de write-back.

### MEM — Acesso à memória e resolução de desvios

**Arquivos:** [mem_br_taken.vhd](src/mem_br_taken.vhd), [MEM_WB.vhd](src/MEM_WB.vhd), RAM `data_mem` (Logisim).

- O resultado da ALU (bits 23:0) endereça a RAM de dados. `sw` escreve `EX/MEM.reg_b` na RAM (escrita na borda de descida); `lw` lê a palavra endereçada.
- O desvio é resolvido aqui: `desvio_tomado = EX/MEM.branch AND EX/MEM.aux_br`. Esse sinal:
  - carrega o novo PC no `prog_count` (via porta AND `branch_en` no Logisim);
  - gera o `flush` em `mem_br_taken`, que zera IF/ID e ID/EX.

### WB — Escrita no banco de registradores

**Arquivos:** [MEM_WB.vhd](src/MEM_WB.vhd), [reg_file.vhd](src/reg_file.vhd).

- Um multiplexador controlado por `mem_to_reg` escolhe entre o resultado da ALU (`0`) e o dado lido da memória (`1`).
- O valor resultante (`MEM_WB_result`) é escrito em `rd` quando `reg_write = 1` (escritas em `x0` são ignoradas) e também é usado como fonte de forwarding MEM/WB.

---

## Registradores de pipeline

Todos são atualizados na borda de subida do clock.

| Registrador | Dados armazenados | Controle armazenado | Sinais especiais |
|---|---|---|---|
| **IF/ID** ([IF_ID.vhd](src/IF_ID.vhd)) | instrução, PC | — | `write` (stall), `flush` (zera, assíncrono) |
| **ID/EX** ([ID_EX.vhd](src/ID_EX.vhd)) | instrução, PC, valor de `rs1`, valor de `rs2`, imediato | EX: `pc_reg_alu`, `alu_src`, `alu_op` · MEM: `mem_w`, `mem_r`, `branch`, `pc_reg_br` · WB: `mem_to_reg`, `reg_w` | `bubble` (não atualiza), `flush` (zera, assíncrono) |
| **EX/MEM** ([EX_MEM.vhd](src/EX_MEM.vhd)) | resultado da ALU, `aux_br`, valor de `rs1`, valor de `rs2` (após forwarding C), imediato, `rd`, PC¹ | MEM: `mem_w`, `mem_r`, `branch`, `pc_reg_br` · WB: `mem_to_reg`, `reg_w` | — |
| **MEM/WB** ([MEM_WB.vhd](src/MEM_WB.vhd)) | resultado da ALU, dado da memória, `rd` | WB: `mem_to_reg`, `reg_w` | — |

¹ O campo PC do EX/MEM existe na versão do VHDL embutida no circuito Logisim (portas `pc_in`/`pc_out`), usada como base do cálculo do alvo de desvio; ver [Limitações](#limitações-e-pontos-de-atenção).

---

## Descrição dos arquivos VHDL

| Arquivo | Estágio | Função |
|---|---|---|
| [prog_count.vhd](src/prog_count.vhd) | IF | Registrador do PC. Incrementa de 1 em 1 ou carrega `base + imm` em desvios, onde `base` é o PC da instrução de desvio ou `rs1` (jalr). Respeita `pc_w` (stall). |
| [IF_ID.vhd](src/IF_ID.vhd) | IF→ID | Registrador de pipeline com *write enable* e *flush*. |
| [ctrl_unit.vhd](src/ctrl_unit.vhd) | ID | Decodificador de `opcode` → sinais de controle (tabela em [Unidade de controle](#unidade-de-controle)). |
| [reg_file.vhd](src/reg_file.vhd) | ID / WB | 32 registradores de 32 bits, 2 portas de leitura combinacionais e 1 porta de escrita na borda de descida; escrita em `x0` é descartada. |
| [imm_gen.vhd](src/imm_gen.vhd) | ID | Monta o imediato de 32 bits com extensão de sinal para os formatos I, S, B, U e J. |
| [hzd_unit.vhd](src/hzd_unit.vhd) | ID | Detecta hazard load-use e gera `pc_write`, `if_id_write` e `bubble`. |
| [ID_EX.vhd](src/ID_EX.vhd) | ID→EX | Registrador de pipeline com `bubble` e `flush`. |
| [alu_ctrl.vhd](src/alu_ctrl.vhd) | EX | Traduz `alu_op` + `funct3`/`funct7`/`opcode` no código de 4 bits da ALU e sinaliza instruções vetoriais (`vetorial`). |
| [alu.vhd](src/alu.vhd) | EX | ALU escalar: soma, subtração, and, or, xor, sll, srl, comparações de igualdade, `A+1` e repasse de `B`. Gera `aux_br`. |
| [alu_simd.vhd](src/alu_simd.vhd) | EX | ALU vetorial: soma/subtração e deslocamentos lógicos por faixa (*lane*) para 8×4, 4×8, 2×16 e 1×32 bits. |
| [CLA_4.vhd](src/CLA_4.vhd) | EX | Somador de 4 bits com geração paralela de *propagate*/*generate*; bloco básico dos somadores da ALU SIMD. |
| [fwd_unit.vhd](src/fwd_unit.vhd) | EX | Gera os seletores `forward_a`, `forward_b` (2 bits) e `forward_c` (1 bit). |
| [EX_MEM.vhd](src/EX_MEM.vhd) | EX→MEM | Registrador de pipeline. |
| [mem_br_taken.vhd](src/mem_br_taken.vhd) | MEM | `flush = branch AND aux_br`: indica desvio tomado e esvazia os estágios anteriores. |
| [MEM_WB.vhd](src/MEM_WB.vhd) | MEM→WB | Registrador de pipeline. |

Componentes que existem apenas no Logisim: ROM de programa, RAM de dados, clock, multiplexadores de forwarding / `pc_reg_alu` / `alu_src` / vetorial / `mem_to_reg`, porta AND `branch_en` e splitters que extraem campos da instrução.

---

## Formatos de dados

### Escalares

- **Palavra:** 32 bits. Todos os registradores, posições de memória e instruções têm 32 bits.
- **Inteiros:** complemento de dois para soma, subtração e cálculo de endereços/alvos de desvio.
- **Deslocamentos:** lógicos (preenchimento com zeros), quantidade dada pelos 5 bits menos significativos do segundo operando.
- **Memória:** endereçada por palavra. Não há acesso a byte ou meia-palavra: `lw`/`sw` sempre transferem 32 bits e o endereço `rs1 + imm` é o índice da palavra.
- **PC:** conta instruções (não bytes); a instrução seguinte está em `PC + 1`.

### Vetoriais (empacotados)

Um registrador de 32 bits é interpretado como um vetor de *N* elementos de *w* bits, conforme o campo `vec` da instrução. O elemento 0 ocupa os bits menos significativos:

| `vec` | Configuração | Elemento *i* ocupa os bits |
|:-----:|---|---|
| `000` | 8 elementos × 4 bits  | `[4i+3 : 4i]`   |
| `001` | 4 elementos × 8 bits  | `[8i+7 : 8i]`   |
| `010` | 2 elementos × 16 bits | `[16i+15 : 16i]` |
| `011` | 1 elemento × 32 bits  | `[31 : 0]`      |
| outros | inválido — a saída da ALU SIMD fica em alta impedância (`Z`) | — |

```
 vec = 000   | e7 | e6 | e5 | e4 | e3 | e2 | e1 | e0 |   (4 bits cada)
 vec = 001   |   e3    |   e2    |   e1    |   e0    |   (8 bits cada)
 vec = 010   |        e1         |        e0         |   (16 bits cada)
 vec = 011   |                  e0                   |   (32 bits)
             31                                      0
```

---

## Formatos de instrução e instruções suportadas

### Formatos base (RV32I)

```
        31        25 24    20 19    15 14  12 11         7 6       0
 R    | funct7      | rs2    | rs1    |funct3| rd         | opcode  |
 I    | imm[11:0]            | rs1    |funct3| rd         | opcode  |
 S    | imm[11:5]   | rs2    | rs1    |funct3| imm[4:0]   | opcode  |
 B    |[11]| [9:4]  | rs2    | rs1    |funct3|[3:0] |[10] | opcode  |
 U    | imm[31:12]                           | rd         | opcode  |
 J    |[19]| [9:0]        |[10]| [18:11]     | rd         | opcode  |
```

Os campos ficam nas mesmas posições de bit do padrão RISC-V. A diferença está nos imediatos de **B** e **J**: como o PC é endereçado por palavra, o `imm_gen` **não acrescenta o bit 0 implícito** do padrão, e o valor resultante é o deslocamento **em número de instruções**:

- **B:** `imm = sext(inst[31], inst[7], inst[30:25], inst[11:8])` — 12 bits;
- **J:** `imm = sext(inst[31], inst[19:12], inst[20], inst[30:21])` — 20 bits;
- **U:** `imm = inst[31:12] << 12`;
- **I** (slli/srli): `imm = inst[24:20]` (shamt).

Na prática, para saltar *k* instruções, a instrução deve ser codificada como se o deslocamento em bytes fosse `2k` em um montador padrão (ex.: `bne x6, x7, -2` é codificado como `0xFE731EE3`, que um montador padrão produziria para um deslocamento de −4 bytes).

### Instruções suportadas

| Instrução | Formato | opcode | funct3 | funct7 | Operação |
|---|:-:|:-:|:-:|:-:|---|
| `add`   | R | `0110011` | `000` | `0000000` | `rd ← rs1 + rs2` |
| `sub`   | R | `0110011` | `000` | `0100000` | `rd ← rs1 − rs2` |
| `sll`   | R | `0110011` | `001` | `0000000` | `rd ← rs1 << rs2[4:0]` |
| `xor`   | R | `0110011` | `100` | `0000000` | `rd ← rs1 ^ rs2` |
| `srl`   | R | `0110011` | `101` | `0000000` | `rd ← rs1 >> rs2[4:0]` (lógico) |
| `or`    | R | `0110011` | `110` | `0000000` | `rd ← rs1 \| rs2` |
| `and`   | R | `0110011` | `111` | `0000000` | `rd ← rs1 & rs2` |
| `addi`  | I | `0010011` | `000` | — | `rd ← rs1 + imm` |
| `slli`  | I | `0010011` | `001` | `0000000` | `rd ← rs1 << shamt` |
| `xori`  | I | `0010011` | `100` | — | `rd ← rs1 ^ imm` |
| `srli`  | I | `0010011` | `101` | `0000000` | `rd ← rs1 >> shamt` (lógico) |
| `ori`   | I | `0010011` | `110` | — | `rd ← rs1 \| imm` |
| `andi`  | I | `0010011` | `111` | — | `rd ← rs1 & imm` |
| `lw`    | I | `0000011` | `010` | — | `rd ← MEM[rs1 + imm]` |
| `sw`    | S | `0100011` | `010` | — | `MEM[rs1 + imm] ← rs2` |
| `lui`   | U | `0110111` | — | — | `rd ← imm << 12` |
| `auipc` | U | `0010111` | — | — | `rd ← PC + (imm << 12)` |
| `beq`   | B | `1100011` | `000` | — | se `rs1 = rs2`: `PC ← PC + imm` |
| `bne`   | B | `1100011` | `001` | — | se `rs1 ≠ rs2`: `PC ← PC + imm` |
| `jal`   | J | `1101111` | — | — | `rd ← PC + 1`; `PC ← PC + imm` |
| `jalr`  | I | `1100111` | `000` | — | `rd ← PC + 1`; `PC ← rs1 + imm` |

O `funct3` de `lw`/`sw` não é decodificado (o acesso é sempre de uma palavra). As instruções vetoriais estão descritas em [Extensão vetorial](#extensão-vetorial-simd).

---

## Unidade de controle

A [ctrl_unit.vhd](src/ctrl_unit.vhd) decodifica apenas o `opcode`. Significado dos sinais:

| Sinal | Estágio | `0` | `1` |
|---|:-:|---|---|
| `pc_reg` (`pc_reg_alu`) | EX  | entrada A da ALU = `rs1` | entrada A da ALU = PC |
| `alu_src`               | EX  | entrada B da ALU = `rs2` | entrada B da ALU = imediato |
| `alu_op` (3 bits)       | EX  | ver tabela da ALU | |
| `branch`                | MEM | não é desvio | desvio / salto |
| `pc_reg_branch`         | MEM/IF | base do alvo = PC | base do alvo = `rs1` |
| `mem_read`              | MEM | — | lê a RAM |
| `mem_write`             | MEM | — | escreve na RAM |
| `mem_to_reg`            | WB  | escreve resultado da ALU | escreve dado da memória |
| `reg_write`             | WB  | não escreve | escreve em `rd` |

Valores gerados por classe de instrução (`X` = irrelevante):

| Classe (opcode) | pc_reg | alu_src | alu_op | branch | pc_reg_branch | mem_read | mem_write | mem_to_reg | reg_write |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| R `0110011`              | 0 | 0 | `001` | 0 | 0 | X | X | 0 | 1 |
| I `0010011`              | 0 | 1 | `010` | 0 | 0 | X | X | 0 | 1 |
| lw `0000011`             | 0 | 1 | `100` | 0 | 0 | 1 | 0 | 1 | 1 |
| sw `0100011`             | 0 | 1 | `100` | 0 | 0 | 0 | 1 | X | 0 |
| beq/bne `1100011`        | 0 | 0 | `011` | 1 | 0 | X | X | X | 0 |
| lui `0110111`            | X | 1 | `110` | 0 | 0 | X | X | 0 | 1 |
| auipc `0010111`          | 1 | 1 | `100` | 0 | 0 | X | X | 0 | 1 |
| jal `1101111`            | 1 | X | `101` | 1 | 0 | X | X | 0 | 1 |
| jalr `1100111`           | 1 | X | `101` | 1 | 1 | X | X | 0 | 1 |
| SIMD R `0001111`         | 0 | 0 | `001` | 0 | 0 | X | X | 0 | 1 |
| SIMD addi `1110011`      | 0 | 1 | `010` | 0 | 0 | X | X | 0 | 1 |
| SIMD slli `0011011`      | 0 | 1 | `010` | 0 | 0 | X | X | 0 | 1 |
| SIMD srli `0111011`      | 0 | 1 | `010` | 0 | 0 | X | X | 0 | 1 |

Em `jal`/`jalr`, a ALU calcula `PC + 1` (endereço de retorno escrito em `rd`) e sempre ativa `aux_br`, tornando o salto incondicional; o alvo é calculado separadamente pelo `prog_count`.

---

## ALU e controle da ALU

### `alu_op` (unidade de controle → [alu_ctrl.vhd](src/alu_ctrl.vhd))

| `alu_op` | Significado |
|:-:|---|
| `000` | nop |
| `001` | lógico-aritmética tipo R (operação definida por `funct3`/`funct7`) |
| `010` | lógico-aritmética tipo I (operação definida por `funct3`) |
| `011` | desvio condicional (`funct3`: `000` beq, `001` bne) |
| `100` | soma `A + B` (lw, sw, auipc) |
| `101` | `A + 1` com `aux_br = 1` (jal, jalr) |
| `110` | repassa `B` (lui) |
| `111` | nop |

### Código de operação da ALU ([alu.vhd](src/alu.vhd))

| Código | Operação | `aux_br` |
|:-:|---|:-:|
| `0000` | nop (saída = A) | 0 |
| `0001` | `A + B` | 0 |
| `0010` | `A − B` | 0 |
| `0011` | `A and B` | 0 |
| `0100` | `A or B` | — |
| `0101` | `A xor B` | 0 |
| `0110` | `A << B[4:0]` | 0 |
| `0111` | `A >> B[4:0]` (lógico) | 0 |
| `1000` | igualdade | 1 se `A = B` |
| `1001` | desigualdade | 1 se `A ≠ B` |
| `1010` | `A + 1` | 1 |
| `1011` | saída = `B` | 0 |

A ALU SIMD usa os mesmos códigos `0001` (soma), `0010` (subtração), `0110` (sll) e `0111` (srl).

---

## Extensão vetorial (SIMD)

A extensão adiciona operações empacotadas (*packed SIMD*) sobre registradores escalares de 32 bits — não há banco de registradores vetoriais separado. O tamanho dos elementos é escolhido instrução a instrução pelo campo `vec` (ver [Formatos de dados](#vetoriais-empacotados)).

Os opcodes usados reaproveitam espaços da ISA padrão que esta CPU não implementa (`MISC-MEM`, `SYSTEM`, `OP-IMM-32` e `OP-32`).

### Codificação

Conforme [docs/doc_instruções_vetoriais](docs/doc_instruções_vetoriais):

```
            31   28 27  25 24    20 19    15 14  12 11     7 6       0
 R vetorial| 0000  | vec  | rs2    | rs1    | op   | rd     | 0001111 |
            31                  20 19    15 14  12 11     7 6       0
 addi vet. | imm[11:0]           | rs1    | vec  | rd     | 1110011 |
            31        25 24    20 19    15 14  12 11     7 6       0
 slli vet. | 0000000   | shamt  | rs1    | vec  | rd     | 0011011 |
 srli vet. | 0000000   | shamt  | rs1    | vec  | rd     | 0111011 |
```

- No formato R, `funct3` seleciona a operação e `vec` ocupa os bits 27:25 (parte baixa do `funct7`).
- No formato I, `vec` ocupa a posição do `funct3` (bits 14:12), pois a operação já é definida pelo opcode.

### Instruções

Os mnemônicos com prefixo `v` são usados apenas neste documento para distinguir das instruções escalares.

| Instrução | opcode | op (funct3) | Operação por elemento *i* |
|---|:-:|:-:|---|
| `vadd`  | `0001111` | `001` | `rd[i] ← rs1[i] + rs2[i]` (mod 2ʷ) |
| `vsub`  | `0001111` | `010` | `rd[i] ← rs1[i] − rs2[i]` (mod 2ʷ) |
| `vsll`  | `0001111` | `011` | `rd[i] ← rs1[i] << s` |
| `vsrl`  | `0001111` | `100` | `rd[i] ← rs1[i] >> s` (lógico) |
| `vaddi` | `1110011` | — (`vec`) | `rd[i] ← rs1[i] + imm32[i]` |
| `vslli` | `0011011` | — (`vec`) | `rd[i] ← rs1[i] << shamt` |
| `vsrli` | `0111011` | — (`vec`) | `rd[i] ← rs1[i] >> shamt` (lógico) |

`auipc` vetorial não foi implementado.

### Semântica

- **Soma e subtração:** cada elemento é somado de forma independente; o *carry* não se propaga de um elemento para o seguinte (aritmética modular por elemento). A subtração é feita como `A + not(B) + 1`, com *carry-in* `1` em cada elemento.
- **Deslocamentos:** todos os elementos são deslocados pela **mesma quantidade** `s`, tirada dos bits menos significativos do segundo operando (`rs2` ou `shamt`). São usados `log2(w) + 1` bits — `B[2:0]` para 4 bits, `B[3:0]` para 8, `B[4:0]` para 16 e `B[5:0]` para 32. Se `s ≥ w`, o resultado é zero; se `s = 0`, o operando passa inalterado. Bits deslocados para fora de um elemento são descartados (não invadem o vizinho).
- **Imediato de `vaddi`:** o imediato de 12 bits é estendido para 32 bits e particionado como um vetor comum — **não** é replicado em cada elemento. Ex.: com `vec = 000`, `imm = 1` soma 1 só ao elemento 0, enquanto `imm = −1` (`0xFFFFFFFF`) soma `0xF` (−1) a todos os elementos.

### Hardware ([alu_simd.vhd](src/alu_simd.vhd))

- **Somadores:** quatro arranjos de 8 somadores [CLA_4](src/CLA_4.vhd) (32 bits cada), um por configuração:
  - `ints_8` — 8 CLA_4 independentes (elementos de 4 bits);
  - `ints_4` — 4 grupos de 2 CLA_4 encadeados (elementos de 8 bits);
  - `ints_2` — 2 grupos de 4 CLA_4 encadeados (elementos de 16 bits);
  - `ints_1` — 8 CLA_4 encadeados (32 bits).

  O campo `vec` seleciona a saída do arranjo correspondente.
- **Deslocadores:** deslocamento lógico por elemento para cada configuração, selecionado por `vec`.
- **Seleção de `vec`:** bits 14:12 para os opcodes `1110011`, `0011011` e `0111011` (formato I); bits 27:25 para os demais (formato R).
- **Integração:** a `alu_ctrl` ativa `vetorial = 1` para os opcodes vetoriais, e um multiplexador no estágio EX seleciona a saída da `alu_simd` no lugar da `alu`. Os operandos passam pelos mesmos multiplexadores de forwarding da ALU escalar, então instruções vetoriais e escalares podem ser intercaladas livremente no pipeline.

---

## Unidade de forwarding

**Arquivo:** [fwd_unit.vhd](src/fwd_unit.vhd)

Resolve dependências RAW entre instruções próximas, encaminhando resultados ainda não escritos no banco de registradores diretamente para o estágio EX.

**Entradas:** `rs1`, `rs2` e `rd` da instrução em EX (extraídos de `ID/EX.instr`), `rd` e `reg_write` de EX/MEM e de MEM/WB.

**Lógica** (prioridade para o resultado mais recente, EX/MEM):

```
se EX/MEM.reg_write e EX/MEM.rd ≠ x0:
    se EX/MEM.rd = ID/EX.rs1: forward_a = 10
    se EX/MEM.rd = ID/EX.rs2: forward_b = 10, forward_c = 1

se MEM/WB.reg_write e MEM/WB.rd ≠ x0 e MEM/WB.rd = ID/EX.rs1
   e não houve forwarding de EX/MEM para rs1:             forward_a = 01
(idem para rs2 → forward_b = 01)
```

**Seletores dos multiplexadores:**

| Sinal | Valor | Fonte do operando |
|---|:-:|---|
| `forward_a` / `forward_b` | `00` | valor lido do banco em ID (`ID/EX.rs1` / `ID/EX.rs2`) |
|                           | `01` | `MEM_WB_result` — saída do mux `mem_to_reg`, inclui dados vindos de `lw` |
|                           | `10` | `EX/MEM.alu_result` |
|                           | `11` | constante 0 (não utilizado) |
| `forward_c`               | `0`  | `ID/EX.rs2` |
|                           | `1`  | `EX/MEM.alu_result` |

- Os muxes de forwarding ficam **antes** dos muxes `pc_reg_alu` e `alu_src`; por isso, quando o operando B é um imediato, um eventual `forward_b` não tem efeito.
- `forward_c` controla o dado que segue para EX/MEM como valor a ser gravado por `sw`, garantindo que um store use o resultado da instrução imediatamente anterior.
- Como `beq`/`bne` comparam os operandos na ALU, os desvios condicionais também se beneficiam do forwarding.
- Dependências de distância 3 (WB → ID) não precisam de forwarding: o banco escreve na borda de descida e a leitura em ID já vê o valor novo.

---

## Unidade de hazards e tratamento de desvios

### Hazard de dados load-use — [hzd_unit.vhd](src/hzd_unit.vhd)

Um `lw` só tem o dado disponível ao fim do estágio MEM, então uma instrução imediatamente dependente não pode recebê-lo por forwarding a tempo. A hazard unit detecta o caso em ID:

```
se ID/EX.mem_read = 1 e (ID/EX.rd = IF/ID.rs1 ou ID/EX.rd = IF/ID.rs2):
    pc_write    = 0   → PC não avança
    if_id_write = 0   → IF/ID mantém a instrução dependente
    bubble      = 1   → ID/EX não é atualizado
senão:
    pc_write = 1, if_id_write = 1, bubble = 0
```

Depois do stall, o dado do `lw` fica disponível em MEM/WB e chega à instrução dependente pelo forwarding (`forward = 01`).

### Hazard de controle — [mem_br_taken.vhd](src/mem_br_taken.vhd)

- **Política:** predição estática "não tomado". O pipeline continua buscando instruções sequenciais até o desvio ser resolvido.
- **Resolução:** no estágio MEM, `desvio_tomado = EX/MEM.branch AND EX/MEM.aux_br`.
- **Alvo:** `EX/MEM.pc + EX/MEM.imm` (beq, bne, jal) ou `EX/MEM.rs1 + EX/MEM.imm` (jalr), calculado no `prog_count`.
- **Flush:** quando o desvio é tomado, `mem_br_taken` ativa `flush`, que zera de forma assíncrona IF/ID e ID/EX (sinais de controle em 0, ou seja, NOPs). Na borda seguinte, o PC recebe o alvo e as três instruções buscadas após o desvio (em IF, ID e EX) são descartadas.
- **Custo:** desvio não tomado — 0 ciclos; desvio tomado, `jal` ou `jalr` — 3 ciclos.

---

## Programa de exemplo

[bin/programa_teste.txt](bin/programa_teste.txt) (assembly + binário) e [bin/fill_memory.txt](bin/fill_memory.txt) (imagem hexadecimal para a ROM):

```asm
addi x6, x0, 2047      # x6 = 2047
addi x6, x6, 2047      # x6 = 4094        (forwarding EX/MEM)
addi x6, x6, 1         # x6 = 4095
addi x12, x0, 12       # x12 = 12
sll  x7, x6, x12       # x7 = 4095 << 12 = 0xFFF000
add  x7, x7, x6        # x7 = 0xFFFFFF   (2^24 − 1)
add  x6, x0, x0        # x6 = 0 (índice)
add  x5, x0, x7        # x5 = 0xFFFFFF (valor a escrever)
loop:
sw   x5, 0(x6)         # MEM[x6] = x5
addi x6, x6, 1         # x6++
bne  x6, x7, -2        # volta 2 instruções (para o sw) enquanto x6 ≠ x7
beq  x0, x0, 0         # laço infinito (fim)
```

O programa preenche toda a memória de dados com `0x00FFFFFF` e exercita forwarding EX/MEM e MEM/WB, store, desvio condicional tomado/não tomado e flush.

---

## Como simular

### Logisim-evolution (CPU completa)

1. Abra `logisim/circuito_cpu_com_SIMD.circ` no **Logisim-evolution** (os componentes VHDL ficam embutidos no `.circ`).
2. Carregue o programa na ROM `program_mem`: clique com o botão direito → *Load Image…* → `bin/fill_memory.txt`.
3. Execute com o clock `clk_logisim` (passo a passo ou contínuo) e observe os registradores de pipeline, o banco de registradores e a RAM `data_mem`.

Os outros circuitos servem para comparação: `circuito_cpu_no_pipeline.circ` (monociclo) e `circuito_cpu.circ` (pipeline sem SIMD).

### GHDL (blocos individuais)

O [Makefile](Makefile) analisa todos os arquivos de `src/` com VHDL-2008 e simula o testbench `alu_test`, salvando a forma de onda em `test/waveforms/testbench.ghw` (visualizável no GTKWave):

```bash
make
gtkwave test/waveforms/testbench.ghw
```

Em `test/files/` há testbenches para `alu`, `alu_ctrl`, `ctrl_unit`, `imm_gen` e `prog_count`. Para simulá-los, analise o testbench e troque o nome da entidade nas linhas `ghdl -e`/`ghdl -r`.

---

## Limitações e pontos de atenção

Observações levantadas na revisão do código e dos circuitos:

**Divergência entre `src/` e os circuitos**
- O VHDL embutido nos `.circ` é a versão efetivamente usada. Ele difere de `src/` em dois pontos: o `EX_MEM` embutido tem as portas `pc_in`/`pc_out` (usadas como base do alvo de desvio), e a `alu` embutida devolve `0` em vez de `X` na saída de resultado para beq/bne.

**ISA**
- Não há `sra`/`srai`, `slt`/`sltu`/`slti`/`sltiu`, `blt`/`bge`/`bltu`/`bgeu`, loads/stores de byte ou meia-palavra, `fence` nem `ecall`/`ebreak`. Para deslocamentos, o `funct7` não é verificado (um `sra` seria executado como `srl`).
- Os imediatos de desvio e salto estão em unidades de instrução (ver [Formatos de instrução](#formatos-base-rv32i)); código gerado por um montador RISC-V padrão salta o dobro da distância.

**Hazards e forwarding**
- Durante um stall, `bubble = 1` **congela** o ID/EX em vez de inserir uma NOP. Com isso, o `lw` permanece em ID/EX e a condição de stall continua verdadeira no ciclo seguinte.
- Nos circuitos Logisim, a entrada `id_ex_mem_r` da hazard unit aparenta estar ligada à saída `mem_w_out` do ID/EX (e não a `mem_r_out`), de modo que o stall seria disparado por `sw` em vez de `lw`.
- O alvo de `jalr` usa `EX/MEM.reg_a`, que recebe `rs1` **sem** forwarding.
- O dado de `sw` só recebe forwarding de EX/MEM (`forward_c`); uma dependência de distância 2 (MEM/WB → store) usa o valor antigo do registrador.

**Extensão vetorial**
- O `imm_gen` não decodifica os opcodes `1110011`, `0011011` e `0111011` (cai no caso `others`, imediato `X`), então `vaddi`, `vslli` e `vsrli` não recebem um imediato válido.
- Na `alu_ctrl`, o teste de `funct3 = "100"` (xor) vem antes do de `vsrl`, então `vsrl` é decodificado como xor e a ALU SIMD devolve `Z`.
- `vsub` com `vec = 000` tem `funct7 = 0000000` e é decodificado como `vadd`; `vslli`/`vsrli` com `vec = 000` caem no caso de `addi`, e `vsrli` com `vec = 001` cai no caso de `sll`.
- Na `alu_simd`, o sinal `carrys` é compartilhado pelos quatro arranjos de somadores (`ints_8`, `ints_4`, `ints_2`, `ints_1`), que dirigem os mesmos bits simultaneamente; o código mantém o comentário `to do: corrigir lógica` nesse trecho.

---

## Referências

- [docs/riscv-spec-v2.2.pdf](docs/riscv-spec-v2.2.pdf) — *The RISC-V Instruction Set Manual, Volume I: User-Level ISA*, v2.2.
- [docs/riscv-user-isa.pdf](docs/riscv-user-isa.pdf) — RISC-V User-Level ISA.
- [docs/doc_instruções_vetoriais](docs/doc_instruções_vetoriais) — codificação das instruções vetoriais deste projeto.
- D. A. Patterson e J. L. Hennessy, *Computer Organization and Design RISC-V Edition* — organização do pipeline, forwarding e hazard detection.
