import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth_provider.dart';
import '../../core/tax_provider.dart';
import '../../models/tax_model.dart';

class TaxationScreen extends StatefulWidget {
  const TaxationScreen({super.key});

  @override
  State<TaxationScreen> createState() => _TaxationScreenState();
}

class _TaxationScreenState extends State<TaxationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token != null) {
      Provider.of<TaxProvider>(context, listen: false).fetchTaxGroups(auth.token!);
    }
  }

  void _showTaxGroupForm([TaxGroupModel? group]) {
    showDialog(
      context: context,
      builder: (context) => TaxGroupForm(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PREFERENCES',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Taxation Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showTaxGroupForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Tax Group'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Consumer<TaxProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.taxGroups.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                  }

                  if (provider.taxGroups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 64, color: Colors.white.withOpacity(0.05)),
                          const SizedBox(height: 16),
                          const Text(
                            'No tax groups found. Create one to get started.',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisExtent: 220,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: provider.taxGroups.length,
                    itemBuilder: (context, index) {
                      final group = provider.taxGroups[index];
                      return _buildTaxGroupCard(group);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxGroupCard(TaxGroupModel group) {
    final double totalPercentage = group.taxes.fold(0, (sum, t) => sum + t.percentage);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      group.isInclusive ? 'Inclusive of Tax' : 'Exclusive of Tax',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: group.isActive,
                onChanged: (val) {
                  Provider.of<TaxProvider>(context, listen: false).toggleTaxGroupStatus(auth.token!, group);
                },
                activeThumbColor: const Color(0xFFD4AF37),
              ),
            ],
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.taxes.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${t.name}: ${t.percentage}%',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${totalPercentage.toStringAsFixed(2)}%',
                style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Outfit'),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showTaxGroupForm(group),
                    icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.white38),
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(group),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(TaxGroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D21),
        title: const Text('Delete Tax Group'),
        content: Text('Are you sure you want to delete "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final success = await Provider.of<TaxProvider>(context, listen: false).removeTaxGroup(auth.token!, group.id);
              if (mounted) Navigator.pop(context);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete tax group')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class TaxGroupForm extends StatefulWidget {
  final TaxGroupModel? group;
  const TaxGroupForm({super.key, this.group});

  @override
  State<TaxGroupForm> createState() => _TaxGroupFormState();
}

class _TaxGroupFormState extends State<TaxGroupForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  bool _isActive = true;
  bool _isInclusive = false;
  List<Map<String, dynamic>> _taxes = [];

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _isActive = widget.group!.isActive;
      _isInclusive = widget.group!.isInclusive;
      _taxes = widget.group!.taxes.map((t) => {
        'id': t.id,
        'nameController': TextEditingController(text: t.name),
        'percentController': TextEditingController(text: t.percentage.toString()),
      }).toList();
    } else {
      _addTaxRow();
    }
  }

  void _addTaxRow() {
    setState(() {
      _taxes.add({
        'nameController': TextEditingController(),
        'percentController': TextEditingController(),
      });
    });
  }

  void _removeTaxRow(int index) {
    if (_taxes.length > 1) {
      setState(() {
        _taxes.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16181D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.group == null ? 'Create Tax Group' : 'Edit Tax Group',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Group Name (e.g., GST 5%)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSwitchTile(
                      'Inclusive of Tax',
                      'Tax is included in product price',
                      _isInclusive,
                      (val) => setState(() => _isInclusive = val),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildSwitchTile(
                      'Status',
                      'Active or Deactive',
                      _isActive,
                      (val) => setState(() => _isActive = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Taxes', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1)),
                  TextButton.icon(
                    onPressed: _addTaxRow,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Tax'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFD4AF37)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _taxes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _taxes[index]['nameController'],
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDecoration('Tax Name (e.g., CGST)'),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _taxes[index]['percentController'],
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _inputDecoration('Percentage %'),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeTaxRow(index),
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Framework', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final List<Map<String, dynamic>> taxList = [];
    for (var tax in _taxes) {
      final data = {
        'name': tax['nameController'].text,
        'percentage': double.parse(tax['percentController'].text),
      };
      if (tax['id'] != null) data['id'] = tax['id'];
      taxList.add(data);
    }

    final Map<String, dynamic> taxGroupData = {
      'name': _nameController.text,
      'is_active': _isActive,
      'is_inclusive': _isInclusive,
      'taxes': taxList,
    };

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<TaxProvider>(context, listen: false);

    bool success;
    if (widget.group == null) {
      success = await provider.addTaxGroup(auth.token!, taxGroupData);
    } else {
      success = await provider.editTaxGroup(auth.token!, widget.group!.id, taxGroupData);
    }

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'An error occurred')));
    }
  }
}
