import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../providers/app_state.dart';

class WorkerAreaScreen extends StatefulWidget {
  const WorkerAreaScreen({super.key});
  @override
  State<WorkerAreaScreen> createState() => _WorkerAreaScreenState();
}

class _WorkerAreaScreenState extends State<WorkerAreaScreen> {
  final Set<String> _selectedAreas = {};
  File? _profileFile;
  File? _cnicFrontFile;
  File? _cnicBackFile;
  File? _certFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final data = appState.workerRegistrationData;
    _selectedAreas.addAll(data.areas);
    _profileFile = data.profilePhoto;
    _cnicFrontFile = data.cnicFront;
    _cnicBackFile = data.cnicBack;
    _certFile = data.cert;
  }

  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  final _areas = [
    'G-13', 'F-7', 'F-8', 'F-10', 'F-11',
    'G-9', 'G-10', 'G-11', 'I-8', 'E-7',
  ];

  Future<void> _pickDoc(ImageSource source, void Function(File) onPicked) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null && mounted) setState(() => onPicked(File(picked.path)));
  }

  void _showPickerDialog(void Function(File) onPicked) {
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
            title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); _pickDoc(ImageSource.camera, onPicked); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF075E54)),
            title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); _pickDoc(ImageSource.gallery, onPicked); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Premium Header with Monument ──────────────────────
          _MonumentHeader(
            onBack: () => Navigator.pop(context),
            title: 'Apna Area aur Documents',
            subtitle: 'Please select your service areas and upload\nrequired documents to complete registration.',
            currentStep: 3,
            totalSteps: 3,
          ),

          // ── Scrollable Content ──────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Areas Section
                  _SectionHeader(
                    icon: Icons.location_on_outlined,
                    title: 'Service Areas (Lahore)',
                    subtitle: 'Select the areas where you can provide services.',
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _areas.map((area) {
                      final sel = _selectedAreas.contains(area);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (sel) _selectedAreas.remove(area);
                          else _selectedAreas.add(area);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? _teal : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? _teal : const Color(0xFFD1D5DB), width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(area, style: TextStyle(
                                color: sel ? Colors.white : _textDark,
                                fontSize: 13, fontWeight: FontWeight.w600,
                              )),
                              if (sel) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle, color: _green, size: 16),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 28),

                  // Upload Documents Section
                  _SectionHeader(
                    icon: Icons.description_outlined,
                    title: 'Upload Documents',
                    subtitle: 'Clear photos are required for verification.',
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 12),

                  _DocRow(
                    icon: Icons.camera_alt_outlined,
                    title: 'Profile Photo (Selfie)',
                    subtitle: 'Tap to upload photo',
                    hint: 'Face should be clearly visible',
                    file: _profileFile,
                    onTap: () => _showPickerDialog((f) => _profileFile = f),
                    delay: 350,
                  ),
                  _DocRow(
                    icon: Icons.credit_card_outlined,
                    title: 'CNIC (Front Side)',
                    subtitle: 'Tap to upload CNIC',
                    hint: 'Ensure all text is readable',
                    file: _cnicFrontFile,
                    onTap: () => _showPickerDialog((f) => _cnicFrontFile = f),
                    delay: 400,
                  ),
                  _DocRow(
                    icon: Icons.credit_card,
                    title: 'CNIC (Back Side)',
                    subtitle: 'Tap to upload CNIC',
                    hint: 'Upload a clear back-side image',
                    file: _cnicBackFile,
                    onTap: () => _showPickerDialog((f) => _cnicBackFile = f),
                    delay: 450,
                  ),
                  _DocRow(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Optional Certificate / Proof of Skill',
                    subtitle: 'Tap to upload file',
                    hint: 'Recommended for better trust',
                    file: _certFile,
                    isOptional: true,
                    onTap: () => _showPickerDialog((f) => _certFile = f),
                    delay: 500,
                  ),

                  const SizedBox(height: 20),

                  // Security Note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: _teal, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Your documents are securely used only for verification.',
                            style: TextStyle(fontSize: 12, color: _textGrey),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 550.ms),

                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (appState.isRegisteringWorker || _selectedAreas.isEmpty || _profileFile == null || _cnicFrontFile == null || _cnicBackFile == null)
                          ? null
                          : () async {
                              appState.workerRegistrationData.areas = _selectedAreas;
                              appState.workerRegistrationData.profilePhoto = _profileFile;
                              appState.workerRegistrationData.cnicFront = _cnicFrontFile;
                              appState.workerRegistrationData.cnicBack = _cnicBackFile;
                              appState.workerRegistrationData.cert = _certFile;

                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await appState.submitWorkerRegistration();
                                if (!mounted) return;
                                messenger.showSnackBar(const SnackBar(
                                  content: Text('Registration submitted! Verification pending.'),
                                  backgroundColor: _teal, duration: Duration(seconds: 2),
                                ));
                                Navigator.pushReplacementNamed(context, AppRoutes.workerHub);
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(SnackBar(
                                  content: Text('Failed: $e', maxLines: 4),
                                  backgroundColor: Colors.red.shade700,
                                  duration: const Duration(seconds: 8),
                                ));
                              }
                            },
                      icon: appState.isRegisteringWorker
                          ? const SizedBox.shrink()
                          : const Icon(Icons.arrow_forward, size: 18),
                      label: appState.isRegisteringWorker
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD1D5DB),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Save & Finish Later',
                        style: TextStyle(color: _teal, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ).animate().fadeIn(delay: 650.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Monument Header ─────────────────────────────────────────
class _MonumentHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final String title;
  final String subtitle;
  final int? currentStep;
  final int? totalSteps;

  const _MonumentHeader({
    this.onBack, required this.title, required this.subtitle,
    this.currentStep, this.totalSteps,
  });

  static const _teal = Color(0xFF075E54);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          // Monument silhouette background
          Positioned(
            right: 0, bottom: 0, top: 0,
            child: Opacity(
              opacity: 0.06,
              child: Image.asset('assets/images/pak_bg.png', fit: BoxFit.fitHeight,
                errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (onBack != null)
                        GestureDetector(
                          onTap: onBack,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE4E6EB)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back, color: Color(0xFF111B21), size: 18),
                          ),
                        ),
                      if (onBack != null) const SizedBox(width: 12),
                      const Text('Karigar AI', style: TextStyle(
                        color: _teal, fontSize: 16, fontWeight: FontWeight.w800,
                      )),
                    ],
                  ),
                  if (currentStep != null && totalSteps != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('STEP $currentStep OF $totalSteps',
                          style: const TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: currentStep! / totalSteps!,
                              backgroundColor: const Color(0xFFE4E6EB),
                              valueColor: const AlwaysStoppedAnimation(_teal),
                              minHeight: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(title, style: const TextStyle(
                    color: Color(0xFF111B21), fontSize: 22, fontWeight: FontWeight.w800, height: 1.2,
                  )),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF8696A0), fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _SectionHeader({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF075E54), size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Color(0xFF111B21), fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Color(0xFF8696A0), fontSize: 12)),
      ])),
    ],
  );
}

class _DocRow extends StatelessWidget {
  final IconData icon; final String title, subtitle, hint;
  final File? file; final bool isOptional; final VoidCallback onTap; final int delay;
  const _DocRow({
    required this.icon, required this.title, required this.subtitle, required this.hint,
    required this.file, required this.onTap, required this.delay, this.isOptional = false,
  });
  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final uploaded = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F2F5))),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: uploaded ? const Color(0xFFE8F5EF) : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: uploaded
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(file!, fit: BoxFit.cover, width: 40, height: 40),
                    )
                  : Icon(icon, color: const Color(0xFF8696A0), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(title, style: TextStyle(
                    color: uploaded ? _teal : const Color(0xFF111B21),
                    fontSize: 14, fontWeight: FontWeight.w600,
                  )),
                  if (isOptional) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Optional', style: TextStyle(fontSize: 10, color: Color(0xFF8696A0))),
                    ),
                  ],
                ]),
                Text(uploaded ? 'Uploaded ✓' : subtitle,
                  style: TextStyle(fontSize: 12, color: uploaded ? _green : const Color(0xFF8696A0))),
                Text(hint, style: const TextStyle(fontSize: 11, color: Color(0xFFB5BEC6))),
              ]),
            ),
            Icon(Icons.chevron_right, color: uploaded ? _teal : const Color(0xFFD1D5DB), size: 20),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.05),
    );
  }
}
