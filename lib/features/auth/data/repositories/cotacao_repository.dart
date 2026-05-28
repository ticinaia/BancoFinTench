import 'package:dio/dio.dart';
import 'package:banco_fin_tech/features/auth/domain/models/cotacao.dart';
import 'package:banco_fin_tech/core/constants/app_constants.dart';

class CotacaoRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.awesomeApiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
    ),
  );

  Future<List<Cotacao>> getCotacoes() async {
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

      return [
        Cotacao.fromJson(dolar),
        Cotacao.fromJson(euro),
        Cotacao.fromJson(bitcoin),
      ];
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
