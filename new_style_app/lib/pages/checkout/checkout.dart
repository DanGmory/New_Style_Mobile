import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  bool _isProcessing = false;

  // Formulario de envío
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  // Datos de pago
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  String? _selectedShippingMethod;
  String? _selectedPaymentMethod = 'credit_card';

  final double _subtotal = 250.50;
  final double _shippingCost = 10.00;
  late double _total;

  @override
  void initState() {
    super.initState();
    _selectedShippingMethod = 'standard';
    _calculateTotal();
  }

  void _calculateTotal() {
    final shipping =
        _selectedShippingMethod == 'express' ? 25.00 : _shippingCost;
    _total = _subtotal + shipping;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _continueStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _processPayment();
    }
  }

  void _cancelStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isProcessing = false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/simple-thank-you');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: isMobile
          ? _buildMobileCheckout(context)
          : _buildDesktopCheckout(context),
    );
  }

  Widget _buildMobileCheckout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Indicador de pasos
          _buildStepsIndicator(),
          const SizedBox(height: 24),

          // Contenido del paso actual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStepContent(),
          ),
          const SizedBox(height: 24),

          // Resumen del pedido
          _buildOrderSummary(),
          const SizedBox(height: 24),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildActionButtons(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDesktopCheckout(BuildContext context) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildStepsIndicator(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildStepContent(),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildActionButtons(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Resumen del pedido (sidebar)
        Container(
          width: 300,
          color: Colors.grey[50],
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen del Pedido',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildOrderSummaryDetails(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepsIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStepCircle(0, 'Envío'),
          Container(
            height: 2,
            width: 50,
            color: _currentStep >= 1 ? Colors.blue : Colors.grey[300],
          ),
          _buildStepCircle(1, 'Pago'),
          Container(
            height: 2,
            width: 50,
            color: _currentStep >= 2 ? Colors.blue : Colors.grey[300],
          ),
          _buildStepCircle(2, 'Revisar'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? Colors.blue : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blue : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildShippingStep();
      case 1:
        return _buildPaymentStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildShippingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de Envío',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(_nameController, 'Nombre Completo', Icons.person),
        _buildTextField(_emailController, 'Correo Electrónico', Icons.email),
        _buildTextField(_phoneController, 'Teléfono', Icons.phone),
        _buildTextField(_addressController, 'Dirección', Icons.location_on),
        Row(
          children: [
            Expanded(
              child: _buildTextField(_cityController, 'Ciudad', Icons.location_city),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(_zipController, 'Código Postal', Icons.mail),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Método de Envío',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildShippingOption(
          'standard',
          'Envío Estándar',
          'Entrega en 5-7 días',
          '\$${_shippingCost.toStringAsFixed(2)}',
        ),
        _buildShippingOption(
          'express',
          'Envío Express',
          'Entrega en 1-2 días',
          '\$25.00',
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de Pago',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodOption(
          'credit_card',
          'Tarjeta de Crédito',
          Icons.credit_card,
        ),
        _buildPaymentMethodOption(
          'paypal',
          'PayPal',
          Icons.payment,
        ),
        _buildPaymentMethodOption(
          'bank_transfer',
          'Transferencia Bancaria',
          Icons.account_balance,
        ),
        const SizedBox(height: 24),
        if (_selectedPaymentMethod == 'credit_card') ...[
          _buildTextField(_cardNumberController, 'Número de Tarjeta', Icons.credit_card),
          Row(
            children: [
              Expanded(
                child: _buildTextField(_cardNameController, 'Titular', Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(_expiryController, 'MM/YY', Icons.calendar_today),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(_cvvController, 'CVV', Icons.security),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revisar Pedido',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildReviewSection('Información de Envío', [
          _buildReviewItem('Nombre', _nameController.text),
          _buildReviewItem('Correo', _emailController.text),
          _buildReviewItem('Teléfono', _phoneController.text),
          _buildReviewItem('Dirección', _addressController.text),
          _buildReviewItem('Ciudad', _cityController.text),
        ]),
        const SizedBox(height: 24),
        _buildReviewSection('Método de Pago', [
          _buildReviewItem(
            'Pago',
            _selectedPaymentMethod == 'credit_card'
                ? 'Tarjeta de Crédito'
                : _selectedPaymentMethod == 'paypal'
                    ? 'PayPal'
                    : 'Transferencia Bancaria',
          ),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Acepto los términos y condiciones',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Al confirmar esta compra, acepto los términos de servicio y política de privacidad.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildShippingOption(
    String value,
    String title,
    String subtitle,
    String price,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedShippingMethod = value;
            _calculateTotal();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedShippingMethod == value
                  ? Colors.blue
                  : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _selectedShippingMethod == value
                ? Colors.blue.shade50
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() => _selectedPaymentMethod = value);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  _selectedPaymentMethod == value ? Colors.blue : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _selectedPaymentMethod == value
                ? Colors.blue.shade50
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: _selectedPaymentMethod == value ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: _selectedPaymentMethod == value
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (_selectedPaymentMethod == value)
                const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _buildOrderSummaryDetails(),
    );
  }

  Widget _buildOrderSummaryDetails() {
    return Column(
      children: [
        _buildSummaryRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _buildSummaryRow(
          'Envío',
          '\$${(_selectedShippingMethod == "express" ? 25.00 : _shippingCost).toStringAsFixed(2)}',
        ),
        Divider(color: Colors.grey[400]),
        const SizedBox(height: 8),
        _buildSummaryRow(
          'Total',
          '\$${_total.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : _cancelStep,
              child: const Text('Atrás'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _continueStep,
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_currentStep == 2 ? 'Confirmar Compra' : 'Continuar'),
          ),
        ),
      ],
    );
  }
}
