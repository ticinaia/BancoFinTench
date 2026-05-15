# BancoFinTech

Aplicativo bancario feito em Flutter para a disciplina de Mobile. O projeto ja
nasceu com uma base organizada para a equipe trabalhar em paralelo: Firebase,
rotas nomeadas, tema global, telas iniciais e servicos centralizados.

Este README explica como cada membro deve preparar o ambiente, entender o fluxo
do app e contribuir sem quebrar o trabalho dos outros.

## 1. Stack do Projeto

- Flutter e Dart
- Material Design 3
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Flutter Riverpod
- Dio para chamadas HTTP
- AwesomeAPI para cotacoes
- Local Auth para biometria
- Flutter Secure Storage para dados sensiveis locais
- Mobile Scanner para leitura de codigos
- Share Plus para compartilhamento
- Image Picker para camera/galeria
- Google Fonts

## 2. Como Preparar o Ambiente

1. Instale o Flutter na maquina.
2. Confirme se o Flutter esta funcionando:

```bash
flutter doctor
```

3. Entre na pasta do projeto:

```bash
cd banco
```

4. Baixe as dependencias:

```bash
flutter pub get
```

5. Rode o app em um emulador, celular ou navegador:

```bash
flutter run
```

6. Para rodar no Chrome:

```bash
flutter run -d chrome
```

## 3. Comandos Importantes

Use estes comandos antes de entregar qualquer parte do trabalho:

```bash
flutter analyze
flutter test
```

Se precisar limpar arquivos gerados pelo Flutter:

```bash
flutter clean
flutter pub get
```

## 4. Estrutura de Pastas

```text
lib/
├── app/
│   ├── routes/
│   └── theme/
├── core/
│   ├── constants/
│   └── services/
├── features/
│   ├── auth/
│   ├── home/
│   └── splash/
├── firebase_options.dart
└── main.dart
```

### O que fica em cada pasta

- `lib/main.dart`: ponto de entrada do app. Inicializa Flutter, orientacao da
  tela, plugins, Firebase e abre o `MaterialApp`.
- `lib/app/routes/`: concentra os nomes das rotas e o gerador de navegacao.
- `lib/app/theme/`: cores, estilos de texto e tema global do app.
- `lib/core/constants/`: constantes compartilhadas, como nome do app, URLs,
  timeouts e chaves de armazenamento.
- `lib/core/services/`: servicos reutilizaveis, como Firebase e plugins.
- `lib/features/`: funcionalidades do app separadas por modulo.
- `test/`: testes automatizados.
- `android/`, `ios/`, `web/`: configuracoes especificas de cada plataforma.
- `build/`: arquivos gerados automaticamente. Nao deve ser alterada manualmente.

## 5. Fluxo de Execucao do App

1. O Flutter executa `main()` em `lib/main.dart`.
2. `WidgetsFlutterBinding.ensureInitialized()` prepara recursos nativos antes do
   app abrir.
3. O app trava a orientacao em modo retrato, ideal para um aplicativo bancario.
4. A barra de status e configurada com fundo transparente.
5. `AppPlugins.initialize()` inicializa os servicos centrais.
6. `FirebaseService.initialize()` tenta iniciar o Firebase usando
   `lib/firebase_options.dart`.
7. O app chama `runApp(const BancoFinTechApp())`.
8. `BancoFinTechApp` cria o `MaterialApp` com:
   - titulo do app vindo de `AppConstants.appName`;
   - tema claro e tema escuro;
   - idioma `pt_BR`;
   - rota inicial `AppRoutes.splash`;
   - rotas geradas por `AppRouter.onGenerateRoute`.

## 6. Fluxo de Telas

### Splash

Arquivo:

```text
lib/features/splash/presentation/pages/splash_page.dart
```

Passo a passo:

1. Mostra o logo e o nome BancoFinTech.
2. Executa animacoes de fade, escala e slide.
3. Aguarda `AppConstants.splashDuration`, atualmente 3 segundos.
4. Redireciona para a tela de login.

No futuro, a splash deve verificar se existe sessao ativa. Se o usuario ja
estiver logado, deve ir para `home`; caso contrario, deve ir para `login`.

### Login

Arquivo:

```text
lib/features/auth/presentation/pages/login_page.dart
```

Passo a passo:

1. Mostra o status do Firebase.
2. Exibe formulario com e-mail e senha.
3. Valida se os campos foram preenchidos.
4. Ao clicar em `Entrar`, tenta autenticar com Firebase Auth.
5. Se o usuario ainda nao existir, cria a conta com e-mail e senha.
6. Cria ou atualiza o documento do usuario no Firestore.
7. Depois navega para a home.

Arquivos principais da autenticacao:

```text
lib/features/auth/data/repositories/auth_repository.dart
lib/features/auth/data/repositories/user_repository.dart
lib/features/auth/domain/models/app_user.dart
```

### Home

Arquivo:

```text
lib/features/home/presentation/pages/home_page.dart
```

Passo a passo:

1. Mostra um dashboard inicial.
2. Informa se o Firebase foi inicializado.
3. Possui um botao para voltar ao login.

A home e o ponto onde as proximas features do banco devem aparecer: saldo,
extrato, perfil, transferencias, pagamentos, cartoes e outras entregas do grupo.

## 7. Rotas e Navegacao

As rotas ficam em:

```text
lib/app/routes/app_routes.dart
lib/app/routes/routes.dart
```

Rotas atuais:

- `/`: splash
- `/login`: login
- `/home`: home

Para navegar:

```dart
Navigator.pushNamed(context, AppRoutes.login);
Navigator.pushReplacementNamed(context, AppRoutes.home);
```

Para adicionar uma nova tela:

1. Crie a tela dentro de `lib/features/nome_da_feature/`.
2. Adicione uma constante em `AppRoutes`.
3. Importe a pagina em `routes.dart`.
4. Adicione um `case` no `switch` de `AppRouter.onGenerateRoute`.
5. Teste a navegacao no app.

## 8. Firebase

Arquivos principais:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `firebase.json`

O Firebase e inicializado em:

```text
lib/core/services/firebase_service.dart
```

O servico possui:

- `FirebaseService.isReady`: indica se o Firebase iniciou corretamente.
- `FirebaseService.lastError`: guarda o erro caso a inicializacao falhe.
- `FirebaseService.auth`: acesso ao Firebase Auth.
- `FirebaseService.firestore`: acesso ao Cloud Firestore.

Produtos que a equipe deve habilitar no console do Firebase conforme as
features forem implementadas:

- Authentication com Email/Password
- Cloud Firestore
- Storage, se houver upload de imagens ou documentos

Colecao inicial usada pelo app:

```text
users/{uid}
```

Campos gravados:

- `email`: e-mail do usuario.
- `name`: nome inicial gerado a partir do e-mail.
- `createdAt`: data de criacao do documento.
- `updatedAt`: data da ultima atualizacao.

## 9. Plugins Centralizados

Os plugins ficam em:

```text
lib/core/services/app_plugins.dart
```

Use essa classe para evitar criar varias instancias soltas pelo projeto.

Recursos disponiveis:

- `AppPlugins.dio`: cliente HTTP configurado com a URL da AwesomeAPI.
- `AppPlugins.secureStorage`: armazenamento seguro local.
- `AppPlugins.localAuth`: biometria e autenticacao local.
- `AppPlugins.imagePicker`: camera e galeria.
- `AppPlugins.firebaseAuth`: Firebase Auth, quando o Firebase estiver pronto.
- `AppPlugins.firestore`: Cloud Firestore, quando o Firebase estiver pronto.

## 10. Tema Visual

Arquivos:

```text
lib/app/theme/app_colors.dart
lib/app/theme/app_text_styles.dart
lib/app/theme/app_theme.dart
```

Regras para manter o visual consistente:

1. Use as cores de `AppColors`.
2. Use os estilos de texto de `AppTextStyles` ou `Theme.of(context).textTheme`.
3. Evite cores fixas direto nas telas, exceto quando for realmente necessario.
4. Prefira componentes do tema global, como `ElevatedButton`, `TextFormField`,
   `Card` e `AppBar`.
5. Antes de criar um estilo novo, veja se o tema atual ja resolve.

## 11. Como Cada Membro Deve Trabalhar

Fluxo recomendado:

1. Atualize o projeto antes de comecar.
2. Escolha uma feature pequena e bem definida.
3. Crie ou edite arquivos somente dentro da area da sua feature quando possivel.
4. Se precisar mexer em `core/`, `routes/` ou `theme/`, avise o grupo, porque
   essas pastas afetam todo mundo.
5. Rode o app e teste manualmente o fluxo alterado.
6. Rode `flutter analyze`.
7. Rode `flutter test`.
8. Envie a alteracao com uma mensagem clara.

Exemplo de divisao de tarefas:

- Membro 1: autenticacao e cadastro.
- Membro 2: home, saldo e extrato.
- Membro 3: transferencias e pagamentos.
- Membro 4: perfil, biometria e armazenamento seguro.
- Membro 5: integracao com API externa e cotacoes.

## 12. Padrao Para Criar Novas Features

Crie uma pasta dentro de `lib/features/`:

```text
lib/features/nome_da_feature/
└── presentation/
    └── pages/
        └── nome_da_pagina.dart
```

Se a feature crescer, use tambem:

```text
lib/features/nome_da_feature/
├── data/
├── domain/
└── presentation/
    ├── pages/
    └── widgets/
```

Sugestao de responsabilidades:

- `data/`: comunicacao com Firebase, APIs e armazenamento local.
- `domain/`: regras de negocio, entidades e casos de uso.
- `presentation/`: telas, widgets e estados visuais.

## 13. Checklist Antes de Entregar

Antes de dizer que sua parte esta pronta, confira:

- O app abre sem erro.
- A tela funciona no fluxo esperado.
- Nao existem imports inutilizados.
- Nao existem `print` esquecidos.
- O codigo esta formatado.
- `flutter analyze` passa sem problemas.
- `flutter test` passa.
- Arquivos gerados dentro de `build/` nao foram editados manualmente.
- Dados sensiveis, senhas e tokens nao foram colocados no codigo.

Para formatar:

```bash
dart format lib test
```

## 14. O Que Ja Esta Pronto

- Estrutura inicial do projeto Flutter.
- Firebase configurado no codigo.
- Inicializacao centralizada de plugins.
- Tema claro e escuro.
- Rotas nomeadas.
- Splash animada.
- Tela de login inicial.
- Tela home inicial.
- Teste simples de abertura do app.

## 15. Proximos Passos Sugeridos

1. Implementar login real com Firebase Auth.
2. Criar tela de cadastro.
3. Verificar sessao ativa na splash.
4. Criar modelo de usuario no Firestore.
5. Criar dashboard com saldo e ultimas transacoes.
6. Criar extrato.
7. Criar fluxo de transferencia.
8. Adicionar biometria com `local_auth`.
9. Salvar dados sensiveis com `flutter_secure_storage`.
10. Criar testes para os fluxos principais.

## 16. Observacoes Importantes

- A pasta `assets/images/` e `assets/icons/` esta declarada no `pubspec.yaml`.
  Se forem usados assets, os arquivos devem ser colocados nessas pastas.
- Se algum pacote novo for adicionado, rode `flutter pub get` e avise o grupo.
- Alteracoes em Firebase, rotas, tema e constantes devem ser combinadas para
  evitar conflito entre as tarefas.
- O projeto esta em evolucao. Prefira organizar cada entrega de forma pequena,
  testavel e facil de revisar.
