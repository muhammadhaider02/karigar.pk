import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/booking.dart';
import '../providers/app_state.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});
  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).loadBookings();
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

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
                SafeArea(bottom: false, child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(width: 36, height: 36,
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE4E6EB)), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.arrow_back, color: _textDark, size: 18)),
                      ),
                      const SizedBox(width: 12),
                      const Text('My Bookings', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(20)),
                        child: const Row(children: [
                          Text('🇵🇰', style: TextStyle(fontSize: 12)), SizedBox(width: 4),
                          Text('Karigar AI', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ]),
                  ),
                  TabBar(
                    controller: _tabs,
                    labelColor: _teal, unselectedLabelColor: _textGrey,
                    indicatorColor: _teal, indicatorWeight: 3,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    tabs: const [Tab(text: 'All'), Tab(text: 'Active'), Tab(text: 'Completed')],
                  ),
                ])),
              ],
            ),
          ),

          Expanded(
            child: Consumer<AppState>(
              builder: (context, state, _) {
                if (state.isLoadingBookings) {
                  return const Center(child: CircularProgressIndicator(color: _teal));
                }
                if (state.bookings.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 90, height: 90,
                      decoration: BoxDecoration(color: const Color(0xFFE8F5EF), shape: BoxShape.circle),
                      child: const Icon(Icons.history, color: _teal, size: 40)),
                    const SizedBox(height: 20),
                    const Text('Koi booking nahi mili', style: TextStyle(color: _textDark, fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Your bookings will appear here', style: TextStyle(color: _textGrey, fontSize: 13)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
                      style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Find a Professional'),
                    ),
                  ]));
                }

                return TabBarView(
                  controller: _tabs,
                  children: [
                    _BookingList(bookings: state.bookings),
                    _BookingList(bookings: state.bookings.where((b) => !b.isCompleted && !b.isCancelled).toList()),
                    _BookingList(bookings: state.bookings.where((b) => b.isCompleted).toList()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Booking> bookings;
  const _BookingList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings here', style: TextStyle(color: Color(0xFF8696A0))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _BookingCard(booking: bookings[index])
          .animate().fadeIn(delay: Duration(milliseconds: 80 * index)).slideY(begin: 0.06);
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});
  static const _teal = Color(0xFF075E54);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  @override
  Widget build(BuildContext context) {
    final isCompleted = booking.isCompleted;
    final isCancelled = booking.isCancelled;
    final statusColor = isCompleted ? const Color(0xFF25D366) : isCancelled ? const Color(0xFFDC2626) : _teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E6EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(_iconForService(booking.serviceType), color: statusColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(booking.providerName, style: const TextStyle(color: _textDark, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(booking.status,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text(booking.displayDate, style: const TextStyle(color: _textGrey, fontSize: 12)),
          ]),
        ])),
        Text(booking.displayCost, style: const TextStyle(color: _teal, fontSize: 15, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  IconData _iconForService(String serviceType) {
    switch (serviceType) {
      case 'plumber': return Icons.plumbing;
      case 'electrician': return Icons.electrical_services;
      case 'ac_technician': return Icons.ac_unit;
      case 'carpenter': return Icons.carpenter;
      case 'tutor': return Icons.school;
      case 'beautician': return Icons.face;
      default: return Icons.handyman;
    }
  }
}
