import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';
import '../../utils/responsive.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _thumbnailUrlController = TextEditingController();
  bool _isFree = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<CourseProvider>();
    final success = await provider.createCourse(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      price: _isFree ? 0 : double.tryParse(_priceController.text) ?? 0,
      thumbnailUrl: _thumbnailUrlController.text.trim().isEmpty
          ? null
          : _thumbnailUrlController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Course created! It will be visible after admin approval.',
          ),
          backgroundColor: Color(0xFF1F7A63),
        ),
      );
      Navigator.pop(context, true); // return true to signal refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create course'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTabletLayout = AppResponsive.isTablet(context);
    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 16,
      tablet: 24,
      desktop: 32,
    );
    final formMaxWidth = AppResponsive.formMaxWidth(
      context,
      tablet: 760,
      desktop: 860,
    );

    Widget formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your course will be reviewed by an admin before it becomes visible to students.',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Course Title *',
              hintText: 'e.g. Flutter Development Masterclass',
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              if (value.trim().length < 3) {
                return 'Title must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe what students will learn...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.description_outlined),
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // Thumbnail URL
          TextFormField(
            controller: _thumbnailUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Thumbnail URL',
              hintText: 'https://example.com/image.jpg',
              prefixIcon: Icon(Icons.image_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // Pricing toggle
          SwitchListTile(
            title: const Text('Free Course'),
            subtitle: Text(
              _isFree ? 'Students can enroll for free' : 'Set a price below',
            ),
            value: _isFree,
            onChanged: (val) => setState(() => _isFree = val),
            contentPadding: EdgeInsets.zero,
          ),

          // Price field (only when not free)
          if (!_isFree) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price (₹) *',
                hintText: '9.99',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              validator: (value) {
                if (!_isFree) {
                  final price = double.tryParse(value ?? '');
                  if (price == null || price <= 0) {
                    return 'Enter a valid price greater than 0';
                  }
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 32),

          // Submit
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_rounded),
              label: Text(_isSubmitting ? 'Creating...' : 'Create Course'),
            ),
          ),
        ],
      ),
    );

    if (isTabletLayout) {
      formContent = Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: formContent,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Course')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          20,
          horizontalPadding,
          24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: formMaxWidth),
            child: formContent,
          ),
        ),
      ),
    );
  }
}
