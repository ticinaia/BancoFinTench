# FinTech - Banco Digital em Flutter
Universidade da Amazonia (UNAMA)
Professor Mauricio Aldenor - Desenvolvimento Mobile
A
Alunos: Leticia Monteiro Alves da SIlva - 04186058 - Divisao de Tarefas, Configuraç~ao de Ambiente e Banco de Dados, Centralizaç~ao de Plugins, Historico de Trasnferencias, comprovante e implementaçao de Qr Code, Melhorias e refinamento logico
Bruno Henrique Brasil da Silva - 04185495 - Desenvolveu a Home com saldo e ultimas transferencias e aplicou o plugin de Image_Picker
Daniel Viana de Farias - 04178809 - Desenvolveu a p'agina de Cotaçao com o uso de Api, tratou os erros de conexao e implementou segurança.
Felipe Mota Damasceno - 04183762 - Desenvolveu as telas de login e cadastro com Firebase Auth, logout, e implementou a biometria
Camila Gonçalves Bomfim - 04185677 - Desenvolveu as telas de Pix






## 1. Apresentação do projeto

O **FinTech** é um aplicativo mobile desenvolvido em **Flutter** com a proposta de simular a experiência principal de um banco digital. O projeto foi criado para atender à atividade de Programação Mobile, que solicitava uma aplicação bancária com acesso a banco de dados, telas mínimas de login, principal, cotação e transferência, uso de rotas nomeadas, uso de API externa e utilização de plugins.

A ideia central foi construir um app que não fosse apenas uma sequência de telas isoladas, mas uma jornada parecida com a de um banco real: o usuário cria conta, confirma e-mail, protege o acesso com PIN ou biometria, consulta saldo, acompanha cotações, envia e recebe Pix, visualiza extrato e abre comprovantes.

## 2. Requisitos da atividade atendidos

| Requisito | Como foi implementado |
| --- | --- |
| Aplicação mobile em Flutter | Projeto desenvolvido em Flutter e Dart, com Material Design 3. |
| Tema de banco digital | Fluxo de conta, saldo, Pix, extrato, comprovante, segurança e cotações. |
| Acesso a banco de dados | Firebase Auth para autenticação e Cloud Firestore para dados da conta, saldo, Pix, favoritos e histórico. |
| Tela de Login | `LoginPage`, com autenticação por e-mail e senha. |
| Tela Principal | `HomePage`, com saldo, resumo mensal, ações rápidas e últimas transferências. |
| Tela de Cotação | `CotacaoPage`, consumindo API externa com Dio. |
| Tela de Transferência | `PixTransferPage`, com chave Pix, valor, confirmação, PIN/biometria e comprovante. |
| Rotas nomeadas | Todas as telas são acessadas por constantes em `AppRoutes`. |
| Rotas nomeadas com argumentos | `PixReceiptPage` recebe um `PixReceipt` por argumento de rota. |
| Uso de API com conexão | AwesomeAPI para consultar dólar, euro e bitcoin em reais. |
| Uso de plugins | Biometria, armazenamento seguro, câmera/galeria, scanner de QR Code, geração de QR Code e compartilhamento. |
| Criatividade | Jornada com verificação de e-mail, bloqueio por sessão, Pix com QR Code, favoritos e comprovantes. |

## 3. Tecnologias utilizadas

- **Flutter e Dart**: base da aplicação mobile.
- **Material Design 3**: construção dos componentes visuais.
- **Firebase Core**: inicialização do Firebase.
- **Firebase Auth**: cadastro, login, verificação de e-mail e recuperação de senha.
- **Cloud Firestore**: persistência de dados bancários simulados.
- **Dio**: comunicação HTTP com a API de cotações.
- **AwesomeAPI**: consulta de cotações de USD, EUR e BTC em BRL.
- **Local Auth**: autenticação por biometria ou bloqueio do aparelho.
- **Flutter Secure Storage**: armazenamento local seguro do PIN.
- **Mobile Scanner**: leitura de QR Code Pix.
- **QR Flutter**: geração de QR Code para recebimento Pix.
- **Share Plus**: compartilhamento de comprovantes.
- **Image Picker**: escolha de foto de perfil por câmera ou galeria.
- **Google Fonts e Intl**: tipografia e formatação brasileira de moeda/data.

## 4. Organização do projeto

A organização foi feita por responsabilidades, separando estrutura global, serviços centrais e funcionalidades.

```text
lib/
├── app/
│   ├── routes/              # Rotas nomeadas e gerador de rotas
│   ├── theme/               # Cores, tema claro/escuro e estilos
│   └── widgets/             # Widgets globais, como navegação inferior
├── core/
│   ├── constants/           # Constantes do app
│   ├── services/            # Firebase, plugins e repositórios centrais
│   └── utils/               # Formatadores brasileiros
├── features/
│   ├── auth/                # Login, cadastro, segurança, PIN e cotações
│   ├── home/                # Tela principal
│   ├── pix/                 # Transferência, recebimento, extrato e comprovante
│   └── splash/              # Tela inicial e redirecionamento
└── main.dart                # Inicialização do aplicativo
```

Essa divisão ajudou a manter o código mais legível. Cada funcionalidade possui suas páginas, modelos, validadores, serviços ou repositórios próprios.

## 5. Decisões de arquitetura

O projeto usa uma arquitetura simples, mas organizada. A camada de apresentação fica nas telas e widgets. A camada de dados fica nos repositórios, como `AuthRepository`, `UserRepository`, `PixRepository` e `CotacaoRepository`. Serviços compartilhados, como Firebase e plugins, ficam em `core/services`.

Essa escolha foi feita para evitar que as telas ficassem responsáveis por tudo. Por exemplo, a tela de Pix não conversa diretamente com o Firestore; ela chama o `PixRepository`, que centraliza regras de saldo, limite diário, envio, recebimento, favoritos e histórico.

Também foi criada uma centralização de repositórios em `AppRepositories`. Com isso, as telas acessam dependências do app por um ponto único, deixando o código mais consistente.

## 6. Escolha do Firebase como banco de dados

O Firebase foi escolhido porque combina bem com a proposta de um app mobile acadêmico e funcional. Ele oferece autenticação e banco de dados em tempo real sem exigir a criação de um backend próprio.

No projeto, ele foi usado em duas partes principais:

- **Firebase Auth**: gerencia cadastro, login, verificação de e-mail, recuperação de senha e conta autenticada.
- **Cloud Firestore**: armazena dados do usuário, saldo, foto de perfil em base64, histórico de Pix, contatos favoritos e notificações internas.

A escolha do Firestore também facilitou a atualização automática da interface. A Home, o resumo mensal e o extrato escutam streams do banco, então os dados são refletidos no app conforme mudam.

## 7. Rotas nomeadas e navegação

As rotas ficam centralizadas em:

```text
lib/app/routes/app_routes.dart
lib/app/routes/routes.dart
```

Principais rotas:

```text
/login
/cadastro
/home
/cotacao
/pix-transfer
/pix-receive
/pix-history
/pix-receipt
/security
```

O projeto também usa **rotas com argumentos**. O melhor exemplo é o comprovante Pix: depois de enviar ou receber um Pix, o app navega para `AppRoutes.pixReceipt` enviando um objeto `PixReceipt`. A tela `PixReceiptPage` recebe esse argumento e monta o comprovante com valor, chave, banco, status, data e código da transação.

Além disso, existe uma proteção de rotas. Se o usuário não estiver logado, ele volta para o login. Se o e-mail não estiver verificado, ele vai para a tela de confirmação. Se a sessão estiver bloqueada, ele vai para a tela de desbloqueio.

## 8. Jornada do usuário

### 8.1 Abertura do aplicativo

A jornada começa na Splash. Essa tela verifica o estado da sessão e decide para onde o usuário deve ir. Esse redirecionamento torna o app mais próximo de uma experiência real, porque o usuário não precisa escolher manualmente se deve ir para login, verificação de e-mail, PIN ou Home.

### 8.2 Cadastro

No cadastro, o usuário informa nome completo, e-mail, CPF, celular e senha. O app valida os dados antes de criar a conta. Essa etapa foi pensada para simular a abertura de uma conta bancária, em que os dados precisam ter formato válido.

Depois do cadastro, o app envia o usuário para a confirmação de e-mail. Essa decisão reforça a ideia de segurança e evita que qualquer conta criada entre diretamente no app sem validação.

### 8.3 Login e verificação

No login, o usuário entra com e-mail e senha. Se o e-mail ainda não estiver confirmado, o app direciona para a tela de verificação. Se já estiver confirmado, o app verifica se o usuário possui PIN configurado.

Esse fluxo cria uma ordem de segurança:

1. O usuário precisa existir no Firebase Auth.
2. O e-mail precisa estar verificado.
3. O usuário precisa ter um PIN.
4. A sessão precisa estar desbloqueada.

### 8.4 Criação de PIN e desbloqueio

Após confirmar o e-mail, o usuário cria um PIN. Esse PIN é salvo de forma segura usando `flutter_secure_storage`. Depois disso, o acesso ao app pode ser protegido por PIN ou biometria.

O app também possui bloqueio de sessão. Se o usuário ficar muito tempo inativo ou sair e voltar após o tempo definido, a sessão é bloqueada e precisa ser liberada novamente.

### 8.5 Tela principal

A Home apresenta as informações principais da conta:

- saudação com nome do usuário;
- foto de perfil;
- saldo com opção de ocultar/mostrar;
- proteção por biometria ou bloqueio do aparelho;
- resumo de entradas e saídas do mês;
- ações rápidas;
- últimas transferências.

A ideia da Home foi funcionar como o painel inicial de um banco digital. Ela concentra o que o usuário provavelmente procura primeiro: saldo, movimentações recentes e atalhos para ações financeiras.

### 8.6 Cotações

A tela de cotações consulta a AwesomeAPI e mostra valores de dólar, euro e bitcoin em reais. A tela também possui atualização manual e tratamento de erro para problemas de conexão.

Esse requisito foi importante porque mostra o uso de API externa com conexão real. A consulta fica no `CotacaoRepository`, deixando a tela responsável apenas por exibir o resultado.

### 8.7 Transferência Pix

A transferência Pix foi a parte mais trabalhosa da jornada. O usuário escolhe o tipo de chave, informa a chave, digita o valor e confirma os dados. Antes de enviar, o app confere saldo, resolve o destinatário, mostra um resumo e pede autenticação por biometria ou PIN.

Depois do envio, o saldo é atualizado no Firestore e o usuário recebe um comprovante. O app também permite:

- preencher uma transferência de demonstração;
- ler QR Code;
- colar código Pix;
- salvar destinatários como favoritos;
- reutilizar contatos frequentes.

Essa tela tenta simular a sensação de um banco real, mas sem complicar demais a implementação para o contexto da atividade.

### 8.8 Recebimento Pix

Na tela de recebimento, o usuário escolhe uma chave da conta, informa um valor e o app gera um QR Code. Depois, pode simular o recebimento, atualizando saldo e criando comprovante.

Essa parte complementa a transferência, pois mostra os dois lados do Pix: enviar e receber.

### 8.9 Extrato e comprovante

O extrato lista movimentações, permite filtros por tipo, data e valor, e abre comprovantes. O comprovante pode ser compartilhado usando plugin de compartilhamento.

A rota de comprovante é um ponto importante do projeto porque demonstra navegação com argumento. A tela recebe os dados da transação e monta uma visualização própria, como acontece em aplicativos bancários.

### 8.10 Segurança e preferências

A tela de segurança permite atualizar dados, solicitar troca de e-mail, alterar senha por e-mail, trocar PIN, escolher tema claro/escuro/sistema e excluir conta.

Essa tela foi incluída para deixar a aplicação mais completa e demonstrar que um banco digital também precisa de área de gerenciamento da conta.

## 9. Jornada do desenvolvedor

Durante o desenvolvimento, a maior dificuldade foi transformar a ideia geral de "banco digital" em funcionalidades simples, mas convincentes. Um banco real possui muitas regras complexas, então foi necessário escolher quais partes seriam simuladas sem perder a coerência.

A lógica de Pix foi o principal desafio. Era necessário pensar em saldo, limite diário, chave, destinatário, recebimento, histórico, comprovante e cancelamento de Pix pendente. A dificuldade não foi apenas criar telas, mas organizar uma sequência lógica que fizesse sentido para o usuário e estivesse dentro das nossas capacidades como desenvolvedores.

Outra dificuldade foi reunir ideias que fossem simples para implementar dentro do prazo, mas que ainda parecessem com um banco real. Por isso, algumas decisões foram tomadas:

- o saldo inicial é simulado;
- os destinatários podem ser resolvidos de forma demonstrativa;
- o recebimento Pix é simulado pelo próprio app;
- o QR Code usa payload Pix para tornar a experiência mais realista;
- o comprovante registra as informações essenciais da operação;
- o Firestore guarda as movimentações para manter histórico.

Também houve preocupação em manter o código organizado. Conforme o app cresceu, algumas responsabilidades foram separadas em repositórios, validadores, formatadores e widgets próprios. Isso facilitou a manutenção pontual durante o desenvolvimento.

## 10. Uso de IA no desenvolvimento

A inteligência artificial foi utilizada como apoio durante o projeto, principalmente em duas frentes: design e manutenção pontual.

No design, a IA ajudou a pensar em uma interface com aparência de banco digital, sugerindo organização de telas, hierarquia visual, textos mais claros e componentes coerentes com o uso mobile. A decisão final e a implementação ficaram no código Flutter, mas a IA auxiliou apenas no processo inicial. 

Na manutenção, a IA foi usada para revisar textos, sugerir nomes mais claros, identificar repetições e apoiar pequenas otimizações sem alterar a lógica principal do app que foi feito pelos desenvolvedores. Um exemplo foi a criação de um helper para formatar valores monetários em campos de entrada, evitando repetição de código em telas de Pix.

O uso da IA não substituiu a compreensão do projeto. Ela foi usada como ferramenta de apoio para organizar ideias, melhorar clareza e acelerar ajustes pontuais. entao o uso foi pontual e consciente, respeitando o limite estabelecido pela atividade.

## 11. Como executar o projeto

1. Instale o Flutter.
2. Entre na pasta do projeto.
3. Baixe as dependências:

```bash
flutter pub get
```

4. Execute o app:

```bash
flutter run
```

5. Para executar no Chrome:

```bash
flutter run -d chrome
```

## 12. Comandos de verificação

Antes de entregar ou gerar APK, foram usados comandos de análise e teste:

```bash
flutter analyze
flutter test
```

Resultado da última verificação:

- `flutter analyze`: sem problemas encontrados.
- `flutter test`: todos os testes passaram.

## 13. Geração do APK

Para gerar um APK otimizado em modo release:

```bash
flutter build apk --release
```

O arquivo gerado normalmente fica em:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 14. Considerações finais

O FinTech foi desenvolvido com o objetivo de demonstrar os principais conceitos pedidos na atividade: telas em Flutter, navegação por rotas nomeadas, API externa, banco de dados, plugins e criatividade.

Mais do que cumprir telas obrigatórias, o projeto tenta apresentar uma jornada completa de usuário em um banco digital. O foco foi criar uma experiência didática, organizada e coerente: da criação da conta até o uso de Pix, consulta de cotações, segurança e visualização de comprovantes.
