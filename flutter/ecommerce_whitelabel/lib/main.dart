import 'package:ecommerce_whitelabel/core/services/api_services.dart';
import 'package:ecommerce_whitelabel/core/services/cart_service.dart';
import 'package:ecommerce_whitelabel/features/auth/profile_page.dart';
import 'package:ecommerce_whitelabel/features/cart/cart_page.dart';
import 'package:ecommerce_whitelabel/features/products/product_detail_page.dart';
import 'package:ecommerce_whitelabel/features/auth/registerpage.dart';
import 'package:ecommerce_whitelabel/models/favorite_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(WhitelabelApp());
}

class WhitelabelApp extends StatefulWidget {
  const WhitelabelApp({super.key});

  @override
  State<WhitelabelApp> createState() => _WhitelabelAppState();
}

class _WhitelabelAppState extends State<WhitelabelApp> {
  String host = 'devnology.com';
  Map<String, dynamic>? clientData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _detectHostAndLoadClient();
  }

  Future<void> _detectHostAndLoadClient() async {
    String detectedHost = getHost();
    print('🌐 Host detectado: $detectedHost');

    final client = await ApiService.getClientByDomain(detectedHost);

    setState(() {
      host = detectedHost;
      clientData = client;
      isLoading = false;
    });
  }

  String getHost() {
    if (kIsWeb) {
      final uri = Uri.base;
      final host = uri.host;

      if (host == 'localhost') {
        final clientParam = uri.queryParameters['client'];
        if (clientParam == 'devnology') return 'devnology.com';
        if (clientParam == 'in8') return 'in8.com';
        return 'devnology.com';
      }

      if (host == 'devnology.com' || host == 'in8.com') return host;
      return host;
    } else {
      return 'devnology.com';
    }
  }

  ThemeData getTheme() {
    if (clientData != null && clientData!['primaryColor'] != null) {
      final colorHex = clientData!['primaryColor'].replaceAll('#', '');
      final colorValue = int.parse('0xFF$colorHex');
      return ThemeData(
        primaryColor: Color(colorValue),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(colorValue)),
        useMaterial3: true,
        appBarTheme: AppBarTheme(backgroundColor: Color(colorValue)),
      );
    }

    switch (host) {
      case 'devnology.com':
        return ThemeData(
          primarySwatch: Colors.green,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.green),
        );
      case 'in8.com':
        return ThemeData(
          primarySwatch: Colors.purple,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.purple),
        );
      default:
        return ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        );
    }
  }

  String getAppName() {
    return clientData?['name'] ??
        (host == 'devnology.com'
            ? 'Devnology Store'
            : host == 'in8.com'
            ? 'IN8 Store'
            : 'E-commerce Whitelabel');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[400]!, Colors.purple[600]!],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Carregando $host...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '🌐 Detectando configurações',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => CartService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: getTheme(),
        home: LoginPage(
          host: host,
          appName: getAppName(),
          primaryColor: clientData?['primaryColor'],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final String host;
  final String appName;
  final String? primaryColor;

  const LoginPage({
    super.key,
    required this.host,
    required this.appName,
    this.primaryColor,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();

    final credentials = defaultCredentials[widget.host];
    if (credentials != null) {
      _emailController.text = credentials['email']!;
      _passwordController.text = credentials['password']!;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Map<String, Map<String, String>> get defaultCredentials {
    return {
      'devnology.com': {
        'email': 'admin@devnology.com',
        'password': 'devnology123',
        'hint':
            'Em caso de erro use o user default: admin@devnology.com / devnology123',
      },
      'in8.com': {
        'email': 'admin@in8.com',
        'password': 'in8123',
        'hint': 'Em caso de erro use o user default: admin@in8.com / in8123',
      },
    };
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Preencha email e senha');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ProductsPage(
            host: widget.host,
            appName: widget.appName,
            primaryColor: widget.primaryColor,
            user: result['user'],
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getPrimaryColor() {
    if (widget.primaryColor != null) {
      final colorHex = widget.primaryColor!.replaceAll('#', '');
      return Color(int.parse('0xFF$colorHex'));
    }
    return widget.host == 'devnology.com' ? Colors.green : Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();
    final credentials = defaultCredentials[widget.host];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor.withOpacity(0.8), primaryColor],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.shopping_bag_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 24),

                        Text(
                          widget.appName,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Faça login para continuar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),

                        if (credentials != null) ...[
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              credentials['hint']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        SizedBox(height: 32),

                        if (_errorMessage.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[700],
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'seu@email.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        SizedBox(height: 20),

                        // Senha
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            hintText: '••••••••',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: primaryColor,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        SizedBox(height: 32),

                        // Botão Login
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: primaryColor.withOpacity(0.4),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Entrar',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterPage(
                                  host: widget.host,
                                  appName: widget.appName,
                                  primaryColor: widget.primaryColor,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Não tem conta? Cadastre-se',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;

  ProductSearchDelegate(this.onSearch);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSearch(query);
        close(context, query);
      });
    }

    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchSuggestions();
  }

  Widget _buildSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Buscando por: "$query"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Carregando resultados...',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 20),
          CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final List<String> suggestions = [
      'Eletrônicos',
      'Roupas',
      'Esportes',
      'Casa',
      'Beleza',
      'Livros',
    ];

    final filteredSuggestions = query.isEmpty
        ? suggestions
        : suggestions.where((suggestion) {
            return suggestion.toLowerCase().contains(query.toLowerCase());
          }).toList();

    return ListView.builder(
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = filteredSuggestions[index];
        return ListTile(
          leading: Icon(Icons.search, color: Colors.grey[400]),
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        );
      },
    );
  }

  @override
  String get searchFieldLabel => 'Buscar produtos...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }
}

class ProductsPage extends StatefulWidget {
  final String host;
  final String appName;
  final String? primaryColor;
  final dynamic user;

  const ProductsPage({
    super.key,
    required this.host,
    required this.appName,
    this.primaryColor,
    this.user,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<dynamic> products = [];
  List<String> categories = [];
  Map<String, dynamic>? stats;
  bool isLoading = true;

  String searchQuery = '';
  String selectedCategory = 'all';
  String selectedProvider = 'all';
  double minPrice = 0;
  double maxPrice = 2000;
  bool showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadProducts(), _loadCategories(), _loadStats()]);
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      final productsData = await ApiService.getProducts(
        search: searchQuery.isEmpty ? null : searchQuery,
        category: selectedCategory == 'all' ? null : selectedCategory,
        provider: selectedProvider == 'all' ? null : selectedProvider,
        minPrice: minPrice > 0 ? minPrice : null,
        maxPrice: maxPrice < 2000 ? maxPrice : null,
        domain: widget.host,
      );
      setState(() => products = productsData);
    } catch (e) {
      print('❌ Erro: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesData = await ApiService.getCategories(
        domain: widget.host,
      );
      setState(() => categories = ['all', ...categoriesData]);
    } catch (e) {
      print('❌ Erro: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final statsData = await ApiService.getProductsStats(domain: widget.host);
      setState(() => stats = statsData);
    } catch (e) {
      print('❌ Erro: $e');
    }
  }

  void _applyFilters() {
    _loadProducts();
    setState(() => showFilters = false);
  }

  void _resetFilters() {
    setState(() {
      searchQuery = '';
      selectedCategory = 'all';
      selectedProvider = 'all';
      minPrice = 0;
      maxPrice = 2000;
    });
    _loadProducts();
  }

  Color _getPrimaryColor() {
    if (widget.primaryColor != null) {
      final colorHex = widget.primaryColor!.replaceAll('#', '');
      return Color(int.parse('0xFF$colorHex'));
    }
    return widget.host == 'devnology.com' ? Colors.green : Colors.purple;
  }

  bool get _hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedCategory != 'all' ||
      selectedProvider != 'all' ||
      minPrice > 0 ||
      maxPrice < 2000;

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(primaryColor, context),
          SliverToBoxAdapter(child: _buildStatsHeader(primaryColor, isDark)),
          if (_hasActiveFilters)
            SliverToBoxAdapter(child: _buildActiveFiltersChips(primaryColor)),
          if (showFilters)
            SliverToBoxAdapter(child: _buildFiltersPanel(primaryColor, isDark)),
          isLoading
              ? SliverFillRemaining(child: _buildLoadingState())
              : products.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : _buildProductsGrid(primaryColor, isDark),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(primaryColor, context),
    );
  }

  Widget _buildSliverAppBar(Color primaryColor, BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.appName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      actions: [
        // ÍCONE DO CARRINHO COM BADGE
        Consumer<CartService>(
          builder: (context, cartService, child) {
            final totalItems = cartService.totalItems;
            return Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CartPage()),
                    );
                  },
                ),
                if (totalItems > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        totalItems.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.search, color: Colors.white),
          onPressed: () {
            showSearch<String>(
              context: context,
              delegate: ProductSearchDelegate((query) {
                setState(() {
                  searchQuery = query;
                  _loadProducts();
                });
              }),
            ).then((result) {
              if (result == null || result.isEmpty) {
                setState(() {
                  searchQuery = '';
                  _loadProducts();
                });
              }
            });
          },
        ),
        IconButton(
          icon: Icon(
            showFilters ? Icons.filter_alt_off : Icons.filter_alt,
            color: Colors.white,
          ),
          onPressed: () => setState(() => showFilters = !showFilters),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'profile') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    user: widget.user,
                    appName: widget.appName,
                    primaryColor: primaryColor,
                    host: widget.host,
                  ),
                ),
              );
            } else if (value == 'logout') {
              ApiService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(
                    host: widget.host,
                    appName: widget.appName,
                    primaryColor: widget.primaryColor,
                  ),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 8),
                  Text('Meu Perfil'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text('Sair'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsHeader(Color primaryColor, bool isDark) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catálogo Completo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    if (stats != null)
                      Text(
                        '${stats!['total']} produtos disponíveis',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (stats != null) ...[
            SizedBox(height: 16),
            Row(
              children: [
                _buildStatBadge(
                  '🇧🇷 ${stats!['providers']['brazilian'] ?? 0}',
                  primaryColor,
                ),
                SizedBox(width: 8),
                _buildStatBadge(
                  '🇪🇺 ${stats!['providers']['european'] ?? 0}',
                  primaryColor,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (searchQuery.isNotEmpty)
            _buildFilterChip('🔍 $searchQuery', primaryColor, () {
              setState(() => searchQuery = '');
              _loadProducts();
            }),
          if (selectedCategory != 'all')
            _buildFilterChip('📁 $selectedCategory', primaryColor, () {
              setState(() => selectedCategory = 'all');
              _loadProducts();
            }),
          if (selectedProvider != 'all')
            _buildFilterChip(
              selectedProvider == 'brazilian'
                  ? '🇧🇷 Brasileiro'
                  : '🇪🇺 Europeu',
              primaryColor,
              () {
                setState(() => selectedProvider = 'all');
                _loadProducts();
              },
            ),
          if (minPrice > 0 || maxPrice < 2000)
            _buildFilterChip(
              '💰 R\$ ${minPrice.toInt()}-${maxPrice.toInt()}',
              primaryColor,
              () {
                setState(() {
                  minPrice = 0;
                  maxPrice = 2000;
                });
                _loadProducts();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color, VoidCallback onDelete) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      backgroundColor: color.withOpacity(0.15),
      deleteIconColor: color,
      onDeleted: onDelete,
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildFiltersPanel(Color primaryColor, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros Avançados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          SizedBox(height: 20),
          _buildDropdownFilter(
            'Categoria',
            selectedCategory,
            categories
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c == 'all' ? 'Todas' : c),
                  ),
                )
                .toList(),
            (value) => setState(() => selectedCategory = value!),
            isDark,
          ),
          SizedBox(height: 16),
          _buildDropdownFilter(
            'Fornecedor',
            selectedProvider,
            [
              DropdownMenuItem(value: 'all', child: Text('Todos')),
              DropdownMenuItem(
                value: 'brazilian',
                child: Text('🇧🇷 Brasileiro'),
              ),
              DropdownMenuItem(value: 'european', child: Text('🇪🇺 Europeu')),
            ],
            (value) => setState(() => selectedProvider = value!),
            isDark,
          ),
          SizedBox(height: 20),
          Text(
            'Faixa de Preço: R\$ ${minPrice.toInt()} - R\$ ${maxPrice.toInt()}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[700],
            ),
          ),
          RangeSlider(
            values: RangeValues(minPrice as double, maxPrice as double),
            min: 0,
            max: 2000,
            divisions: 20,
            activeColor: primaryColor,
            onChanged: (values) {
              setState(() {
                minPrice = values.start as double;
                maxPrice = values.end as double;
              });
            },
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _applyFilters,
                  icon: Icon(Icons.check),
                  label: Text('Aplicar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: Icon(Icons.clear),
                label: Text('Limpar'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<DropdownMenuItem<String>> items,
    void Function(String?) onChanged,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark ? Colors.grey[800] : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.grey[800]),
              onChanged: (newValue) {
                if (newValue != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onChanged(newValue);
                  });
                }
              },
              items: items,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Carregando produtos...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey[300]),
          SizedBox(height: 20),
          Text(
            'Nenhum produto encontrado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Tente ajustar os filtros',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _resetFilters,
            icon: Icon(Icons.refresh),
            label: Text('Limpar Filtros'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(Color primaryColor, bool isDark) {
    return SliverPadding(
      padding: EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return ProductCard(
            product: products[index],
            primaryColor: primaryColor,
            isDark: isDark,
          );
        }, childCount: products.length),
      ),
    );
  }

  Widget _buildFloatingActionButton(Color primaryColor, BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        return FloatingActionButton.extended(
          onPressed: () {
            if (cartService.cartItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Seu carrinho está vazio'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            }
          },
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 6,
          icon: Icon(Icons.shopping_cart),
          label: Text(
            'Carrinho (${cartService.totalItems})',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}

class ProductCard extends StatefulWidget {
  final dynamic product;
  final Color primaryColor;
  final bool isDark;

  const ProductCard({
    super.key,
    required this.product,
    required this.primaryColor,
    this.isDark = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔧 HELPER: Converte para string com segurança
  String _toString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  // 🔧 HELPER: Converte para double com segurança
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);

    final price = _toDouble(widget.product['price']);
    final hasDiscount = widget.product['hasDiscount'] == true;
    final discountValue = _toDouble(widget.product['discountValue']);
    final finalPrice = hasDiscount ? price * (1 - discountValue) : price;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                product: widget.product,
                primaryColor: widget.primaryColor,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            _toString(widget.product['image']) ??
                                'https://via.placeholder.com/150',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  if (hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red, Colors.red[700]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          '-${(discountValue * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Botão de favorito usando o CartService
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Consumer<CartService>(
                      builder: (context, cartService, child) {
                        final isFavorite = cartService.isFavorite(
                          _toString(widget.product['id']),
                        );
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: isFavorite ? Colors.red : Colors.grey[600],
                            ),
                            onPressed: () {
                              final favoriteItem = FavoriteItem(
                                id: 'fav_${_toString(widget.product['id'])}',
                                productId: _toString(widget.product['id']),
                                name: _toString(
                                  widget.product['name'] ?? 'Produto sem nome',
                                ),
                                price: price,
                                image: _toString(
                                  widget.product['image'] ??
                                      'https://via.placeholder.com/150',
                                ),
                                provider: _toString(
                                  widget.product['provider'] ?? 'unknown',
                                ),
                                hasDiscount: hasDiscount,
                                originalPrice: _toDouble(
                                  widget.product['originalPrice'],
                                ),
                                discountPercentage: (discountValue * 100)
                                    .toInt(),
                              );
                              cartService.toggleFavorite(favoriteItem);
                            },
                            padding: EdgeInsets.all(6),
                            constraints: BoxConstraints(),
                          ),
                        );
                      },
                    ),
                  ),

                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        _toString(widget.product['provider']) == 'brazilian'
                            ? '🇧🇷'
                            : '🇪🇺',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _toString(widget.product['category']) ?? 'Geral',
                          style: TextStyle(
                            fontSize: 9,
                            color: widget.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      SizedBox(height: 6),
                      Text(
                        _toString(widget.product['name']) ?? 'Sem nome',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: widget.isDark
                              ? Colors.white
                              : Colors.grey[800],
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Spacer(),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              'R\$ ${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                                fontSize: 10,
                              ),
                            ),
                          Text(
                            'R\$ ${finalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: widget.primaryColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
