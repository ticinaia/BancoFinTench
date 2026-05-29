import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/cotacao_repository.dart';
import '../../features/auth/data/repositories/user_repository.dart';
import '../../features/pix/data/repositories/pix_repository.dart';

class AppRepositories {
  AppRepositories._();

  static final UserRepository user = UserRepository();
  static final AuthRepository auth = AuthRepository(userRepository: user);
  static final PixRepository pix = PixRepository();
  static final CotacaoRepository cotacao = CotacaoRepository();
}
