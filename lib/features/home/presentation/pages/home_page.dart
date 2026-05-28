import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:intl/intl.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/app_plugins.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authRepository = AuthRepository();
  bool _biometriaDisponivel = false;
  bool _saldoVisivel = false;
  
  XFile? _imagemPerfil;

  final List<Map<String, dynamic>> _ultimasTransferencias = [
  {
    'nome': 'Maria Silva',
    'valor': 580.00,
    'tipo': 'recebido',
    'data': 'Hoje, 14:22',
  },
  {
    'nome': 'João Pedro',
    'valor': 150.00,
    'tipo': 'enviado',
    'data': 'Ontem, 18:40',
  },
  {
    'nome': 'Netflix',
    'valor': 39.90,
    'tipo': 'enviado',
    'data': 'Ontem, 09:10',
  },
];

  @override
  void initState() {
    super.initState();
    _verificarBiometria();
  }

  Future<void> _verificarBiometria() async {
  if (kIsWeb) {
    setState(() => _biometriaDisponivel = false);
    return;
  }

  try {
    final disponivel =
        await AppPlugins.localAuth.canCheckBiometrics;

    final suportado =
        await AppPlugins.localAuth.isDeviceSupported();

    if (mounted) {
      setState(() {
        _biometriaDisponivel =
            disponivel || suportado;
      });
    }
  } catch (_) {
    if (mounted) {
      setState(() {
        _biometriaDisponivel = false;
      });
    }
  }
}

  Future<void> _mostrarSaldoComBiometria() async {
    if (_saldoVisivel) {
      setState(() => _saldoVisivel = false);
      return;
    }

    final autenticado = await _autenticarComBiometria(
      'Confirme sua identidade para visualizar o saldo',
    );

    if (autenticado && mounted) {
      setState(() => _saldoVisivel = true);
    }
  }

  Future<bool> _autenticarComBiometria(String motivo) async {
  if (kIsWeb) return true;

  if (!_biometriaDisponivel) return true;

  try {
    return await AppPlugins.localAuth.authenticate(
      localizedReason: motivo,
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  } catch (_) {
    if (mounted) {
      _mostrarMensagem('Erro ao autenticar.');
    }
    return false;
  }
}
  
  Future<void> _selecionarImagem(ImageSource source) async {
  try {
    final imagem = await AppPlugins.imagePicker.pickImage(
      source: source,
      imageQuality: 75,
    );

    if (imagem == null) return;

    setState(() {
      _imagemPerfil = imagem;
    });

    if (mounted) {
      _mostrarMensagem('Imagem de perfil atualizada.');
    }
  } catch (_) {
    _mostrarMensagem('Erro ao selecionar imagem.');
  }
}

void _abrirSeletorImagem() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Escolher imagem de perfil',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _selecionarImagem(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _selecionarImagem(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Future<void> _logout() async {
    await _authRepository.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepository.currentUser;
    final name = user?.email?.split('@').first ?? 'cliente';

    return Scaffold(
      appBar: AppBar(
        title: const Text('BancoFinTech'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
                        Row(
              children: [
                GestureDetector(
                  onTap: _abrirSeletorImagem,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: _imagemPerfil != null
                    ? (kIsWeb
                        ? NetworkImage(_imagemPerfil!.path)
                        : FileImage(File(_imagemPerfil!.path))
                            as ImageProvider)
                    : null,
                    child: _imagemPerfil == null
                        ? const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 32,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard inicial',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall,
                      ),
                      Text(
                        'Toque na foto para alterar',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_biometriaDisponivel)
                ElevatedButton.icon(
                  onPressed: _autenticarComBiometria,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Autenticar com Digital'),
                ),

              if (_biometriaDisponivel)
                const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.pixTransfer,
                  );
                },
                child: const Text('Transferência PIX'),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.pixHistory,
                  );
                },
                child: const Text('Histórico PIX'),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
