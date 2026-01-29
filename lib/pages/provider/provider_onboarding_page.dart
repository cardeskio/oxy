import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:oxy/models/service_provider.dart';
import 'package:oxy/services/living_service.dart';
import 'package:oxy/theme.dart';

/// Service Provider onboarding page - collect business details after signup
class ProviderOnboardingPage extends StatefulWidget {
  const ProviderOnboardingPage({super.key});

  @override
  State<ProviderOnboardingPage> createState() => _ProviderOnboardingPageState();
}

class _ProviderOnboardingPageState extends State<ProviderOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController(text: '+254 ');
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _whatsappController = TextEditingController(text: '+254 ');
  final _locationController = TextEditingController();

  ServiceCategory _selectedCategory = ServiceCategory.other;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _whatsappController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final livingService = context.read<LivingService>();
      
      final provider = await livingService.registerAsProvider(
        businessName: _businessNameController.text.trim(),
        businessDescription: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        locationText: _locationController.text.trim(),
      );

      if (provider != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business profile created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/provider');
      } else {
        throw Exception('Failed to create business profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a1628),
              Color(0xFF0d173d),
              Color(0xFF142550),
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedStore01,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Set Up Your Business',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us about your business so customers can find you',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Form content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Stepper(
                      currentStep: _currentStep,
                      onStepContinue: () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _completeOnboarding();
                        }
                      },
                      onStepCancel: _currentStep > 0
                          ? () => setState(() => _currentStep--)
                          : null,
                      controlsBuilder: (context, details) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : details.onStepContinue,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _currentStep == 2 ? 'Complete Setup' : 'Continue',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),
                              if (_currentStep > 0) ...[
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Back'),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                      steps: [
                        // Step 1: Business Info
                        Step(
                          title: const Text('Business Info'),
                          subtitle: const Text('Name & category'),
                          isActive: _currentStep >= 0,
                          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                          content: Column(
                            children: [
                              TextFormField(
                                controller: _businessNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Business Name *',
                                  hintText: 'e.g., Joe\'s Plumbing Services',
                                ),
                                textCapitalization: TextCapitalization.words,
                                validator: (v) => v?.isEmpty == true ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<ServiceCategory>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                ),
                                items: ServiceCategory.values.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Row(
                                      children: [
                                        HugeIcon(
                                          icon: _getCategoryIcon(cat),
                                          color: AppColors.primaryNavy,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(cat.label),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedCategory = v!),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description (Optional)',
                                  hintText: 'What does your business offer?',
                                ),
                                maxLines: 3,
                                textCapitalization: TextCapitalization.sentences,
                              ),
                            ],
                          ),
                        ),

                        // Step 2: Contact Info
                        Step(
                          title: const Text('Contact Info'),
                          subtitle: const Text('How customers reach you'),
                          isActive: _currentStep >= 1,
                          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                          content: Column(
                            children: [
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number *',
                                  hintText: '+254 7XX XXX XXX',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (v) => v?.isEmpty == true ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _whatsappController,
                                decoration: const InputDecoration(
                                  labelText: 'WhatsApp (Optional)',
                                  hintText: '+254 7XX XXX XXX',
                                  prefixIcon: Icon(Icons.chat_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email (Optional)',
                                  hintText: 'business@example.com',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _websiteController,
                                decoration: const InputDecoration(
                                  labelText: 'Website (Optional)',
                                  hintText: 'www.example.com',
                                  prefixIcon: Icon(Icons.language_outlined),
                                ),
                                keyboardType: TextInputType.url,
                              ),
                            ],
                          ),
                        ),

                        // Step 3: Location
                        Step(
                          title: const Text('Location'),
                          subtitle: const Text('Where are you based?'),
                          isActive: _currentStep >= 2,
                          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                          content: Column(
                            children: [
                              TextFormField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Location *',
                                  hintText: 'e.g., Westlands, Nairobi',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                                textCapitalization: TextCapitalization.words,
                                validator: (v) => v?.isEmpty == true ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'You can update your precise location and business hours in your dashboard later.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.foodDining:
        return HugeIcons.strokeRoundedRestaurant01;
      case ServiceCategory.shopping:
        return HugeIcons.strokeRoundedShoppingBag02;
      case ServiceCategory.healthWellness:
        return HugeIcons.strokeRoundedMedicine02;
      case ServiceCategory.homeServices:
        return HugeIcons.strokeRoundedHome03;
      case ServiceCategory.professionalServices:
        return HugeIcons.strokeRoundedBriefcase01;
      case ServiceCategory.entertainment:
        return HugeIcons.strokeRoundedTicket02;
      case ServiceCategory.transport:
        return HugeIcons.strokeRoundedCar01;
      case ServiceCategory.education:
        return HugeIcons.strokeRoundedBook02;
      case ServiceCategory.beautySpa:
        return HugeIcons.strokeRoundedHairDryer;
      case ServiceCategory.fitness:
        return HugeIcons.strokeRoundedDumbbell01;
      case ServiceCategory.financial:
        return HugeIcons.strokeRoundedBank;
      case ServiceCategory.other:
        return HugeIcons.strokeRoundedMoreHorizontal;
    }
  }
}
