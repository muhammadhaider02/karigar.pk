import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not dial $number')),
        );
      }
    }
  }

  void _shareLocation(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final lat = appState.customerLat;
    final lng = appState.customerLng;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS unavailable')),
      );
      return;
    }
    final url = 'https://maps.google.com?q=$lat,$lng';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location link copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency / Madadgar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WarningHeader(),
            const SizedBox(height: 28),
            _EmergencyButton(
              icon: Icons.local_police,
              label: 'Police — 15',
              onTap: () => _call(context, '15'),
            ),
            const SizedBox(height: 14),
            _EmergencyButton(
              icon: Icons.local_hospital,
              label: 'Rescue / Ambulance — 1122',
              onTap: () => _call(context, '1122'),
            ),
            const SizedBox(height: 14),
            _EmergencyButton(
              icon: Icons.local_fire_department,
              label: 'Fire Brigade — 16',
              onTap: () => _call(context, '16'),
            ),
            const SizedBox(height: 14),
            _EmergencyButton(
              icon: Icons.support_agent,
              label: 'Karigar Support',
              onTap: () => _call(context, '03001234567'),
            ),
            const SizedBox(height: 32),
            _TipsSection(),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _shareLocation(context),
              icon: const Icon(Icons.share_location, size: 20),
              label: const Text(
                'Share My Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _WarningHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
          ),
          child: const Icon(
            Icons.warning_rounded,
            color: Color(0xFFDC2626),
            size: 52,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Musibat mein koi nahi?\nCall karo!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFDC2626),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EmergencyButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(Icons.call, color: Colors.white70, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Madadgar Tips',
          style: TextStyle(
            color: Color(0xFF111B21),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _TipRow(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                text: 'Aapna location note karein',
              ),
              _TipDivider(),
              _TipRow(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                text: 'Booking ID police ko batayein',
              ),
              _TipDivider(),
              _TipRow(
                icon: Icons.warning,
                iconColor: Colors.amber,
                text: 'Zakhmion ko na hilayein',
              ),
              _TipDivider(),
              _TipRow(
                icon: Icons.warning,
                iconColor: Colors.amber,
                text: 'Gar se bahar mat niklein',
              ),
              _TipDivider(),
              _TipRow(
                icon: Icons.info,
                iconColor: Colors.blue,
                text: 'Karigar AI support 24/7 available hai',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final bool isLast;

  const _TipRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isLast ? 12 : 12, 16, isLast ? 14 : 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 52, endIndent: 16, color: Color(0xFFEDF2F7));
  }
}
