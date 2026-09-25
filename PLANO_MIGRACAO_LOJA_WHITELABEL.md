# Plano de migração: de "Biblioteca Guiar" para loja de livros white-label (venda e/ou empréstimo)

> Documento de planejamento. Nenhum código do projeto original foi alterado.
> Destino: um **fork local** deste repositório. O projeto `biblioteca_guiar` continua como está.
> Base da análise: código em `lib/` (44 arquivos Dart, ~5.900 linhas), configs de plataforma e os dois snippets `.js` da raiz. A análise começou no commit `3b481e1`; o zip foi gerado no `d79ca14`. Entre os dois, `lib/`, `test/` e `integration_test/` **não mudaram**.
>
> ⚠️ **Leia a seção 0 antes de qualquer coisa: o repositório está com conflitos de merge não resolvidos e não compila no estado atual.**

---

## 0. Estado do repositório no momento do zip (corrigir primeiro)

O commit `d79ca14` ("Resolved merge conflicts") gravou os marcadores `<<<<<<<` / `=======` / `>>>>>>>` dentro de 5 arquivos. Com isso o `pubspec.yaml` é YAML inválido e `flutter pub get` falha. O zip contém esse estado, porque o projeto original não foi alterado.

| Arquivo | Conflito | Resolução recomendada |
|---|---|---|
| `pubspec.yaml` | `version: 1.0.1+2` × `1.0.2+2` | ficar com `1.0.2+2` (lado mais novo, `e6fb102`) |
| `pubspec.lock` | 6 blocos | **apagar o arquivo** e rodar `flutter pub get` para regenerar |
| `android/settings.gradle.kts` | Android Gradle Plugin `8.7.3` × `8.9.1` | `8.9.1`, coerente com `compileSdk = 36`/`targetSdk = 36` do mesmo commit |
| `android/gradle.properties` | com × sem as flags do migrador do Flutter | ficar com o bloco de baixo (inclui `android.builtInKotlin=false` e `android.newDsl=false`) |
| `.gitignore` | bloco novo (`.omc`, `.agents`, `.vscode`, `antigravity.config.json`) | ficar com o bloco novo, removendo só os marcadores |

Detalhe do `.gitignore`: o bloco novo ignora `.agents/`, `.vscode/` e `antigravity.config.json`, mas esses caminhos **já estão versionados** (commit `bc5defe`), então a regra não tem efeito sobre eles. No fork, decidir: ou remove do índice (`git rm -r --cached .agents .vscode antigravity.config.json`), ou tira as linhas do `.gitignore`.

Para conferir que não sobrou nada: `git grep -nE "^(<<<<<<<|=======|>>>>>>>)"` deve voltar vazio. **O mesmo conserto vale para o repositório original.**

Os dois scripts novos da raiz (`build_aab_obfuscated.sh`, `run_on_device.sh`) são úteis no fork, mas precisarão receber a marca como parâmetro (`--flavor` + `--dart-define-from-file`) a partir da Fase 1.

---

## 1. Resumo executivo

O app atual é um sistema de **empréstimo** de livros de uma única instituição (Igreja Metodista de Palmas), com marca, cores, igreja e textos fixos no código. O objetivo do fork é virar um **produto white-label de livraria**, em que cada cliente (lojista, igreja, escola, sebo) recebe um app com a própria marca e escolhe o **modo de operação**:

| Modo | O que o usuário final faz | O que o admin faz |
|---|---|---|
| `emprestimo` | reserva, retira, renova, devolve (fluxo atual) | efetiva, renova, recebe devolução |
| `venda` | coloca no carrinho, fecha pedido, paga, retira/recebe | confirma pagamento, separa, entrega |
| `ambos` | cada livro diz se pode ser vendido, emprestado ou os dois | as duas filas de trabalho |

A boa notícia: **cerca de 70% do app é reaproveitável sem mudança de conceito** (autenticação, cadastro em duas etapas, perfil, catálogo, cadastro de livro com OCR, chat de atendimento, gestão de usuários, papéis, tema claro/escuro, exclusão de conta, notificações). O fluxo de venda pode nascer como um **espelho do fluxo de empréstimo** que já existe:

```
Empréstimo (hoje):  reservado ──► ativo ──► devolvido
Venda (MVP):        aguardando_pagamento ──► pago ──► pronto_retirada ──► concluido
```

As três frentes de trabalho reais são:

1. **White-label**: tirar tudo que é "Guiar/Metodista/verde" do código e colocar em configuração (build + runtime).
2. **Modo de operação**: isolar o que é empréstimo em um módulo, criar o módulo de venda ao lado, e ligar/desligar por configuração.
3. **Backend de verdade**: hoje não há servidor nem regras de segurança no repositório. Para empréstimo isso é tolerável; **para venda não é** (preço, estoque e pagamento não podem ser decididos pelo app do cliente).

---

## 2. Diagnóstico do que existe hoje

### 2.1 Funcionalidades e destino de cada uma

| Funcionalidade atual | Onde está | Destino no fork |
|---|---|---|
| Login, recuperar senha, trocar senha | `screens/auth`, `screens/profile`, `AuthService` | **Mantém.** Só troca marca/logo. |
| Cadastro em 2 etapas com CPF único e rollback | `RegisterScreen` → `CompleteProfileScreen`, `UserProvider.completeRegistration` | **Mantém**, com ajustes: igreja fixa sai; CPF passa a ser configurável (obrigatório/opcional por marca); validação de unicidade vai para o servidor (ver 6.3). |
| Estado/cidade via API do IBGE | `CompleteProfileScreen._fetchCities` | **Mantém.** Acrescentar endereço estruturado + CEP (ViaCEP) para entrega. |
| Catálogo em grade com busca | `HomeScreen` | **Mantém e amplia**: preço, selo de promoção, filtro por categoria, ícone de carrinho. |
| Detalhe do livro + "RESERVAR LIVRO" | `BookDetailScreen` | **Bifurca por modo**: botões de reserva (empréstimo) e/ou "Adicionar ao carrinho"/"Comprar" (venda). |
| "Reservar para leitor" (admin escolhe o usuário) | `BookDetailScreen` | **Mantém no empréstimo**; na venda vira **"Venda no balcão"** (admin cria pedido para um cliente). |
| Cadastro/edição de livro com foto e OCR | `AddEditBookScreen`, `OcrHelper` | **Mantém e amplia**: preço, estoque de venda, SKU, flags por modo, peso/dimensões. |
| Soft delete de livro com histórico | `BookProvider.deleteBook` | **Mantém**; passa a considerar também pedidos. |
| "Minha Estante" (empréstimos do usuário, semáforo de status) | `MyLoansScreen` | **Mantém no modo empréstimo.** Criar irmã **"Meus Pedidos"**. |
| "Gerenciar Empréstimos" (efetivar, renovar, devolver) | `ManageLoansScreen`, `LoanDurationDialog` | **Mantém no modo empréstimo.** Criar irmã **"Gerenciar Pedidos"**. |
| Dashboard (totais, pizza de status, top categorias) | `DashboardProvider`, `widgets/dashboard` | **Bifurca**: KPIs de empréstimo × KPIs de venda (faturamento, ticket médio, pedidos por status, mais vendidos, estoque baixo). |
| Chat usuário ↔ admin com caixa de entrada e atendente | `ChatProvider`, `ChatScreen`, `AdminInboxScreen` | **Mantém.** Opcional: vincular conversa a um pedido. |
| Gestão de usuários e dossiê | `UsersListScreen`/`UserDetailScreen` e `AdminUsersListScreen`/`UserDetailDossierScreen` | **Unificar** (hoje há duas versões). Dossiê mostra empréstimos e/ou pedidos. |
| Papéis `SUPER_ADMIN`/`ADMIN`/`HELPER`/`USER` | `UserModel` | **Mantém**, com novo significado (ver 4.4). |
| Hierarquia Estado → Cidade → Igreja (mock) | `super_admin_flow.dart` | **Generalizar** para "unidades/filiais" ou remover do MVP (ver 4.5). |
| Desativar conta / excluir conta com feedback | `DeleteAccountDialog`, `UserProvider` | **Mantém**, mas com pedidos a exclusão vira **anonimização** (ver 9). |
| Tema claro/escuro persistido | `ThemeProvider` | **Mantém**, cores passam a vir da marca. |
| Push (FCM) em primeiro plano | `NotificationService` | **Completar**: hoje o token nunca é salvo e nada envia push. Venda precisa ("pedido pago", "pronto para retirada"). |

### 2.2 O que está fixo no código e impede o white-label

Levantamento por busca no repositório:

- **Nome/identidade**: 86 ocorrências de "Biblioteca Guiar / biblioteca_guiar / Metodista / Igreja" em 30 arquivos.
  - Dart: título do `MaterialApp` (`main.dart`), AppBar da `HomeScreen`, `LoginScreen`, `CompleteProfileScreen` (UF `TO`, cidade `Palmas`, igreja `metodista_palmas` como constantes), `super_admin_flow.dart` (mapa mock).
  - Android: `applicationId` e `namespace` = `br.com.i9android.biblioteca_guiar`, pasta Kotlin `br/com/i9android/biblioteca_guiar/`, `android:label` no manifest.
  - iOS/macOS: `Info.plist`, `project.pbxproj`, `AppInfo.xcconfig`. Web: `index.html`, `manifest.json`. Windows/Linux: `CMakeLists.txt`, `Runner.rc`, `main.cpp`, `my_application.cc`.
  - Loja: `play_store_assets/textos/*`, `assets/icon/app_icon.png`.
- **Cor**: `ThemeProvider` fixa `Colors.green`/`greenAccent` (12 ocorrências) e há mais 14 `Colors.green` espalhados em 11 telas/widgets. Atenção: parte desses verdes é **semântica** ("em dia", "sucesso") e deve continuar verde; só os que significam "cor da marca" (FAB "Fale Conosco", botões) devem virar `colorScheme.primary`.
- **Vocabulário**: "Biblioteca", "Leitor", "Minha Estante", "Empréstimo", "retirada na biblioteca" estão em literais dentro das telas. Não há arquivo de strings nem l10n.
- **Firebase**: um único projeto, com `firebase_options.dart` e `google-services.json` fora do git.

### 2.3 Dívidas técnicas que ficam mais caras depois (resolver na Fase 0/1)

1. **Camadas furadas.** `ChatProvider` e `DashboardProvider` acessam o Firestore direto; `UserProvider` mistura service com chamadas diretas a Auth/Firestore/Storage; telas instanciam `FirestoreService()`. Para ter dois módulos (venda/empréstimo) é preciso um padrão único de acesso a dados.
2. **Testes quebrados.** `test/widget_test.dart` é o template do contador; `test/widget_tests.dart` não roda em `flutter test` (nome não termina em `_test.dart`) e os mocks estão desatualizados (`isAdmin:` no construtor, assinaturas antigas de `activateLoan`/`renewLoan`, cadastro de etapa única); a dependência `integration_test` está comentada e o teste usa login fixo contra o Firebase real.
3. **Duplicidades.** Duas telas de lista de usuários e duas de detalhe; `AuthService.signUp` (fluxo antigo) convive com o cadastro em duas etapas; `LoanProvider.fetchUserLoans(uid)` ignora o `uid`.
4. **Papéis em duplicidade.** `role` convive com os booleanos legados `isAdmin`/`isHelper`, que ainda são gravados e consultados (`getHelpers`). Como o fork nasce com banco novo, é a hora de **eliminar os booleanos**.
5. **Caminhos de Storage inconsistentes.** O cadastro grava foto em `user_photos/{uid}/profile.jpg`; a edição grava em `user_profiles/{uid}/profile.jpg`; `deleteUserPhoto` aponta para a pasta, não para o arquivo.
6. **`print` em todo lugar**, inclusive com e-mail do usuário no login. Trocar por logger com níveis e sem dados pessoais.
7. **Infra fora do repositório.** Regras do Firestore/Storage e índices compostos vivem só no console do Firebase. Não existe `firebase.json`, `firestore.rules`, `firestore.indexes.json` nem pasta `functions/`.
8. **`pubspec.yaml`**: `firebase_messaging` e `flutter_local_notifications` sem versão; `dependency_overrides` de `vector_math`; configuração do `flutter_launcher_icons` duplicada (no pubspec e em arquivo próprio, com valores diferentes).

### 2.4 Riscos de segurança que a venda transforma em bloqueadores

| Risco hoje | Por que piora com venda |
|---|---|
| Controle de papel só na interface (drawer/botões). Não dá para confirmar no repositório o que as regras do Firestore impõem. | Um usuário comum não pode alterar preço, marcar pedido como pago ou ler pedidos de terceiros. |
| Estoque é decrementado **pelo app** (`activateLoan` faz `increment(-1)` em batch; `returnBook` em transação do cliente). | Na venda, estoque e total do pedido têm que ser calculados **no servidor**. |
| `role` é gravado pelo cliente no cadastro (`toMap()` inclui `role`). Se as regras permitirem, o usuário se autopromove. | Vira fraude financeira, não só bagunça administrativa. |
| Unicidade de CPF é checada por `where('cpf')` no cliente, o que exige que qualquer usuário autenticado consiga consultar a coleção `users`. "Reservar para leitor" baixa **todos** os usuários. | Exposição de CPF/telefone/endereço (LGPD) numa base que agora terá dados de compra. |
| O limite "uma reserva ativa" só aparece como `permission-denied` tratado no app; a regra em si está no console. | O fork precisa dessas regras versionadas e testadas. |

**Ação obrigatória antes de começar:** exportar do console do Firebase as regras do Firestore, as regras do Storage e a lista de índices compostos do projeto atual, e guardá-las no fork como ponto de partida.

---

## 3. Arquitetura-alvo do white-label

### 3.1 Dois níveis de configuração

| Nível | O que define | Quando muda | Onde fica |
|---|---|---|---|
| **Build (por marca)** | `applicationId`/bundle id, nome do app, ícone, splash, projeto Firebase, modo padrão, textos da loja | A cada novo cliente; exige publicar um app | Pasta `brands/<marca>/` + flavors |
| **Runtime (por marca, editável)** | cores, logo, modo de operação, recursos ligados, regras de negócio (prazo de empréstimo, prazo para pagar, taxa de entrega), contatos, textos legais | Quando o lojista quiser, sem nova versão | Documento `config/app` no Firestore, com cache local |

O app sobe lendo a configuração de build (sempre disponível, funciona offline) e depois aplica por cima a de runtime.

### 3.2 Isolamento entre clientes: decisão recomendada

**Recomendação: um projeto Firebase por cliente (marca).**

| Critério | Um projeto por cliente (recomendado) | Um projeto só, multi-tenant por `tenantId` |
|---|---|---|
| Vazamento entre clientes | impossível por construção | depende de toda regra e toda query estarem certas |
| Regras de segurança | as mesmas para todos, simples | todas precisam checar `tenantId` |
| Custo/cobrança | fatura separada por cliente, fácil de repassar | fatura única, rateio manual |
| LGPD / saída do cliente | entrega ou apaga o projeto inteiro | exportação seletiva trabalhosa |
| Push, Auth, e-mails de senha | com a identidade do cliente | compartilhados |
| Esforço de onboarding | maior (criar projeto, deploy) — **automatizável por script** | menor |
| Painel consolidado do dono da plataforma | precisa agregar | trivial |

O `churchId` que já existe **não** é o tenant; ele vira a **unidade/filial dentro de um cliente** (ver 4.5).

### 3.3 Estrutura de pastas proposta

```
brands/
  _template/                 # copiar para criar um novo cliente
  guiar/                     # a marca original, como primeiro "cliente" e caso de teste
    brand.json               # nome, cores semente, modo padrão, flags padrão, contatos
    icon.png  splash.png  logo.png
    firebase/                # google-services.json, GoogleService-Info.plist, firebase_options
    store/                   # título, descrição curta/longa, screenshots
lib/
  core/
    config/                  # BrandConfig (build), AppConfig (runtime), OperationMode, FeatureFlags
    theme/                   # ThemeProvider a partir de ColorScheme.fromSeed(brand)
    l10n/ ou terms/          # vocabulário por modo (ver 3.5)
    auth/  users/  chat/  notifications/  storage/
  features/
    catalog/                 # livros: comum aos dois modos
    lending/                 # tudo que hoje é loans/*  (LoanModel, LoanProvider, telas, diálogo)
    sales/                   # carrinho, checkout, pedidos, gestão de pedidos
    dashboard/               # cartões por modo
    admin/
firebase/
  firestore.rules  firestore.indexes.json  storage.rules  firebase.json
  functions/                 # Cloud Functions (TypeScript)
tool/
  new_brand.ps1              # cria pasta da marca, flavor, ícones
  deploy_brand.ps1           # rules + indexes + functions no projeto da marca
```

A reorganização em `features/` pode ser gradual; o essencial é que **nada em `lending/` seja importado por `sales/` e vice-versa**. O que os dois usam vai para `catalog/` ou `core/`.

### 3.4 Flavors e build

- **Android**: `productFlavors` em `android/app/build.gradle.kts`, um por marca, com `applicationId`, `resValue("string","app_name",…)` e `google-services.json` em `android/app/src/<marca>/`. A assinatura já lê de `local.properties`; passar a ler por flavor (cada cliente pode ter a própria conta na Play Store e a própria keystore).
- **iOS**: um scheme + xcconfig por marca, com bundle id e `GoogleService-Info.plist` próprios.
- **Dart**: `--dart-define-from-file=brands/<marca>/brand.json` e um `main.dart` único. `firebase_options` selecionado por marca.
- **Ícones/splash**: `flutter_launcher_icons` aceita um arquivo por flavor (`flutter_launcher_icons-<marca>.yaml`). Adotar `flutter_native_splash` do mesmo jeito.
- **Pacote Dart**: renomear `biblioteca_guiar` para um nome neutro (ex.: `livraria_core`). É barato: `lib/` só usa imports relativos; apenas `test/` e `integration_test/` usam `package:biblioteca_guiar/…`.
- **Plataformas**: o repositório tem pastas de web/windows/linux/macos, mas o app depende de câmera, ML Kit e FCM. Recomendo **declarar Android + iOS como alvo** e remover as demais do fork para reduzir superfície de rebranding. (Um painel web para o lojista é um projeto futuro à parte.)

Comando-alvo: `flutter run --flavor guiar --dart-define-from-file=brands/guiar/brand.json`

### 3.5 Vocabulário por modo

Criar uma fonte única de textos (recomendo `flutter_localizations` + ARB, o que também deixa o produto pronto para outros idiomas; alternativa mínima: uma classe `Terms`). Termos que mudam com o modo/marca:

| Conceito | Empréstimo | Venda |
|---|---|---|
| Estabelecimento | Biblioteca | Loja / Livraria |
| Usuário final | Leitor | Cliente |
| Lista pessoal | Minha Estante | Meus Pedidos |
| Ação principal | Reservar livro | Adicionar ao carrinho / Comprar |
| Fila do admin | Gerenciar Empréstimos | Gerenciar Pedidos |
| Aguardando | Aguardando retirada na biblioteca | Aguardando pagamento / Pronto para retirada |

### 3.6 Documento de configuração em runtime (`config/app`)

```jsonc
{
  "operationMode": "venda",            // "venda" | "emprestimo" | "ambos"
  "brand": { "displayName": "...", "primaryColor": "#1B5E20", "logoUrl": "...", "whatsapp": "...", "email": "..." },
  "features": {
    "chat": true, "ocr": true, "coupons": false, "delivery": false,
    "pickup": true, "onlinePayment": false, "payOnPickup": true, "units": false
  },
  "signup": { "requireCpf": true, "requireAddress": false, "askUnit": false },
  "lending": { "defaultDays": 7, "maxActiveReservations": 1, "maxRenewals": 2 },
  "sales":   { "paymentTimeoutMinutes": 30, "pickupHoldDays": 5, "deliveryFlatFee": 0, "lowStockThreshold": 2 },
  "legal":   { "termsUrl": "...", "privacyUrl": "...", "returnPolicyUrl": "..." }
}
```

Somente `ADMIN`/`SUPER_ADMIN` escrevem (garantido por regra). Um `AppConfigProvider` expõe `isSalesEnabled`, `isLendingEnabled` e as flags; drawer, rotas, detalhe do livro e dashboard consultam esse provider em vez de decidir sozinhos. Os valores hoje fixos no código (7 dias de empréstimo em `BookDetailScreen`, por exemplo) passam a vir daqui.

---

## 4. Modelo de dados

### 4.1 `books` (ampliado)

| Campo | Situação | Observação |
|---|---|---|
| `titulo`, `autor`, `isbn`, `categoria`, `sinopse`, `imageUrl`, `isActive` | já existe | sem mudança |
| `quantidadeDisponivel` | já existe | passa a significar **exemplares para empréstimo** |
| `disponivelEmprestimo` (bool) | novo | usado no modo `ambos` |
| `disponivelVenda` (bool) | novo | usado no modo `ambos` |
| `preco` (int, **centavos**) | novo | nunca `double` para dinheiro |
| `precoPromocional` (int, centavos, opcional) | novo | |
| `estoqueVenda` (int) | novo | **separado** do acervo de empréstimo |
| `sku`, `editora`, `anoPublicacao`, `paginas`, `idioma`, `condicao` (novo/usado) | novo | `condicao` interessa a sebos |
| `pesoGramas`, `dimensoesCm` | novo | só quando houver entrega com frete calculado |
| `destaque` (bool), `criadoEm`, `atualizadoEm` | novo | vitrine e ordenação |
| `unitId` | novo, opcional | só se `features.units` |

**Decisão: estoque separado.** Um exemplar do acervo de empréstimo não é mercadoria; misturar os dois números gera venda de livro que está emprestado. No modo `ambos`, o mesmo título pode ter `quantidadeDisponivel: 2` e `estoqueVenda: 10`.

Observação de escala: hoje `getBooks()` assina a coleção **inteira** e filtra `isActive` e a busca no cliente. Funciona com centenas de títulos; uma livraria pode ter milhares. Planejar paginação e filtro no servidor (`where isActive`, `where categoria`, `orderBy`) e, se a busca textual for importante, um índice externo (Algolia/Typesense) ou campo de palavras-chave.

### 4.2 Coleções novas para venda

**`orders/{orderId}`**

```jsonc
{
  "numero": 1042,                        // sequencial legível, gerado no servidor
  "userId": "...", "userName": "...", "userCpf": "...",   // cópia no momento da compra
  "items": [ { "bookId": "...", "titulo": "...", "imageUrl": "...", "precoUnitario": 4990, "quantidade": 1 } ],
  "subtotal": 4990, "desconto": 0, "frete": 0, "total": 4990,     // centavos, calculado no servidor
  "cupom": null,
  "status": "aguardando_pagamento",
  "pagamento": { "metodo": "pix|cartao|na_retirada", "gateway": "...", "gatewayId": "...", "pagoEm": null },
  "entrega": { "tipo": "retirada|entrega", "endereco": { ... }, "rastreio": null },
  "canal": "app|balcao", "criadoPor": "uid",          // balcão = admin vendeu para o cliente
  "unitId": null,
  "criadoEm": "...", "atualizadoEm": "...", "expiraEm": "...",
  "historico": [ { "status": "...", "em": "...", "por": "uid" } ]
}
```

Os itens guardam **cópia** de título e preço, do mesmo jeito que `loans` já guarda `bookTitle` e `userName`: o pedido não pode mudar se o livro for editado depois.

- **`users/{uid}/addresses/{id}`**: endereços de entrega (CEP, logradouro, número, complemento, bairro, cidade, UF). O campo livre `endereco` de hoje continua como está para não quebrar o cadastro.
- **`carts/{uid}`** (opcional): carrinho persistido entre aparelhos. No MVP o carrinho pode ser só local (`shared_preferences`, já é dependência).
- **`coupons/{codigo}`** (fase posterior): tipo, valor, validade, limite de uso.
- **`stock_movements/{id}`**: trilha de auditoria (entrada, venda, cancelamento, ajuste manual) escrita só pelo servidor.
- **`payment_events/{id}`**: notificações brutas do gateway, para idempotência e conciliação.
- **`counters/orders`**: numeração sequencial.
- **`config/app`**: seção 3.6.

### 4.3 Máquina de estados do pedido

```
                       ┌────────────► cancelado  (expirou, cliente desistiu, admin cancelou → devolve estoque)
aguardando_pagamento ──┤
                       └─► pago ─► em_separacao ─┬─► pronto_retirada ─► concluido
                                                 └─► enviado ─────────► entregue ─► concluido
                                                                  qualquer estado pago ─► reembolsado
```

Paralelo direto com o que já existe, o que permite reaproveitar layout e lógica das telas:

| Empréstimo | Venda | Tela do usuário | Tela do admin |
|---|---|---|---|
| `reservado` (amarelo, "aguardando retirada") | `aguardando_pagamento` / `pronto_retirada` | cartão com borda amarela | botão de ação principal ("EFETIVAR" ↔ "CONFIRMAR PAGAMENTO"/"ENTREGAR") |
| `ativo` (verde/vermelho conforme prazo) | `pago` / `em_separacao` / `enviado` | borda verde | ações secundárias |
| `devolvido` (cinza, histórico) | `concluido` / `cancelado` | borda cinza | some da fila |

**Reserva de estoque**: ao criar o pedido o servidor **reserva** o estoque (decrementa `estoqueVenda`). Se o pagamento não chega até `expiraEm`, uma função agendada cancela e devolve. Isso evita vender o último exemplar duas vezes.

### 4.4 Papéis no contexto de loja

| Papel | Empréstimo (hoje) | Venda |
|---|---|---|
| `SUPER_ADMIN` | dono da plataforma | **você** (operador do white-label): configura marca, modo, unidades |
| `ADMIN` | responsável pela biblioteca | **lojista**: catálogo, preços, pedidos, relatórios, configuração |
| `HELPER` | ajudante: só gerencia empréstimos | **atendente/vendedor**: fila de pedidos, venda no balcão, chat; **não** altera preço nem vê faturamento |
| `USER` | leitor | cliente |

Mover o papel para **custom claims** do Firebase Auth (definidas por Cloud Function) e usar o campo `role` do documento só como espelho para exibição. As regras passam a checar `request.auth.token.role`, sem leitura extra de documento.

### 4.5 Igrejas → unidades

O trabalho em andamento de Estado → Cidade → Igreja generaliza para **unidades/filiais de um mesmo cliente** (uma rede de livrarias, uma denominação com várias igrejas):

- renomear `churchId` → `unitId`, coleção `churches` → `units`, e usar dados reais no lugar do `mockLocationData`;
- `cloud_functions_code.js` já traz o CRUD protegido por `SUPER_ADMIN`; serve de base para `units`;
- ligar por `features.units`. Com a flag desligada (caso comum de loja única) nada disso aparece e o cadastro não pergunta unidade.

**Recomendação: deixar unidades fora do MVP de venda.** É ortogonal e multiplica as regras (estoque por unidade, pedidos por unidade, admin por unidade).

---

## 5. Telas: o que muda

### 5.1 Alterações em telas existentes

| Tela | Mudança |
|---|---|
| `main.dart` | Carregar `BrandConfig` + `AppConfig` antes do `runApp`; título e tema vindos da marca; rotas de `lending/` e `sales/` registradas conforme o modo; tratar a janela em que `userModel` ainda é nulo após login. |
| `AppDrawer` | Itens montados a partir de `AppConfig` + papel. "Meus Empréstimos"/"Gerenciar Empréstimos" só com empréstimo ligado; "Meus Pedidos"/"Gerenciar Pedidos"/"Carrinho" só com venda ligada. |
| `HomeScreen` | Título da marca; preço e selo no cartão; "Disponível/Indisponível" calculado pelo estoque do modo ativo; filtro de categorias; ícone de carrinho com contador; FAB do chat com a cor da marca. |
| `BookDetailScreen` | Bloco de ações por modo (hoje são ~140 linhas de botões inline; extrair para `LendingActions` e `SalesActions`). Mostrar preço/promoção. Prazo padrão vem de `config.lending.defaultDays`. "Reservar para leitor" deixa de baixar todos os usuários: busca paginada por nome/CPF. |
| `AddEditBookScreen` | Campos de preço (máscara em reais, grava centavos), estoque de venda, SKU, flags "pode vender/pode emprestar" (visíveis só no modo `ambos`). Sugestão de valor: preencher dados pelo ISBN (Google Books/Open Library) além do OCR. |
| `DashboardScreen`/`DashboardProvider` | Cartões e gráficos por modo. Vendas: faturamento do período, ticket médio, pedidos por status, top 5 mais vendidos, estoque baixo. Os totais devem vir de **agregados mantidos pelo servidor**; hoje o provider baixa todos os empréstimos e todos os livros a cada abertura. |
| `CompleteProfileScreen` | Remover constantes `TO`/`Palmas`/`metodista_palmas`; campos exigidos conforme `config.signup`; unidade só se `features.units`. |
| `UserDetail*` | Unificar as duas versões; abas "Empréstimos" e "Pedidos" conforme o modo. |
| `ChatScreen`/`AdminInboxScreen` | Sem mudança estrutural. Opcional: atalho "Falar sobre este pedido". |
| `SettingsScreen` | Acrescentar "Meus endereços" e links legais (termos, privacidade, trocas e devoluções). |
| `DeleteAccountDialog` | Texto e fluxo ajustados para anonimização quando houver pedidos (seção 9). |

### 5.2 Telas novas (módulo `sales/`)

1. **Carrinho**: itens, quantidade (limitada ao estoque), subtotal.
2. **Checkout**: retirada × entrega, endereço, forma de pagamento, cupom, resumo, aceite dos termos.
3. **Pagamento**: Pix (QR + copia-e-cola, aguardando confirmação em tempo real) e/ou cartão; ou "pagar na retirada".
4. **Meus Pedidos** + **Detalhe do pedido** (linha do tempo de status, cancelar enquanto permitido, falar com a loja).
5. **Gerenciar Pedidos** (admin/atendente): abas por status, ações de avançar estado, cancelar/reembolsar com motivo.
6. **Venda no balcão** (admin/atendente): escolher cliente, itens, registrar pagamento presencial.
7. **Configuração da loja** (admin): edita `config/app` — modo de operação, cores, logo, regras, contatos.
8. **Endereços** (usuário).
9. Fase posterior: **Cupons**, **Ajuste de estoque**, **Relatório de vendas** (exportar CSV).

### 5.3 Módulo `lending/` (o que é movido, sem reescrever)

`LoanModel`, `LoanProvider`, `MyLoansScreen`, `ManageLoansScreen`, `LoanDurationDialog`, `loan_status_pie_chart.dart` e os métodos `reserveBook`/`activateLoan`/`returnBook`/`renewLoan`/`getUserLoans`/`getAllLoans`/`getLoansByUserId`/`checkBookHasLoans` do `FirestoreService` (extrair para `LoanRepository`). Melhorias pendentes que valem ser feitas junto: `LoanModel` não mapeia `renovationsCount`; não há limite de renovações; não há aviso de atraso (nem push nem e-mail).

---

## 6. Backend (hoje inexistente no repositório)

### 6.1 Entregáveis

- `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `storage.rules` versionados e com deploy por script para cada marca.
- `functions/` em TypeScript, testadas com o **Firebase Emulator Suite** (que também destrava os testes de integração do app sem tocar em produção).

### 6.2 Cloud Functions necessárias

| Função | Tipo | Responsabilidade |
|---|---|---|
| `createOrder` | callable | Recebe `{itens: [{bookId, quantidade}], entrega, cupom}`. **Lê os preços no servidor**, valida estoque, reserva estoque e cria o pedido em **uma transação**. Nunca aceita preço/total vindos do app. |
| `cancelOrder` | callable | Valida quem pode cancelar e em que estado; devolve estoque. |
| `advanceOrderStatus` | callable | Transições permitidas por papel; grava `historico`. |
| `createPayment` / `paymentWebhook` | callable / HTTP | Cria cobrança no gateway; webhook com verificação de assinatura e **idempotência** (`payment_events`) marca `pago`. |
| `expireUnpaidOrders` | agendada | Cancela pedidos vencidos e devolve estoque. |
| `onOrderStatusChange` | gatilho Firestore | Push para o cliente; push para admins em pedido novo. |
| `onChatMessage` | gatilho Firestore | Push de nova mensagem (hoje o chat não notifica ninguém). |
| `setUserRole` | callable (`ADMIN`+) | Define custom claim; impede autopromoção. |
| `completeRegistration` | callable | Valida CPF e garante unicidade via documento-índice `cpf_index/{cpf}`, sem exigir leitura aberta de `users`. |
| `activateLoan` / `returnLoan` | callable | Mover para o servidor o que hoje o app faz em batch/transação, e impor `maxActiveReservations`/`maxRenewals`. |
| `overdueLoanReminder` | agendada | Lembrete de devolução (lacuna atual). |
| `dashboardAggregates` | gatilho/agendada | Mantém `stats/daily/{data}` para o dashboard não varrer coleções. |
| `units*` | HTTP/callable | Base já escrita em `cloud_functions_code.js`. |

`backend_logic_snippet.js` (auto-atribuição de tickets ao atendente menos ocupado) descreve uma coleção `tickets` que o app não usa; o chat usa `chats` com atribuição manual. Decidir se a auto-atribuição é portada para `chats` ou descartada.

### 6.3 Diretrizes das regras de segurança

- `books`: leitura para autenticados (ou pública, se a marca quiser vitrine sem login); escrita só `ADMIN`. **`estoqueVenda` e `quantidadeDisponivel` não são graváveis pelo cliente.**
- `orders`: leitura pelo dono, `HELPER` e `ADMIN`; **criação e mudança de estado apenas via Functions** (`allow write: if false` para clientes).
- `users`: cada um lê/escreve o próprio documento, **exceto** `role`, `isActive` e `unitId`; listagem só para `ADMIN`/`HELPER`.
- `loans`: mesma lógica de `orders`.
- `chats`: dono do chat + equipe.
- `config`: leitura para todos os autenticados; escrita `ADMIN`.
- `stock_movements`, `payment_events`, `counters`, `stats`: somente servidor.
- Testes de regras com `@firebase/rules-unit-testing` rodando no CI.

### 6.4 Pagamento

- **Livro físico é bem físico**: as políticas da Google Play e da App Store **não exigem** (e não permitem) o sistema de cobrança das lojas para isso; usa-se gateway externo. **E-book/conteúdo digital é o oposto** e cairia na cobrança in-app com as comissões das lojas — por isso **e-books ficam fora do escopo**.
- Gateways a avaliar para o Brasil com Pix + cartão: Mercado Pago, Asaas, Pagar.me, Stripe. Critérios: taxa do Pix, split (útil se você quiser cobrar comissão da plataforma automaticamente), qualidade do webhook, SDK/checkout pronto. A escolha deve ficar atrás de uma interface `PaymentGateway` nas Functions para permitir gateway diferente por cliente.
- As **credenciais do gateway são do lojista** e ficam no Secret Manager do projeto Firebase dele, nunca no app.
- Dados de cartão **nunca** passam pelo app nem pelo Firestore: usar checkout hospedado/tokenização do gateway (mantém o projeto fora do escopo pesado do PCI-DSS).

### 6.5 Entrega

1. MVP: **retirada na loja** (é o mesmo gesto da "retirada na biblioteca").
2. Depois: entrega local com taxa fixa configurável.
3. Depois: frete calculado (Melhor Envio/Correios) — exige peso e dimensões no cadastro do livro e CEP do cliente (ViaCEP).

---

## 7. Roteiro por fases

Tamanho relativo: **P** (dias), **M** (1–2 semanas), **G** (3+ semanas), para uma pessoa.

### Fase 0 — Preparar o fork (P)
- **Resolver os conflitos de merge da seção 0** (sem isso nada compila).
- Descompactar, `git remote` novo, renomear o pacote Dart para nome neutro.
- **Criar um projeto Firebase novo de desenvolvimento** e gerar `firebase_options`/`google-services.json` próprios. *Os arquivos que vieram no zip apontam para o banco de produção da Biblioteca Guiar.*
- Exportar regras e índices do console atual para `firebase/`.
- Configurar Emulator Suite.
- Consertar a suíte: apagar o teste-template, renomear `widget_tests.dart` → `*_test.dart`, atualizar mocks, reativar `integration_test` contra o emulador.
- Fixar versões no `pubspec.yaml`; remover plataformas que não serão alvo.
- **Pronto quando:** `flutter analyze` e `flutter test` passam; o app roda contra o emulador.

### Fase 1 — Fundação white-label (M)
- `BrandConfig` + `brands/guiar/` como primeira marca; flavors Android/iOS; ícone e splash por flavor.
- `ThemeProvider` com `ColorScheme.fromSeed`; trocar os `Colors.green` de marca por `colorScheme.primary` (manter os semânticos).
- Centralizar strings (ARB) e remover toda menção a Guiar/Metodista/Palmas do Dart.
- Criar uma **segunda marca fictícia** (`brands/demo_livraria/`) para provar o conceito.
- **Pronto quando:** dois apps com nome, ícone, cor e Firebase diferentes saem do mesmo código com um comando cada.

### Fase 2 — Modo de operação e modularização (M)
- `config/app`, `AppConfigProvider`, `OperationMode`, flags.
- Mover empréstimo para `features/lending/`; drawer/rotas/detalhe/dashboard obedecendo ao modo.
- Padronizar acesso a dados (repositórios); unificar telas de usuários; remover `AuthService.signUp` antigo e os booleanos `isAdmin`/`isHelper`; unificar caminho de foto no Storage; trocar `print` por logger.
- **Pronto quando:** com `operationMode: "venda"` nenhum vestígio de empréstimo aparece (e vice-versa), e o modo `emprestimo` se comporta exatamente como o app atual.

### Fase 3 — Venda MVP: "reserva com pagamento na retirada" (G)
- Campos de venda em `books`; tela de cadastro ampliada.
- Carrinho local, checkout só com retirada e `payOnPickup`.
- `createOrder`/`cancelOrder`/`advanceOrderStatus`/`expireUnpaidOrders` + regras de `orders` e estoque.
- "Meus Pedidos", "Gerenciar Pedidos", "Venda no balcão".
- Push de mudança de status; salvar o token FCM (hoje `getToken()` nunca é chamado).
- Dashboard de vendas básico.
- **Pronto quando:** um cliente compra, o atendente confirma pagamento presencial e entrega, o estoque fecha, e nenhuma dessas transições é possível por escrita direta no Firestore a partir do app.

> Esta fase entrega uma loja funcional **sem gateway de pagamento**, que é exatamente o fluxo que o app já domina. É o melhor ponto para colocar o primeiro cliente real.

### Fase 4 — Pagamento online (M/G)
- Gateway escolhido, Pix primeiro, cartão depois; webhook idempotente; reembolso; tela de pagamento com confirmação em tempo real.
- **Pronto quando:** pedido pago por Pix muda de estado sozinho em segundos e o reembolso devolve estoque.

### Fase 5 — Modo `ambos` (P/M)
- Flags por livro, estoques separados visíveis no cadastro, detalhe do livro com as duas ações, dashboard com as duas visões.

### Fase 6 — Entrega, cupons, relatórios (M)
- Endereços, taxa fixa, depois frete calculado; cupons; exportação CSV; ajuste de estoque com trilha.

### Fase 7 — Escala do white-label (M)
- `tool/new_brand.ps1` e `deploy_brand.ps1`: criar cliente novo em minutos.
- CI (GitHub Actions) com matriz de marcas; Fastlane para publicar.
- Unidades/filiais (`features.units`) e painel do `SUPER_ADMIN`.
- Tela "Configuração da loja" completa para o lojista se autoatender.

---

## 8. Decisões em aberto (com recomendação)

| # | Decisão | Recomendação |
|---|---|---|
| 1 | Um Firebase por cliente ou multi-tenant? | **Um por cliente** (3.2). |
| 2 | Estoque único ou separado para venda e empréstimo? | **Separado** (4.1). |
| 3 | Modo escolhido no build ou em runtime? | **Padrão no build, editável em runtime** pelo admin (3.1). |
| 4 | MVP com ou sem pagamento online? | **Sem**: pagar na retirada primeiro (Fase 3), Pix na Fase 4. |
| 5 | Qual gateway? | Decidir na Fase 4; manter interface trocável. Pix é prioridade no Brasil. |
| 6 | Apps publicados na sua conta ou na de cada cliente? | Na **conta do cliente** quando possível (a Apple é restritiva com apps "template" publicados em massa por uma mesma conta — diretriz 4.2.6). |
| 7 | Unidades/filiais no MVP? | **Não.** |
| 8 | E-books? | **Fora do escopo** (6.4). |
| 9 | Plataformas-alvo | **Android + iOS**; remover web/desktop do fork. |
| 10 | Compra sem login (vitrine pública)? | Navegar sem login é desejável para loja; comprar exige conta. Avaliar na Fase 3. |
| 11 | Modelo comercial do white-label (mensalidade, setup, comissão) | Fora do escopo técnico, mas influencia a decisão 5 (split de pagamento). |

---

## 9. Pontos legais e de publicação (validar com advogado/contador)

- **LGPD**: o app já coleta CPF, telefone e endereço; com venda passa a guardar histórico de compras. Necessário: política de privacidade por marca, base legal para cada dado, e rever quem consegue ler `users` (2.4).
- **Exclusão de conta** (exigida pela Play Store e já implementada): com pedidos, registros fiscais precisam ser retidos. A exclusão passa a **anonimizar** o usuário e manter os pedidos sem dados pessoais além do exigido por lei.
- **CDC**: compra fora do estabelecimento dá direito de arrependimento em 7 dias → fluxo de devolução/reembolso e política de trocas visível no checkout.
- **Nota fiscal**: livros têm imunidade de impostos, mas a operação continua exigindo documento fiscal. Integração com emissor de NF fica para depois do MVP; registrar no pedido os dados necessários (CPF, endereço) desde já.
- **Lojas de aplicativos**: formulário de segurança de dados da Play por marca; política de pagamentos (6.4); diretriz 4.2.6 da Apple (decisão 6).
- **Termos de uso** por marca, com aceite registrado no pedido.

---

## 10. Lista de verificação para iniciar o fork

**O que vai no arquivo compactado**
- Todo o código, o histórico git (`.git`), `CLAUDE.md`, este plano, `.agents/` e `antigravity.config.json`.
- `lib/firebase_options.dart` e `android/app/google-services.json`, para o projeto compilar no primeiro dia.
  **Atenção: eles apontam para o Firebase de produção da Biblioteca Guiar. Trocar na Fase 0, antes de rodar qualquer coisa que grave dados.**

**O que NÃO vai (de propósito)**
- `android/app/*.jks` (keystores de assinatura) e `android/local.properties` (caminhos da máquina e senhas de assinatura). O fork terá outro `applicationId` e deve ter assinatura própria; os originais permanecem na pasta do projeto original.
- Artefatos regeneráveis: `android/.gradle/`, `.idea/`, `*.iml`, `build/`, `.dart_tool/`, logs de build.

**Primeiros comandos no novo local**
```bash
# 1. descompactar e entrar na pasta
git remote remove origin            # desvincular do repositório original
git checkout -b whitelabel
# 1b. resolver os conflitos da seção 0, apagar pubspec.lock, e só então:
flutter pub get
# 2. criar projeto Firebase de DEV e reconfigurar
dart pub global activate flutterfire_cli
flutterfire configure               # sobrescreve firebase_options.dart e google-services.json
# 3. validar
flutter analyze
flutter run
```

**Antes de escrever a primeira linha de venda**
- [ ] Conflitos de merge resolvidos (`git grep` da seção 0 vazio) e `flutter pub get` funcionando
- [ ] Regras e índices do Firestore/Storage exportados do console e versionados
- [ ] Projeto Firebase de desenvolvimento separado do de produção
- [ ] Emulator Suite funcionando
- [ ] Testes consertados e rodando
- [ ] Decisões 1 a 4 da seção 8 confirmadas
