# Etapa 1: Definição do Projeto - Validação e Verificação de Sistemas

**Estudante:** [Seu Nome Aqui]
**Professora:** Marcia
**Disciplina:** Validação e Verificação de Sistemas - IFRS

---

### 1. Sistema Escolhido
**Nome do Sistema:** Biblioteca Guiar
**Descrição:** O sistema é um aplicativo móvel voltado para a gestão de uma biblioteca (originalmente desenvolvido para a Igreja Metodista de Palmas). Ele tem como objetivo facilitar o controle do acervo de livros, o gerenciamento de usuários e o acompanhamento de empréstimos e devoluções. O aplicativo possui diferentes níveis de acesso (Leitor, Administrador e Super Administrador), permitindo que os administradores controlem o estoque, aprovem/rejeitem empréstimos e gerenciem os usuários, enquanto os leitores podem consultar o catálogo, solicitar empréstimos de obras disponíveis e se comunicar com a administração através de um sistema de chat integrado.

Este projeto apresenta funcionalidades variadas (CRUD de livros, fluxos de autorização, regras de negócio baseadas em controle de estoque e de níveis de acesso), tornando-o altamente viável e com complexidade adequada para a aplicação prática das técnicas de verificação e validação (testes unitários, de componente e de sistema) requisitadas pela disciplina.

### 2. Linguagem de Programação Utilizada
O sistema foi desenvolvido utilizando a linguagem **Dart**.

### 3. Frameworks Utilizados
O sistema foi construído sobre a seguinte stack tecnológica:
* **Flutter:** Framework principal utilizado para a construção da interface do usuário multiplataforma (Android e iOS).
* **Firebase:** Plataforma utilizada para o backend como serviço (BaaS). Os serviços específicos utilizados incluem:
  * *Firebase Authentication:* Para gerenciar o login e o cadastro de usuários.
  * *Cloud Firestore:* Banco de dados NoSQL reativo para persistência de dados (livros, empréstimos, usuários e chat).
  * *Firebase Storage:* Para o armazenamento em nuvem de arquivos de mídia (como as capas dos livros e imagens de perfil).
* **Provider:** Framework/Pacote utilizado para a injeção de dependências e o gerenciamento de estado da aplicação.
