import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/auth_provider.dart';
import '../../core/attendance_provider.dart';
import '../../core/restaurant_provider.dart';

class AttendanceHeader extends StatefulWidget {
  const AttendanceHeader({super.key});

  @override
  State<AttendanceHeader> createState() => _AttendanceHeaderState();
}

class _AttendanceHeaderState extends State<AttendanceHeader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token != null) {
        Provider.of<AttendanceProvider>(context, listen: false).fetchStatus(auth.token!);
        Provider.of<RestaurantProvider>(context, listen: false).fetchRestaurants(auth.token!, myRestaurants: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final attendance = Provider.of<AttendanceProvider>(context);
    final restoProvider = Provider.of<RestaurantProvider>(context);

    if (attendance.isLoading && attendance.activeAttendance == null) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.isClockedIn ? 'YOU ARE CLOCKED IN' : 'READY TO WORK?',
                  style: TextStyle(
                    color: attendance.isClockedIn ? Colors.greenAccent : const Color(0xFFD4AF37),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  attendance.isClockedIn && attendance.activeAttendance != null
                    ? 'Started at ${DateFormat('hh:mm a').format(DateTime.parse(attendance.activeAttendance!['clock_in']))}'
                    : 'Clock in to start your shift',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!attendance.isClockedIn)
            ElevatedButton.icon(
              onPressed: () {
                if (restoProvider.restaurants.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No restaurants assigned to you.')));
                   return;
                }
                // If only one restaurant, clock in immediately. Else show picker?
                // For now, pick the first one.
                attendance.clockIn(auth.token!, restoProvider.restaurants.first.id);
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Clock In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => attendance.clockOut(auth.token!),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Clock Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }
}
