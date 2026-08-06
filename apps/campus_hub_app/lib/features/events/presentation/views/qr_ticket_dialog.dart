import 'package:flutter/material.dart';
import '../../domain/event_models.dart';

class QRTicketDialog extends StatelessWidget {
  final EventRegistrationModel registration;

  const QRTicketDialog({super.key, required this.registration});

  @override
  Widget build(BuildContext context) {
    final event = registration.event;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Event Pass & E-Ticket',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Event title
            Text(
              event?.title ?? 'Campus Event',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 4),
            Text(
              event?.venue ?? 'Campus Auditorium',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),

            // QR Code Placeholder Card (Simulating QR Attendance for future scanner)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 100, color: Colors.black87),
                        Text(
                          'Scan at Venue',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    registration.ticketCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Attendance Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: registration.attendanceStatus == 'ATTENDED' ? Colors.green.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    registration.attendanceStatus == 'ATTENDED' ? Icons.check_circle : Icons.confirmation_number,
                    color: registration.attendanceStatus == 'ATTENDED' ? Colors.green : Colors.blue,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    registration.attendanceStatus == 'ATTENDED' ? 'Attendance Verified' : 'Status: Registered',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: registration.attendanceStatus == 'ATTENDED' ? Colors.green.shade800 : Colors.blue.shade800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
