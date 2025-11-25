import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing.dart';
import '../services/listing_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key, this.listing});

  final Listing? listing; // If provided, we're editing

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _selectedCategory = ListingCategory.furniture;
  final List<String> _photoUrls = [];
  final List<File> _newPhotos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.listing != null) {
      _titleController.text = widget.listing!.title;
      _descriptionController.text = widget.listing!.description;
      _priceController.text = widget.listing!.price.toStringAsFixed(2);
      _selectedCategory = widget.listing!.category;
      _photoUrls.addAll(widget.listing!.photoUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _newPhotos.addAll(images.map((xFile) => File(xFile.path)));
      });
    }
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        _newPhotos.add(File(image.path));
      });
    }
  }

  void _removePhoto(int index, {bool isUrl = false}) {
    setState(() {
      if (isUrl) {
        _photoUrls.removeAt(index);
      } else {
        _newPhotos.removeAt(index);
      }
    });
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photoUrls.isEmpty && _newPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ListingService();
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) throw Exception('Not logged in');

      // Upload new photos
      List<String> allPhotoUrls = List.from(_photoUrls);
      if (_newPhotos.isNotEmpty) {
        final newUrls = await service.uploadPhotos(
          currentUser.id,
          _newPhotos.map((f) => f.path).toList(),
        );
        allPhotoUrls.addAll(newUrls);
      }

      if (widget.listing == null) {
        // Create new listing
        // Get user profile for name
        final profile = await Supabase.instance.client
            .from('users')
            .select('full_name')
            .eq('id', currentUser.id)
            .single();

        await service.createListing(
          sellerId: currentUser.id,
          sellerName: profile['full_name'] as String,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          photoUrls: allPhotoUrls,
          category: _selectedCategory,
        );
      } else {
        // Update existing listing
        await service.updateListing(
          listingId: widget.listing!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          photoUrls: allPhotoUrls,
          category: _selectedCategory,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.listing == null
                ? 'Listing created successfully!'
                : 'Listing updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listing == null ? 'New Listing' : 'Edit Listing'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photos section
                    Text(
                      'Photos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Existing photos (URLs)
                          ..._photoUrls.asMap().entries.map((entry) {
                            return _PhotoThumbnail(
                              imageUrl: entry.value,
                              onRemove: () => _removePhoto(entry.key, isUrl: true),
                            );
                          }),
                          // New photos (Files)
                          ..._newPhotos.asMap().entries.map((entry) {
                            return _PhotoThumbnail(
                              imageFile: entry.value,
                              onRemove: () => _removePhoto(entry.key),
                            );
                          }),
                          // Add photo buttons
                          _AddPhotoButton(
                            icon: Icons.photo_library,
                            label: 'Gallery',
                            onTap: _pickImages,
                          ),
                          _AddPhotoButton(
                            icon: Icons.camera_alt,
                            label: 'Camera',
                            onTap: _takePicture,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Desk Lamp',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: ListingCategory.all.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        hintText: '0.00',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe the item...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveListing,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.listing == null ? 'Create Listing' : 'Update Listing',
                          style: const TextStyle(fontSize: 16),
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

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    this.imageUrl,
    this.imageFile,
    required this.onRemove,
  });

  final String? imageUrl;
  final File? imageFile;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    imageFile!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.all(4),
                minimumSize: const Size(24, 24),
              ),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
