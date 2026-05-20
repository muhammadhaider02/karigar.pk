import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../app/routes.dart';

class WorkersByRoleScreen extends StatefulWidget {
  final String role;
  final String displayName;

  const WorkersByRoleScreen({super.key, required this.role, required this.displayName});

  @override
  State<WorkersByRoleScreen> createState() => _WorkersByRoleScreenState();
}

class _WorkersByRoleScreenState extends State<WorkersByRoleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false)
          .loadWorkersByService(widget.role);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1E1C) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(widget.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? const Color(0xFF0B1E1C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.isPipelineRunning || (state.recommendedProviders.isEmpty && state.pipelineError == null)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.pipelineError != null) {
            return Center(child: Text('Error: ${state.pipelineError}', style: const TextStyle(color: Colors.red)));
          }
          if (state.recommendedProviders.isEmpty) {
            return Center(child: Text('No ${widget.displayName.toLowerCase()} workers found nearby.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.recommendedProviders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = state.recommendedProviders[i];
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2E2C) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: p.imageUrl.isNotEmpty ? NetworkImage(p.imageUrl) : null,
                      backgroundColor: const Color(0xFF0A7C42).withValues(alpha: 0.15),
                      child: p.imageUrl.isEmpty ? Text(p.name.isNotEmpty ? p.name[0] : '?', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A7C42))) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.star, color: Color(0xFFFFB300), size: 14),
                            const SizedBox(width: 2),
                            Text(p.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text(p.reasoning.split('·').first.trim(), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ]),
                          const SizedBox(height: 4),
                          Text('PKR ${p.pricePerVisit}/visit', style: const TextStyle(fontSize: 12, color: Color(0xFF0A7C42), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final query = 'I need a ${widget.displayName}';
                        state.startBookingFlow(query);
                        Navigator.pushNamed(context, AppRoutes.agentTrace);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A7C42),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Book'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
