import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as dev;

class WhatsAppService {
  Future<void> sendIndividualMessage(String phone, String message) async {
    // Sanitizar teléfono
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      dev.log('Could not launch WhatsApp', name: 'WHATSAPP');
      throw Exception('No se pudo abrir WhatsApp. Verifique si la aplicación está instalada.');
    }
  }

  Future<void> sendBroadcastMessage(String message) async {
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback simple si el esquema whatsapp:// falla
      final fallbackUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se pudo abrir WhatsApp.');
      }
    }
  }
}
