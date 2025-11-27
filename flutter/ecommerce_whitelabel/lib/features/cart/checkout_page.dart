// pages/checkout_page.dart
import 'package:ecommerce_whitelabel/models/cart_model.dart';
import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutPage({super.key, required this.cartItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();

  String _paymentMethod = 'credit_card';
  bool _isProcessing = false;

  double get totalPrice =>
      widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _processOrder() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      // Simular processamento
      Future.delayed(Duration(seconds: 2), () {
        setState(() => _isProcessing = false);
        _showSuccessDialog();
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Pedido Confirmado!'),
          ],
        ),
        content: Text(
          'Seu pedido foi realizado com sucesso! Você receberá um email de confirmação.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text('Voltar à Loja'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Finalizar Pedido')),
      body: _isProcessing ? _buildProcessing() : _buildCheckoutForm(),
    );
  }

  Widget _buildProcessing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Processando seu pedido...'),
        ],
      ),
    );
  }

  Widget _buildCheckoutForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo do Pedido
            _buildOrderSummary(),
            SizedBox(height: 24),

            // Dados Pessoais
            _buildPersonalInfo(),
            SizedBox(height: 24),

            // Endereço
            _buildAddressInfo(),
            SizedBox(height: 24),

            // Pagamento
            _buildPaymentInfo(),
            SizedBox(height: 32),

            // Botão Finalizar
            _buildCheckoutButton(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do Pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...widget.cartItems.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        image: DecorationImage(
                          image: NetworkImage(item.image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.name}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      'R\$ ${item.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'R\$ ${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dados Pessoais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nome Completo'),
              validator: (value) => value!.isEmpty ? 'Digite seu nome' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) => value!.isEmpty ? 'Digite seu email' : null,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Telefone'),
              validator: (value) =>
                  value!.isEmpty ? 'Digite seu telefone' : null,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Endereço de Entrega',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Endereço'),
              validator: (value) =>
                  value!.isEmpty ? 'Digite seu endereço' : null,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(labelText: 'Cidade'),
                    validator: (value) =>
                        value!.isEmpty ? 'Digite sua cidade' : null,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _zipCodeController,
                    decoration: InputDecoration(labelText: 'CEP'),
                    validator: (value) =>
                        value!.isEmpty ? 'Digite o CEP' : null,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forma de Pagamento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ..._buildPaymentOptions(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPaymentOptions() {
    final List<Map<String, dynamic>> options = [
      {
        'value': 'credit_card',
        'label': 'Cartão de Crédito',
        'icon': Icons.credit_card,
      },
      {
        'value': 'debit_card',
        'label': 'Cartão de Débito',
        'icon': Icons.credit_card,
      },
      {'value': 'pix', 'label': 'PIX', 'icon': Icons.qr_code},
      {'value': 'boleto', 'label': 'Boleto Bancário', 'icon': Icons.receipt},
    ];

    return options
        .map(
          (option) => RadioListTile<String>(
            value: option['value'] as String,
            groupValue: _paymentMethod,
            onChanged: (value) => setState(() => _paymentMethod = value!),
            title: Row(
              children: [
                Icon(option['icon'] as IconData, size: 20),
                SizedBox(width: 8),
                Text(option['label'] as String),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildCheckoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _processOrder,
        child: Text(
          'CONFIRMAR PEDIDO - R\$ ${totalPrice.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
