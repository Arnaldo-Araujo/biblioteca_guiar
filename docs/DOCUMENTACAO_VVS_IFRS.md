# 📖 Documentação do Projeto: Biblioteca Guiar (VVS - IFRS)

Bem-vindo à documentação do aplicativo **Biblioteca Guiar**. 

> [!IMPORTANT]
> **Contexto Acadêmico**
> Este documento foi elaborado para a disciplina de **Validação e Verificação de Sistemas (VVS)** do **IFRS**, ministrada pela professora **Marcia**. O objetivo é apresentar os requisitos, a arquitetura e o status de implementação do sistema, servindo de base para as atividades de validação e testes.

A documentação está estruturada para fornecer uma visão abrangente do sistema, desde as regras de negócio até as decisões técnicas e o estado atual do desenvolvimento.

---

## 🗺️ Estrutura do Documento

1. **Requisitos do Produto e Casos de Uso:** O que estamos construindo? Visão geral do negócio, Requisitos Funcionais (RF), Requisitos Não Funcionais (RNF) e principais casos de uso.
2. **Arquitetura e Especificação Técnica:** Como a aplicação está estruturada debaixo do capô? Decisões arquiteturais, stack tecnológica e estruturação do banco de dados (Firestore).
3. **Implementação e Histórico (Agile):** Qual o status atual do desenvolvimento? Resumo das funcionalidades implementadas e do backlog.
4. **Funcionalidades e Regras de Negócio:** Detalhamento das regras específicas de empréstimos, níveis de acesso (Admin/Super Admin) e comunicação interna.

---

# 📋 1. Requisitos de Produto e Casos de Uso

> **Aplicativo de gestão de biblioteca e controle de empréstimos.**
> Controle de acervo, usuários, empréstimos e comunicação interna para a Igreja Metodista de Palmas (adaptado como objeto de estudo para VVS).

## 🗂️ Informações do Produto

| Campo | Valor |
|---|---|
| **Nome** | Biblioteca Guiar |
| **Plataforma** | Flutter (Android, iOS) |
| **Backend** | Firebase (Auth, Firestore, Storage) |
| **Público-alvo** | Administradores da biblioteca e leitores/membros |
| **Modelo** | Gestão de acervo com níveis de acesso (Leitor, Admin, Super Admin) |
| **Stack** | Flutter 3.x · Dart · Firebase · Provider |

---

## 🛠️ Requisitos Funcionais (RF)

Os requisitos funcionais descrevem **o que** o sistema deve fazer.

- **RF01 - Gestão de Autenticação:** Cadastro, login e recuperação de senha de usuários (Leitores, Admins, Super Admins).
- **RF02 - Gestão de Acervo (Livros):** Cadastro, edição, listagem e remoção de livros disponíveis na biblioteca.
- **RF03 - Controle de Empréstimos:** Registro de retirada de livros, definição de prazos de devolução e baixa (devolução) de livros emprestados.
- **RF04 - Histórico de Empréstimos:** Consulta do histórico de livros emprestados por usuário.
- **RF05 - Chat/Comunicação:** Sistema de mensagens interno para comunicação entre leitores e administradores (ex: dúvidas, solicitação de renovação).
- **RF06 - Gestão de Perfil:** Edição de dados pessoais e foto de perfil do usuário.
- **RF07 - Painel Administrativo (Admin):** Área restrita para administradores gerenciarem o acervo e aprovarem/rejeitarem empréstimos.
- **RF08 - Painel Super Admin:** Área com privilégios máximos para gerenciar outros administradores e configurações globais da biblioteca.

---

## ⚙️ Requisitos Não Funcionais (RNF)

- **RNF01 - Gerenciamento de Estado:** Utilização do pacote `provider` para injeção de dependências e gerência de estado.
- **RNF02 - Tratamento de Erros:** Exceções interceptadas com blocos `try-catch` e exibição de alertas amigáveis na interface do usuário (UI).
- **RNF03 - Banco de Dados:** Firebase Firestore estruturado de forma não relacional (NoSQL), otimizado para leituras.
- **RNF04 - Armazenamento de Arquivos:** Firebase Storage para armazenamento de capas de livros e fotos de perfil dos usuários.
- **RNF05 - Segurança de Dados:** Firestore Security Rules aplicadas para restringir ações críticas (ex: apenas Admins podem adicionar livros).
- **RNF06 - Validação de Dados:** Validação de formato de CPF/CNPJ (utilizando pacote `cpf_cnpj_validator`) nos formulários.

---

## 🧑‍💻 Principais Casos de Uso (UC)

### UC01 - Realizar Empréstimo de Livro
1. Usuário (Leitor) navega pelo acervo e seleciona um livro disponível.
2. Solicita o empréstimo do livro através do aplicativo.
3. O sistema cria um registro de empréstimo (`LoanModel`) com status pendente.
4. Um Admin aprova o empréstimo, atualizando o estoque do livro e definindo a data limite de devolução.

### UC02 - Cadastrar Novo Livro (Admin)
1. Administrador acessa a aba de gestão do acervo.
2. Preenche os dados do livro (título, autor, sinopse, quantidade, etc.) e faz upload da imagem da capa.
3. O sistema salva a imagem no Firebase Storage e os dados do livro (`BookModel`) no Firestore.
4. O livro passa a ficar visível para todos os leitores.

### UC03 - Comunicação via Chat
1. Leitor acessa a seção de Chat.
2. Envia uma mensagem (`MessageModel`) para a administração.
3. O administrador recebe a notificação em tempo real (via `StreamBuilder` do Firestore) e responde à solicitação.

---

# 📘 2. Arquitetura e Especificação Técnica

O aplicativo foi projetado seguindo uma separação clara de responsabilidades, dividindo a lógica de negócio, a interface de usuário e a persistência de dados.

## 1. Estrutura de Diretórios (Camadas)

A arquitetura do projeto está organizada dentro da pasta `lib/` da seguinte forma:
- `models/`: Classes de representação de dados (ex: `book_model.dart`, `user_model.dart`, `loan_model.dart`).
- `providers/`: Controladores de estado e regras de negócio, servindo como ponte entre a UI e os serviços.
- `screens/`: Telas e fragmentos da interface do usuário (UI), divididas por feature (ex: `home`, `auth`, `book`, `loans`, `admin`).
- `services/`: Classes responsáveis pela comunicação externa, especificamente com as APIs do Firebase (Auth, Firestore, Storage).
- `widgets/`: Componentes visuais reutilizáveis (ex: botões customizados, cards de livros).
- `helpers/`: Funções utilitárias e constantes globais do aplicativo.

## 2. Endpoints e Rotas

A navegação do app é controlada internamente, com fluxos direcionados com base no nível de acesso do usuário logado:
- **Autenticação:** Telas de Login e Cadastro (`/auth`).
- **Navegação Principal (Leitor):** Home (Acervo), Meus Empréstimos, Perfil, Chat.
- **Navegação Administrativa:** Gestão de Livros, Gestão de Empréstimos, Painel Super Admin.

## 3. Schemas de Banco de Dados (Firestore)

A aplicação utiliza o Firestore de maneira reativa, consumindo streams para atualizar a interface em tempo real.

### Coleções Principais:
- `/users`: Documentos de perfil (`UserModel`). Contém dados como nome, email, CPF e nível de acesso (role).
- `/books`: Documentos do acervo (`BookModel`). Contém título, autor, quantidade disponível, url da capa.
- `/loans`: Histórico e solicitações de empréstimo (`LoanModel`). Referencia o ID do livro e o ID do usuário, além das datas de início, devolução e status.
- `/chats`: Mensagens do sistema de comunicação interna (`MessageModel`).

### Exemplo de Modelo de Dados (Livro)
```json
// BookModel
{
  "id": "abc123xyz",
  "title": "A Cabana",
  "author": "William P. Young",
  "description": "Uma jornada espiritual...",
  "coverUrl": "https://firebasestorage.googleapis.com/...",
  "totalQuantity": 5,
  "availableQuantity": 3,
  "createdAt": "<Timestamp>"
}
```

---

# ⚙️ 3. Implementação e Histórico (Agile)

## 📈 Resumo do Projeto (Burndown)

- **Fase Atual:** Manutenção e Adaptação para VVS.
- **Features Finalizadas:** 
  - Autenticação e Gestão de Usuários (Auth).
  - CRUD completo de Livros no Acervo.
  - Fluxo de Empréstimos (Solicitação, Aprovação e Devolução).
  - Controle de Acesso Baseado em Roles (Leitor, Admin, Super Admin).
  - Comunicação via Chat.
- **Foco para Validação (VVS):** 
  - Testes de limite de estoque (tentar emprestar livro sem quantidade disponível).
  - Testes de segurança de regras do Firestore (tentar deletar livro sendo Leitor).
  - Validação do fluxo de devolução e recálculo de disponibilidade do acervo.

---

# 🎮 4. Funcionalidades e Regras de Negócio Específicas

Para a disciplina de **Validação e Verificação de Sistemas**, é crucial entender os comportamentos esperados (oráculos de teste) das principais funcionalidades:

## 🛡️ Regras de Empréstimo e Estoque
- **Bloqueio por Indisponibilidade:** O sistema **não** deve permitir a solicitação de um empréstimo se `availableQuantity` de um `BookModel` for igual a 0.
- **Atualização Atômica:** Quando um empréstimo é APROVADO, a quantidade disponível do livro deve ser decrementada em exatos 1 unidade. Quando DEVOLVIDO, deve ser incrementada em 1 unidade.
- **Limite de Empréstimos:** Verificar se há regras de negócio ativas limitando o número de livros simultâneos por usuário (RNF de validação).

## 🔒 Controle de Acesso (RBAC)
O aplicativo lida com três níveis de usuários no `UserModel`:
1. **User (Leitor):** Apenas lê o acervo, solicita empréstimos e visualiza seu próprio histórico.
2. **Admin:** Pode adicionar/editar/remover livros e gerenciar empréstimos de todos os usuários.
3. **Super Admin:** Todas as permissões do Admin, mais a capacidade de promover outros usuários a Admin e gerenciar configurações globais.

A validação de segurança (VVS) deve garantir que as views do aplicativo ocultem os botões administrativos (como "Adicionar Livro") para usuários com role "User". Além disso, o backend (Firestore Rules) deve rejeitar gravações indevidas, caso uma requisição maliciosa tente contornar a interface.
