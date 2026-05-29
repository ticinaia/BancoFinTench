import 'package:dio/dio.dart';
import 'package:banco_fin_tech/features/auth/domain/models/cotacao.dart';
import 'package:banco_fin_tech/core/services/app_plugins.dart';

class CotacaoRepository {
  CotacaoRepository({Dio? dio}) : _dio = dio ?? AppPlugins.dio;

  final Dio _dio;
  List<Cotacao>? _cachedCotacoes;
  DateTime? _cachedAt;

  Future<List<Cotacao>> getCotacoes({bool forceRefresh = false}) async {
    final cached = _cachedCotacoes;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < const Duration(minutes: 1)) {
      return cached;
    }

    try {
      final response = await _dio.get(
        '/json/last/USD-BRL,EUR-BRL,BTC-BRL',
        queryParameters: {
          'format': DateTime.now().millisecondsSinceEpoch,
        },
      );
      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('A API retornou uma resposta inválida.');
      }

      final dolar = data['USDBRL'];
      final euro = data['EURBRL'];
      final bitcoin = data['BTCBRL'];

      if (dolar is! Map<String, dynamic> ||
          euro is! Map<String, dynamic> ||
          bitcoin is! Map<String, dynamic>) {
        throw Exception('A API não retornou todas as cotações esperadas.');
      }

      final cotacoes = [
        Cotacao.fromJson(dolar),
        Cotacao.fromJson(euro),
        Cotacao.fromJson(bitcoin),
      ];
      _cachedCotacoes = cotacoes;
      _cachedAt = DateTime.now();
      return cotacoes;
    } on DioException catch (e) {
      throw Exception(_formatarErroDio(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception('Não foi possível carregar as cotações.');
    }
  }

  String _formatarErroDio(DioException erro) {
    switch (erro.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'A API demorou para responder. Tente novamente em alguns segundos.';
      case DioExceptionType.badCertificate:
        return 'Não foi possível validar a conexão segura com a API.';
      case DioExceptionType.badResponse:
        final statusCode = erro.response?.statusCode;
        if (statusCode == null) {
          return 'A API recusou a solicitação de cotações.';
        }
        return 'A API retornou erro $statusCode ao buscar as cotações.';
      case DioExceptionType.cancel:
        return 'A busca de cotações foi cancelada.';
      case DioExceptionType.connectionError:
        return 'Não foi possível conectar à API. Verifique a internet do dispositivo ou emulador.';
      case DioExceptionType.unknown:
        return 'Ocorreu uma falha ao acessar a API de cotações.';
    }
  }
}
