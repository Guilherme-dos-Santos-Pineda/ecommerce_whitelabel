import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Service principal para comunicação com a API
///
/// Gerencia autenticação, requisições HTTP e cache de dados
class ApiService {
  // Configurações
  static const String _tokenKey = 'auth_token';
  static const Duration _defaultTimeout = Duration(seconds: 10);
  static const Duration _shortTimeout = Duration(seconds: 5);

  // Estado
  static String? _authToken;
  static SharedPreferences? _prefs;

  // Cache simples
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// URL base dinâmica baseada na plataforma
  static String get baseUrl {
    if (kIsWeb) {
      // Web: localhost ou domínio de produção
      return const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://localhost:3000',
      );
    } else {
      // Mobile: IP local para emulador/dispositivo
      return const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://10.0.2.2:3000', // Android emulator
      );
    }
  }

  /// Token de autenticação atual
  static String? get authToken => _authToken;

  /// Verifica se está autenticado
  static bool get isAuthenticated => _authToken != null;

  // ========== INICIALIZAÇÃO ==========

  /// Inicializa o service carregando preferências e token
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _authToken = _prefs?.getString(_tokenKey);

      _log('✅ ApiService inicializado');
      _log('🌐 Base URL: $baseUrl');
      _log('🔑 Token presente: ${_authToken != null}');

      if (_authToken != null) {
        _log('🔑 Token: ${_authToken!.substring(0, 20)}...');
      }
    } catch (e) {
      _logError('Erro ao inicializar ApiService', e);
    }
  }

  // ========== AUTENTICAÇÃO ==========

  /// Realiza login e armazena o token
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      _log('🔐 Tentando login: $email');

      final response = await _post(
        '/auth/login',
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );

      // Extrai e salva o token
      _authToken = response['access_token'];
      if (_authToken != null) {
        await _prefs?.setString(_tokenKey, _authToken!);
        _log('✅ Login bem-sucedido! Token salvo.');
      }

      return response;
    } catch (e) {
      _logError('Erro no login', e);
      rethrow;
    }
  }

  /// Realiza logout e limpa o token
  static Future<void> logout() async {
    try {
      _log('🚪 Realizando logout...');

      _authToken = null;
      await _prefs?.remove(_tokenKey);
      _clearCache();

      _log('✅ Logout concluído');
    } catch (e) {
      _logError('Erro ao fazer logout', e);
    }
  }

  /// Valida se o token atual é válido
  static Future<bool> validateToken() async {
    if (_authToken == null) return false;

    try {
      await _get('/clients/domain/devnology.com');
      return true;
    } catch (e) {
      _log('❌ Token inválido');
      return false;
    }
  }

  // ========== CLIENTES ==========

  /// Busca dados de um cliente pelo domínio
  static Future<Map<String, dynamic>?> getClientByDomain(String domain) async {
    try {
      _log('🏪 Buscando cliente: $domain');

      final cacheKey = 'client_$domain';
      if (_isCacheValid(cacheKey)) {
        _log('💾 Retornando do cache');
        return _cache[cacheKey];
      }

      final response = await _get('/clients/domain/$domain');

      _cache[cacheKey] = response;
      _cacheTimestamps[cacheKey] = DateTime.now();

      _log('✅ Cliente encontrado: ${response['name']}');
      return response;
    } catch (e) {
      _logError('Erro ao buscar cliente', e);
      return null;
    }
  }

  // ========== PRODUTOS ==========

  /// Busca produtos com filtros opcionais
  static Future<List<dynamic>> getProducts({
    String? search,
    String? category,
    String? provider,
    dynamic? minPrice,
    dynamic? maxPrice,
    required String domain,
  }) async {
    try {
      _log('🛍️ Buscando produtos');
      _log(
        '🔍 Filtros: search=$search, category=$category, provider=$provider',
      );

      final queryParams = <String, String>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category != 'all') 'category': category,
        if (provider != null && provider != 'all') 'provider': provider,
        if (minPrice != null) 'minPrice': minPrice.toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      };

      final response = await _get(
        '/products',
        queryParams: queryParams,
        headers: {'x-client-domain': domain},
      );

      _log('✅ ${response.length} produtos carregados');
      return response;
    } catch (e) {
      _logError('Erro ao buscar produtos', e);
      return [];
    }
  }

  /// Busca um produto específico pelo ID
  static Future<Map<String, dynamic>?> getProductById(
    String id, {
    required String domain,
  }) async {
    try {
      _log('🔍 Buscando produto ID: $id');

      final cacheKey = 'product_$id';
      if (_isCacheValid(cacheKey)) {
        _log('💾 Retornando do cache');
        return _cache[cacheKey];
      }

      final response = await _get(
        '/products/$id',
        headers: {'x-client-domain': domain},
      );

      _cache[cacheKey] = response;
      _cacheTimestamps[cacheKey] = DateTime.now();

      _log('✅ Produto encontrado');
      return response;
    } catch (e) {
      _logError('Erro ao buscar produto', e);
      return null;
    }
  }

  /// Busca produtos por categoria
  static Future<List<dynamic>> getProductsByCategory(
    String category, {
    required String domain,
  }) async {
    try {
      _log('📁 Buscando produtos da categoria: $category');

      final response = await _get(
        '/products/category/${Uri.encodeComponent(category)}',
        headers: {'x-client-domain': domain},
      );

      _log('✅ ${response.length} produtos encontrados');
      return response;
    } catch (e) {
      _logError('Erro ao buscar produtos por categoria', e);
      return [];
    }
  }

  /// Busca todas as categorias disponíveis
  static Future<List<String>> getCategories({required String domain}) async {
    try {
      _log('📂 Buscando categorias');

      final cacheKey = 'categories_$domain';
      if (_isCacheValid(cacheKey)) {
        _log('💾 Retornando do cache');
        return List<String>.from(_cache[cacheKey]);
      }

      final response = await _get(
        '/products/categories',
        headers: {'x-client-domain': domain},
      );

      final categories = List<String>.from(response);

      _cache[cacheKey] = categories;
      _cacheTimestamps[cacheKey] = DateTime.now();

      _log('✅ ${categories.length} categorias carregadas');
      return categories;
    } catch (e) {
      _logError('Erro ao buscar categorias', e);
      return [];
    }
  }

  /// Busca estatísticas dos produtos
  static Future<Map<String, dynamic>?> getProductsStats({
    required String domain,
  }) async {
    try {
      _log('📊 Buscando estatísticas de produtos');

      final cacheKey = 'stats_$domain';
      if (_isCacheValid(cacheKey)) {
        _log('💾 Retornando do cache');
        return _cache[cacheKey];
      }

      final response = await _get(
        '/products/stats',
        headers: {'x-client-domain': domain},
      );

      _cache[cacheKey] = response;
      _cacheTimestamps[cacheKey] = DateTime.now();

      _log('✅ Estatísticas carregadas');
      return response;
    } catch (e) {
      _logError('Erro ao buscar estatísticas', e);
      return null;
    }
  }

  // ========== UTILIDADES ==========

  /// Testa a conexão com a API
  static Future<bool> testConnection() async {
    try {
      _log('🔍 Testando conexão com: $baseUrl');

      await _get('/clients/domain/devnology.com', timeout: _shortTimeout);

      _log('✅ Conexão bem-sucedida');
      return true;
    } catch (e) {
      _log('❌ Falha na conexão');
      return false;
    }
  }

  /// Limpa todo o cache
  static void clearCache() {
    _clearCache();
    _log('🗑️ Cache limpo');
  }

  // ========== MÉTODOS HTTP PRIVADOS ==========

  /// Realiza requisição GET
  static Future<dynamic> _get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration? timeout,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final requestHeaders = await _buildHeaders(headers, requiresAuth);

    try {
      final response = await http
          .get(uri, headers: requestHeaders)
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Realiza requisição POST
  static Future<dynamic> _post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(endpoint);
    final requestHeaders = await _buildHeaders(headers, requiresAuth);

    try {
      final response = await http
          .post(uri, headers: requestHeaders, body: json.encode(body))
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Adicione estes métodos no ApiService:

  /// Registra um novo usuário
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String domain,
  }) async {
    try {
      _log('👤 Registrando novo usuário: $email');

      // Primeiro busca o clientId pelo domínio
      final client = await getClientByDomain(domain);
      if (client == null) {
        throw ApiException(0, 'Domínio não encontrado');
      }

      final response = await _post(
        '/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'clientId': client['id'],
        },
        requiresAuth: false,
      );

      _log('✅ Usuário registrado com sucesso');
      return response;
    } catch (e) {
      _logError('Erro no registro', e);
      rethrow;
    }
  }

  /// Solicita redefinição de senha
  static Future<void> forgotPassword(String email) async {
    try {
      _log('🔐 Solicitando redefinição de senha para: $email');

      await _post(
        '/auth/forgot-password',
        body: {'email': email},
        requiresAuth: false,
      );

      _log('✅ Email de redefinição enviado');
    } catch (e) {
      _logError('Erro ao solicitar redefinição', e);
      rethrow;
    }
  }

  /// Redefine a senha com token
  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      _log('🔄 Redefinindo senha');

      await _post(
        '/auth/reset-password',
        body: {'token': token, 'newPassword': newPassword},
        requiresAuth: false,
      );

      _log('✅ Senha redefinida com sucesso');
    } catch (e) {
      _logError('Erro ao redefinir senha', e);
      rethrow;
    }
  }

  /// Atualiza perfil do usuário
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      _log('📝 Atualizando perfil: $name, $email');

      final response = await _put(
        '/auth/profile',
        body: {'name': name, 'email': email},
      );

      _log('✅ Perfil atualizado com sucesso');
      return response;
    } catch (e) {
      _logError('Erro ao atualizar perfil', e);
      rethrow;
    }
  }

  /// Exclui conta do usuário
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      _log('🗑️ Excluindo conta');

      final response = await _delete('/auth/account');

      _log('✅ Conta excluída com sucesso');
      return response;
    } catch (e) {
      _logError('Erro ao excluir conta', e);
      rethrow;
    }
  }

  /// Realiza requisição PUT
  static Future<dynamic> _put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(endpoint);
    final requestHeaders = await _buildHeaders(headers, requiresAuth);

    try {
      final response = await http
          .put(uri, headers: requestHeaders, body: json.encode(body))
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Realiza requisição DELETE
  static Future<dynamic> _delete(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(endpoint);
    final requestHeaders = await _buildHeaders(headers, requiresAuth);

    try {
      final response = await http
          .delete(uri, headers: requestHeaders)
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========== HELPERS ==========

  /// Constrói URI completa
  static Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final url = '$baseUrl$endpoint';
    return queryParams != null
        ? Uri.parse(url).replace(queryParameters: queryParams)
        : Uri.parse(url);
  }

  /// Constrói headers da requisição
  static Future<Map<String, String>> _buildHeaders(
    Map<String, String>? customHeaders,
    bool requiresAuth,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?customHeaders,
    };

    // Adiciona token de autenticação se necessário
    if (requiresAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Processa resposta HTTP
  static dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Sucesso
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;

      try {
        return json.decode(response.body);
      } catch (e) {
        return response.body;
      }
    }

    // Erro
    String errorMessage;
    try {
      final errorBody = json.decode(response.body);
      errorMessage =
          errorBody['message'] ?? errorBody['error'] ?? 'Erro desconhecido';
    } catch (_) {
      errorMessage = 'Erro HTTP $statusCode';
    }

    throw ApiException(statusCode, errorMessage);
  }

  /// Trata erros de requisição
  static Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }

    String message;

    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Failed host lookup')) {
      message =
          'Não foi possível conectar à API.\n\n'
          '✅ Verifique se a API está rodando\n'
          '✅ Verifique sua conexão com a internet\n'
          '✅ URL: $baseUrl';
    } else if (error.toString().contains('TimeoutException')) {
      message =
          'Tempo limite excedido.\n\n'
          'A API está demorando muito para responder.';
    } else {
      message = 'Erro de conexão: ${error.toString()}';
    }

    return ApiException(0, message);
  }

  /// Verifica se o cache é válido
  static bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;

    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    return difference < _cacheExpiration;
  }

  /// Limpa o cache
  static void _clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Log de debug
  static void _log(String message) {
    if (kDebugMode) {
      print('[ApiService] $message');
    }
  }

  /// Log de erro
  static void _logError(String message, dynamic error) {
    if (kDebugMode) {
      print('[ApiService] ❌ $message: $error');
    }
  }
}

/// Exceção personalizada para erros de API
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Configuração de debug para kDebugMode
const bool kDebugMode = !bool.fromEnvironment('dart.vm.product');
