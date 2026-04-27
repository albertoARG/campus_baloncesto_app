import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/tablon_providers.dart';
import '../../../../core/services/notification_service.dart';

class CreateTablonPostScreen extends ConsumerStatefulWidget {
  const CreateTablonPostScreen({super.key});

  @override
  ConsumerState<CreateTablonPostScreen> createState() => _CreateTablonPostScreenState();
}

class _CreateTablonPostScreenState extends ConsumerState<CreateTablonPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  bool _isStaffOnly = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No autenticado');
      
      await ref.read(tablonRepositoryProvider).createPost(
        _titleController.text.trim(), 
        _contentController.text.trim(), 
        user.id,
        isStaffOnly: _isStaffOnly,
      );
      
      // Send push notification to all relevant devices
      await ref.read(notificationServiceProvider).sendNotificationToTopic(
        title: _isStaffOnly ? '📋 Aviso Staff' : '📢 Nuevo Aviso',
        body: _titleController.text.trim(),
        isStaffOnly: _isStaffOnly,
      );
      
      ref.invalidate(tablonPostsProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aviso publicado')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Aviso')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título corto (ej: Llevad bañador)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Cuerpo del mensaje',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Solo para Staff (Admins/Entrenadores)'),
                subtitle: const Text('Este aviso no será visible para alumnos ni familias'),
                value: _isStaffOnly,
                activeThumbColor: Colors.orange,
                onChanged: (val) {
                  setState(() {
                    _isStaffOnly = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Publicar Aviso', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
