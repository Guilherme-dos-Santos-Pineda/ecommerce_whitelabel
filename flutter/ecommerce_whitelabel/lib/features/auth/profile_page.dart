import 'package:ecommerce_whitelabel/features/auth/change_password_page.dart';
import 'package:ecommerce_whitelabel/features/auth/edit_profile_page.dart';
import '../../main.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_whitelabel/core/services/api_services.dart';

class ProfilePage extends StatefulWidget {
  final dynamic user;
  final String appName;
  final Color primaryColor;
  final String host;

  const ProfilePage({
    super.key,
    required this.user,
    required this.appName,
    required this.primaryColor,
    required this.host,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;

  void _editProfile() async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          user: widget.user,
          primaryColor: widget.primaryColor,
        ),
      ),
    );

    if (updatedUser != null && mounted) {
      setState(() {
        widget.user['name'] = updatedUser['name'];
        widget.user['email'] = updatedUser['email'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perfil atualizado!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _changePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChangePasswordPage(primaryColor: widget.primaryColor),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Conta', style: TextStyle(color: Colors.red)),
        icon: Icon(Icons.warning, size: 48, color: Colors.orange),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja excluir sua conta?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '• Todos os seus dados serão perdidos\n'
              '• Esta ação não pode ser desfeita\n'
              '• Você precisará criar uma nova conta',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _deleteAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Excluir Conta'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      await ApiService.deleteAccount();

      await ApiService.logout();

      if (mounted) {
        Navigator.pop(context);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(
              host: widget.host,
              appName: widget.appName,
              primaryColor: _colorToHex(widget.primaryColor),
            ),
          ),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Conta excluída com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir conta: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  void _logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sair'),
        content: Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginPage(
              host: widget.host,
              appName: widget.appName,
              primaryColor: _getPrimaryColorHex(),
            ),
          ),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  String _getPrimaryColorHex() {
    if (widget.primaryColor.value == Colors.green.value) {
      return '#1DC55B'; // Verde do devnology
    } else if (widget.primaryColor.value == Colors.purple.value) {
      return '#6B46C1'; // Roxo do in8
    } else {
      return '#${widget.primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meu Perfil'),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.primaryColor.withOpacity(0.1),
                  widget.primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 32, color: Colors.white),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user?['name'] ?? 'Usuário',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.user?['email'] ?? 'email@exemplo.com',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.appName,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildSectionTitle('Conta'),
                _buildProfileOption(
                  icon: Icons.person_outline,
                  title: 'Editar Perfil',
                  subtitle: 'Alterar nome e email',
                  onTap: _editProfile,
                ),
                _buildProfileOption(
                  icon: Icons.lock_outline,
                  title: 'Alterar Senha',
                  subtitle: 'Atualizar senha de acesso',
                  onTap: _changePassword,
                ),

                SizedBox(height: 24),
                _buildSectionTitle('App'),
                _buildProfileOption(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Meus Pedidos',
                  subtitle: 'Histórico de compras',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Em desenvolvimento')),
                    );
                  },
                ),
                _buildProfileOption(
                  icon: Icons.favorite_outline,
                  title: 'Favoritos',
                  subtitle: 'Produtos salvos',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Em desenvolvimento')),
                    );
                  },
                ),

                SizedBox(height: 24),
                _buildSectionTitle('Conta'),
                _buildProfileOption(
                  icon: Icons.logout,
                  title: 'Sair',
                  subtitle: 'Fazer logout da conta',
                  color: Colors.red,
                  onTap: _logout,
                ),
                _buildProfileOption(
                  icon: Icons.delete_outline,
                  title: 'Excluir Conta',
                  subtitle: 'Remover conta permanentemente',
                  color: Colors.red,
                  onTap: _showDeleteConfirmation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? widget.primaryColor),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }
}
