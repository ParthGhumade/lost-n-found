import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';
import '../app_theme.dart';

class ReportItemScreen extends StatefulWidget {
  final VoidCallback? onItemCreated;

  const ReportItemScreen({super.key, this.onItemCreated});

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedCategory = 'Electronics';
  DateTime _dateFound = DateTime.now();
  Uint8List? _imageBytes;
  String? _imageFileName;
  String _imageExtension = 'jpg';

  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _categories = [
    'Electronics',
    'ID Cards',
    'Keys',
    'Wallets',
    'Books',
    'Apparel',
    'Other',
  ];

  final List<String> _quickLocations = [
    'Central Library',
    'Cafeteria',
    'Computer Lab 2',
    'Auditorium',
    'Sports Complex',
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';

        setState(() {
          _imageBytes = bytes;
          _imageFileName = picked.name;
          _imageExtension = ext;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFound,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFound = picked;
      });
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageBytes == null) {
      setState(() {
        _errorMessage = 'A verification photo is required for anti-fraud validation.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // 1. Upload photo to private bucket
      final storagePath = await apiService.uploadItemImage(
        bytes: _imageBytes!,
        fileExtension: _imageExtension,
        originalFileName: _imageFileName,
      );

      // 2. Create Item Listing
      final itemType = _titleController.text.trim().isNotEmpty
          ? '${_selectedCategory} - ${_titleController.text.trim()}'
          : _selectedCategory;

      await apiService.createItemListing(
        itemType: itemType,
        locationFound: _locationController.text.trim(),
        dateFound: _dateFound,
        imagePath: storagePath,
      );

      if (mounted) {
        widget.onItemCreated?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item listing published successfully! Photo secured in private vault.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_dateFound.year}-${_dateFound.month.toString().padLeft(2, '0')}-${_dateFound.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Report Found Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Informational Privacy Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: AppTheme.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Photo is stored privately and revealed only after you verify a claimant\'s description.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Category Selector
                  const Text(
                    'Item Category',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Item Detail / Title
                  const Text(
                    'Item Name / Title',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Boat Earbuds, Blue Water Bottle, Titan Watch',
                      prefixIcon: Icon(Icons.label_outline, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide a brief item title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campus Location Found
                  const Text(
                    'Where was it found?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Central Library - 2nd Floor Reading Room',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter the location where the item was found';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Quick campus location suggestions
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _quickLocations.map((loc) {
                      return ActionChip(
                        label: Text(loc, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppTheme.surfaceMuted,
                        side: const BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: () {
                          _locationController.text = loc;
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Date Found Picker
                  const Text(
                    'Date Found',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 20, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    formattedDate,
                                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Change', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Photo Upload Section
                  const Text(
                    'Verification Photo',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (_imageBytes != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            child: Image.memory(
                              _imageBytes!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Photo Attached',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _imageFileName ?? 'item_photo.$_imageExtension',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                            tooltip: 'Remove photo',
                            onPressed: () {
                              setState(() {
                                _imageBytes = null;
                                _imageFileName = null;
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.add_a_photo_outlined, size: 36, color: AppTheme.textMuted),
                          const SizedBox(height: 10),
                          const Text(
                            'Take or upload a clear photo of the found item',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                label: const Text('Camera'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined, size: 18),
                                label: const Text('Gallery'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Submit Button
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitListing,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.publish_outlined),
                    label: Text(_isSubmitting ? 'Publishing...' : 'Publish Listing'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
