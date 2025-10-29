import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';

class PaymentMethodsManagementScreen extends StatefulWidget {
  const PaymentMethodsManagementScreen({super.key});

  @override
  State<PaymentMethodsManagementScreen> createState() => _PaymentMethodsManagementScreenState();
}

class _PaymentMethodsManagementScreenState extends State<PaymentMethodsManagementScreen> {
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: '1',
      name: 'Cash',
      isDefault: true,
    ),
    PaymentMethod(
      id: '2',
      name: 'Credit Card',
    ),
    PaymentMethod(
      id: '3',
      name: 'Debit Card',
    ),
  ];

  void _addPaymentMethod() {
    showDialog(
      context: context,
      builder: (context) => const _PaymentMethodFormDialog(),
    ).then((result) {
      if (result != null && result is PaymentMethod && mounted) {
        setState(() {
          _paymentMethods.add(result);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment method "${result.name}" added')),
        );
      }
    });
  }

  void _editPaymentMethod(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => _PaymentMethodFormDialog(paymentMethod: method),
    ).then((result) {
      if (result != null && result is PaymentMethod && mounted) {
        setState(() {
          final index = _paymentMethods.indexWhere((m) => m.id == method.id);
          if (index != -1) {
            _paymentMethods[index] = result;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment method "${result.name}" updated')),
        );
      }
    });
  }

  void _deletePaymentMethod(PaymentMethod method) {
    // Prevent deleting Cash payment method
    if (method.name == 'Cash') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cash payment method cannot be deleted')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete "${method.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _paymentMethods.remove(method);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment method "${method.name}" deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleDefault(PaymentMethod method) {
    // Prevent changing Cash from being default
    if (method.name == 'Cash') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cash is always the default payment method')),
      );
      return;
    }

    setState(() {
      // Remove default from all other methods
      for (var m in _paymentMethods) {
        if (m.id != method.id) {
          m.isDefault = false;
        }
      }
      // Set this method as default
      method.isDefault = !method.isDefault;
    });

    final action = method.isDefault ? 'set as default' : 'removed as default';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${method.name}" $action')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _addPaymentMethod,
            icon: const Icon(Icons.add),
            tooltip: 'Add Payment Method',
          ),
        ],
      ),
      body: _paymentMethods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No payment methods',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addPaymentMethod,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment Method'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: method.status == PaymentMethodStatus.active
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: method.status == PaymentMethodStatus.active
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          method.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (method.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Status: ${method.statusDisplayName}'),
                        if (method.createdAt != null)
                          Text('Created: ${method.createdAt!.toString().split(' ')[0]}'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editPaymentMethod(method);
                            break;
                          case 'toggle':
                            _toggleDefault(method);
                            break;
                          case 'delete':
                            _deletePaymentMethod(method);
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        final isCash = method.name == 'Cash';
                        return [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          if (!isCash) // Don't show default toggle for Cash
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    method.isDefault ? Icons.star : Icons.star_border,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(method.isDefault ? 'Remove Default' : 'Set as Default'),
                                ],
                              ),
                            ),
                          if (!isCash) // Don't show delete for Cash
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ];
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPaymentMethod,
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add),
        label: const Text('Add Payment Method'),
      ),
    );
  }
}

class _PaymentMethodFormDialog extends StatefulWidget {
  final PaymentMethod? paymentMethod;

  const _PaymentMethodFormDialog({this.paymentMethod});

  @override
  State<_PaymentMethodFormDialog> createState() => _PaymentMethodFormDialogState();
}

class _PaymentMethodFormDialogState extends State<_PaymentMethodFormDialog> {
  late TextEditingController _nameController;
  late PaymentMethodStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.paymentMethod?.name ?? '');
    _selectedStatus = widget.paymentMethod?.status ?? PaymentMethodStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter payment method name')),
      );
      return;
    }

    final method = PaymentMethod(
      id: widget.paymentMethod?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      status: _selectedStatus,
      isDefault: widget.paymentMethod?.isDefault ?? false,
      createdAt: widget.paymentMethod?.createdAt,
    );

    Navigator.pop(context, method);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.paymentMethod == null ? 'Add Payment Method' : 'Edit Payment Method'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Payment Method Name *',
                  border: OutlineInputBorder(),
                  hintText: 'Cash, Credit Card, etc.',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethodStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  border: OutlineInputBorder(),
                ),
                items: PaymentMethodStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}