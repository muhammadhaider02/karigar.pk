import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../app/routes.dart';

class WorkerProfileSetupScreen extends StatefulWidget {
  const WorkerProfileSetupScreen({super.key});

  @override
  State<WorkerProfileSetupScreen> createState() => _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState extends State<WorkerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _profilePhoto;
  final _picker = ImagePicker();

  Future<void> _pickProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF075E54)),
            title: const Text('Take Selfie', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, preferredCameraDevice: CameraDevice.front);
              if (picked != null && mounted) setState(() => _profilePhoto = File(picked.path));
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF075E54)),
            title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (picked != null && mounted) setState(() => _profilePhoto = File(picked.path));
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          // ── Header Background ────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: 240,
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/pak_bg.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  alignment: Alignment.bottomCenter,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.8),
                        const Color(0xFFF7F8FA).withValues(alpha: 0.95),
                        const Color(0xFFF7F8FA),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF111B21), size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Row(
                          children: [
                            Image.asset('assets/images/karigar_logo.png', width: 28, height: 28),
                            const SizedBox(width: 8),
                            RichText(
                              text: const TextSpan(children: [
                                TextSpan(text: 'Karigar ', style: TextStyle(color: Color(0xFF075E54), fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.2)),
                                TextSpan(text: 'AI', style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.2)),
                              ]),
                            ),
                          ],
                        ),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                          ),
                          child: const Icon(Icons.verified_user_outlined, color: Color(0xFF111B21), size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable Form Area ─────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 60), // Space for header
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Step 1 of 3',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF075E54)),
                          ).animate().fadeIn(delay: 100.ms),
                          const SizedBox(height: 4),
                          const Text(
                            'Create Your Worker Profile',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111B21), letterSpacing: -0.5),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 4),
                          const Text(
                            'Help customers know you better',
                            style: TextStyle(fontSize: 14, color: Color(0xFF8696A0)),
                          ).animate().fadeIn(delay: 300.ms),

                          const SizedBox(height: 24),

                          // ── Stepper ───────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StepIndicator(step: 1, label: 'Profile Info', isActive: true, isCompleted: false),
                              Expanded(child: _StepLine(isActive: false)),
                              _StepIndicator(step: 2, label: 'Skills & Services', isActive: false, isCompleted: false),
                              Expanded(child: _StepLine(isActive: false)),
                              _StepIndicator(step: 3, label: 'Verification', isActive: false, isCompleted: false),
                            ],
                          ).animate().fadeIn(delay: 400.ms),

                          const SizedBox(height: 32),

                          // ── Form Card ─────────────────────────
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 4))],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, color: Color(0xFF075E54), size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Personal Information',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111B21)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  _buildLabel('Full Name'),
                                  _buildTextField(hint: 'Enter your full name', icon: Icons.person_outline),

                                  const SizedBox(height: 20),
                                  _buildLabel('Profile Photo'),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: _pickProfilePhoto,
                                        child: Container(
                                          width: 100, height: 100,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7F8FA),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3), style: BorderStyle.solid),
                                          ),
                                          child: _profilePhoto != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(15),
                                                  child: Image.file(_profilePhoto!, fit: BoxFit.cover, width: 100, height: 100),
                                                )
                                              : Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.camera_alt_outlined, color: Color(0xFF075E54), size: 28),
                                                    const SizedBox(height: 8),
                                                    const Text('Upload Photo', style: TextStyle(color: Color(0xFF075E54), fontSize: 12, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7F8FA),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.verified_user, color: Color(0xFF25D366), size: 16),
                                              const SizedBox(width: 8),
                                              const Expanded(
                                                child: Text(
                                                  'A clear profile photo helps customers trust you more.',
                                                  style: TextStyle(fontSize: 12, color: Color(0xFF111B21), height: 1.4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),
                                  _buildLabel('Phone Number'),
                                  Row(
                                    children: [
                                      Container(
                                        height: 52,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE4E6EB)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone_outlined, color: Color(0xFF25D366), size: 18),
                                            const SizedBox(width: 8),
                                            const Text('+92', style: TextStyle(fontWeight: FontWeight.w600)),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF8696A0)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTextField(hint: '300 1234567'),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),
                                  _buildLabel('CNIC / ID Number'),
                                  _buildTextField(hint: 'XXXXX-XXXXXXX-X', icon: Icons.badge_outlined, suffixIcon: Icons.info_outline),

                                  const SizedBox(height: 20),
                                  _buildLabel('District'),
                                  Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE4E6EB)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, color: Color(0xFF075E54), size: 20),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text('Select your district', style: TextStyle(color: Color(0xFF8696A0), fontSize: 14)),
                                        ),
                                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8696A0)),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                  _buildLabel('Address (Optional)'),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE4E6EB)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(Icons.home_outlined, color: Color(0xFF075E54), size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            maxLines: 2,
                                            style: const TextStyle(fontSize: 14),
                                            decoration: const InputDecoration.collapsed(
                                              hintText: 'Enter your complete address',
                                              hintStyle: TextStyle(color: Color(0xFF8696A0)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F8FA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.lock_outline, color: Color(0xFF25D366), size: 16),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Your information is safe and secure with us.',
                                          style: TextStyle(fontSize: 12, color: Color(0xFF075E54), fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.workerSkills),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF075E54),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111B21)),
      ),
    );
  }

  Widget _buildTextField({required String hint, IconData? icon, IconData? suffixIcon}) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E6EB)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF8696A0), size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextFormField(
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF8696A0)),
              ),
            ),
          ),
          if (suffixIcon != null)
            Icon(suffixIcon, color: const Color(0xFF8696A0), size: 18),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepIndicator({required this.step, required this.label, required this.isActive, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final color = isActive || isCompleted ? const Color(0xFF25D366) : const Color(0xFFD1D7DB);
    return Column(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: isActive || isCompleted ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : color,
                      fontSize: 13, fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF25D366) : const Color(0xFF8696A0),
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;
  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 13),
      height: 2,
      color: isActive ? const Color(0xFF25D366) : const Color(0xFFE4E6EB),
    );
  }
}
