import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;

  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _deleteConfirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name);
    _emailController = TextEditingController(text: user?.email);
    _mobileController = TextEditingController(text: user?.mobile);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _deleteConfirmController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
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
            const Text(
              'ACCOUNT SETTINGS',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage Profile',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                indicator: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: const [
                  Tab(text: 'PROFILE INFORMATION', height: 28),
                  Tab(text: 'UPDATE PASSWORD', height: 28),
                  Tab(text: 'DELETE ACCOUNT', height: 28),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileInfoTab(),
                  _buildPasswordTab(),
                  _buildDeleteAccountTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoTab() {
    final auth = Provider.of<AuthProvider>(context);
    return _buildFormCard(
      title: 'Profile Information',
      subtitle: 'Update your account\'s profile information and email address.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('FULL NAME', _nameController, Icons.person_outline),
          const SizedBox(height: 24),
          _buildTextField('EMAIL ADDRESS', _emailController, Icons.email_outlined),
          const SizedBox(height: 24),
          _buildTextField('MOBILE NUMBER', _mobileController, Icons.phone_android_outlined),
          const SizedBox(height: 40),
          _buildActionButton(
            'SAVE CHANGES',
            isLoading: auth.isLoading,
            onPressed: () async {
              final result = await auth.updateProfile(
                name: _nameController.text,
                email: _emailController.text,
                mobile: _mobileController.text,
              );
              if (result['success']) {
                _showSnackBar('Profile updated successfully');
              } else {
                _showSnackBar(result['message'] ?? 'Update failed', isError: true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTab() {
    final auth = Provider.of<AuthProvider>(context);
    return _buildFormCard(
      title: 'Update Password',
      subtitle: 'Ensure your account is using a long, random password to stay secure.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('CURRENT PASSWORD', _currentPasswordController, Icons.lock_outline, isPassword: true),
          const SizedBox(height: 20),
          _buildTextField('NEW PASSWORD', _passwordController, Icons.lock_reset_rounded, isPassword: true),
          const SizedBox(height: 20),
          _buildTextField('CONFIRM PASSWORD', _confirmPasswordController, Icons.lock_clock_outlined, isPassword: true),
          const SizedBox(height: 40),
          _buildActionButton(
            'UPDATE PASSWORD',
            isLoading: auth.isLoading,
            onPressed: () async {
              if (_passwordController.text != _confirmPasswordController.text) {
                _showSnackBar('Passwords do not match', isError: true);
                return;
              }
              final result = await auth.updatePassword(
                currentPassword: _currentPasswordController.text,
                password: _passwordController.text,
                passwordConfirmation: _confirmPasswordController.text,
              );
              if (result['success']) {
                _showSnackBar('Password changed successfully');
                _currentPasswordController.clear();
                _passwordController.clear();
                _confirmPasswordController.clear();
              } else {
                _showSnackBar(result['message'] ?? 'Update failed', isError: true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountTab() {
    final auth = Provider.of<AuthProvider>(context);
    return _buildFormCard(
      title: 'Delete Account',
      subtitle: 'Permanently delete your account. This action cannot be undone.',
      isDanger: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Once your account is deleted, all of its resources and data will be permanently deleted. Before deleting your account, please download any data or information that you wish to retain.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 30),
          _buildActionButton(
            'DELETE ACCOUNT',
            isDanger: true,
            isLoading: auth.isLoading,
            onPressed: () => _confirmDeleteAccount(),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Account?', style: TextStyle(color: Colors.redAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to delete your account? All your data will be permanently removed. Please enter your password to confirm.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            _buildTextField('PASSWORD', _deleteConfirmController, Icons.lock_outline, isPassword: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final result = await auth.deleteAccount(_deleteConfirmController.text);
              if (result['success']) {
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              } else if (mounted) {
                _showSnackBar(result['message'] ?? 'Deletion failed', isError: true);
              }
            },
            child: const Text('DELETE PERMANENTLY'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required String title, required String subtitle, required Widget child, bool isDanger = false}) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDanger ? Colors.redAccent.withOpacity(0.1) : Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: isDanger ? Colors.redAccent : Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: isDanger ? Colors.redAccent.withOpacity(0.5) : Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
            ),
            const SizedBox(height: 40),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), size: 20),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, {required VoidCallback onPressed, bool isLoading = false, bool isDanger = false}) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDanger ? Colors.redAccent : const Color(0xFFD4AF37),
        foregroundColor: isDanger ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: isLoading 
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
        : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
    );
  }
}
