import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../providers/app_state.dart';
import '../models/agent_event.dart';

class AgentTraceScreen extends StatefulWidget {
  const AgentTraceScreen({super.key});
  @override
  State<AgentTraceScreen> createState() => _AgentTraceScreenState();
}

class _AgentTraceScreenState extends State<AgentTraceScreen> {
  bool _navigated = false;
  static const _teal = Color(0xFF075E54);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            child: Stack(
              children: [
                Positioned(right: 0, top: 0, bottom: 0,
                  child: Opacity(opacity: 0.05,
                    child: Image.asset('assets/images/pak_bg.png', fit: BoxFit.fitHeight,
                      errorBuilder: (_, __, ___) => const SizedBox()))),
                SafeArea(bottom: false, child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Karigar AI Engine', style: TextStyle(color: _teal, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    const Text('Analyzing Request...', style: TextStyle(color: _textDark, fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Our AI is securely matching your requirements with the best professionals in Pakistan.',
                      style: TextStyle(color: _textGrey, fontSize: 13)),
                  ]),
                )),
              ],
            ),
          ),

          Expanded(
            child: Consumer<AppState>(
              builder: (context, state, _) {
                if (!state.isPipelineRunning && !_navigated) {
                  // Auto-navigate to provider selection if we have ANY result:
                  // recommended providers, a booking, or an explicit decision.
                  final hasResult = state.finalDecision == 'show_options'
                      || state.recommendedProviders.isNotEmpty
                      || state.currentBooking != null
                      || state.selectedProvider != null;
                  if (hasResult) {
                    _navigated = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacementNamed(context, AppRoutes.providerSelect);
                    });
                  } else if (state.finalDecision == 'clarify') {
                    _navigated = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pop(context);
                    });
                  }
                }

                // Debug strip so we can see the FE/BE handshake live
                final debugStrip = Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCD34D))),
                  child: Text(
                    'running=${state.isPipelineRunning}  events=${state.traceEvents.length}  providers=${state.recommendedProviders.length}  booking=${state.currentBooking?.id.substring(0, 6) ?? "—"}  decision=${state.finalDecision ?? "—"}  err=${state.pipelineError ?? "—"}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontFamily: 'monospace'),
                  ),
                );

                if (!state.isPipelineRunning && state.pipelineError != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 48),
                        const SizedBox(height: 16),
                        const Text('Connection Failed', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text('Backend API issue: ${state.pipelineError}', textAlign: TextAlign.center, style: const TextStyle(color: _textGrey, fontSize: 13)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Go Back'),
                        ),
                      ]),
                    ),
                  );
                }

                return Column(children: [
                  debugStrip,
                  Expanded(child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.traceEvents.length + (state.isPipelineRunning ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.traceEvents.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(children: [
                            const CircularProgressIndicator(color: _teal),
                            const SizedBox(height: 16),
                            const Text('AI is working...', style: TextStyle(color: _textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ).animate().fadeIn();
                    }
                    return _AgentTraceCard(event: state.traceEvents[index])
                        .animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
                  },
                )),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentTraceCard extends StatelessWidget {
  final AgentTraceEvent event;
  const _AgentTraceCard({required this.event});
  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E6EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _green.withValues(alpha: 0.15)),
            child: const Icon(Icons.check, size: 16, color: _teal)),
          const SizedBox(width: 12),
          Expanded(child: Text('Step ${event.step}: ${event.agent}',
            style: const TextStyle(color: Color(0xFF111B21), fontSize: 14, fontWeight: FontWeight.w700))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(8)),
            child: Text(event.phase, style: const TextStyle(color: _teal, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (event.reasoning.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(event.reasoning, style: const TextStyle(color: Color(0xFF8696A0), fontSize: 12, height: 1.4)),
        ],
      ]),
    );
  }
}
