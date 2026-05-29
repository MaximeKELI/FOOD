import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/api_client.dart';
import '../../api/catalog_api.dart';
import '../../services/app_media_picker.dart';

/// Bottom sheet allowing a seller to publish a new meal to the catalog.
/// Returns `true` when a meal was successfully created.
class PublishMealSheet extends StatefulWidget {
  const PublishMealSheet({super.key});

  @override
  State<PublishMealSheet> createState() => _PublishMealSheetState();
}

class _PublishMealSheetState extends State<PublishMealSheet> {
  final _name = TextEditingController();
  final _subtitle = TextEditingController();
  final _price = TextEditingController();
  final _promoPrice = TextEditingController();
  bool _isSpecial = false;

  List<MealCategory> _categories = [];
  MealCategory? _selected;
  String? _imagePath;
  bool _loadingCategories = true;
  bool _submitting = false;
  String? _categoriesError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CatalogApi.instance.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selected = categories.isNotEmpty ? categories.first : null;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesError = apiErrorMessage(e);
        _loadingCategories = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final media = await AppMediaPicker.instance.pickPhotoFromGallery();
      if (!mounted || media == null) return;
      setState(() => _imagePath = media.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de choisir l’image: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donne un nom au plat.')),
      );
      return;
    }
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis une catégorie.')),
      );
      return;
    }
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute une photo du plat.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await CatalogApi.instance.createMeal(
        name: _name.text.trim(),
        categoryId: _selected!.id,
        imagePath: _imagePath!,
        subtitle: _subtitle.text.trim(),
        price: int.tryParse(_price.text.trim()),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec: ${apiErrorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publier un plat',
              style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nom du plat',
                prefixIcon: Icon(Icons.restaurant_menu_rounded),
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingCategories)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (_categoriesError != null)
              Text(
                _categoriesError!,
                style: t.textTheme.bodySmall?.copyWith(color: Colors.red),
              )
            else
              DropdownButtonFormField<MealCategory>(
                value: _selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: [
                  for (final c in _categories)
                    DropdownMenuItem(value: c, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _selected = v),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitle,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Prix en FCFA (optionnel)',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
            ),
            const SizedBox(height: 12),
            if (_imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_imagePath!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(
                  _imagePath == null ? 'Choisir une photo' : 'Changer la photo',
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(_submitting ? 'Publication…' : 'Publier le plat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
