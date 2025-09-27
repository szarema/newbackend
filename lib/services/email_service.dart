import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final String smtpUsername = 'zarema110604@mail.ru';
  final String smtpPassword = 'uho-duna125';

  final SmtpServer smtpServer;

  EmailService()
      : smtpServer = SmtpServer(
    'smtp.mail.ru',
    port: 465,
    ssl: true,
    username: 'zarema110604@mail.ru',
    password: 'uho-duna125',
  );

  Future<void> sendVerificationEmail(String recipientEmail, String verificationLink) async {
    final message = Message()
      ..from = Address(smtpUsername, 'Dog Owner App')
      ..recipients.add(recipientEmail)
      ..subject = 'Подтвердите вашу регистрацию'
      ..text = 'Пожалуйста, подтвердите регистрацию по ссылке: $verificationLink';

    try {
      final sendReport = await send(message, smtpServer);
      print('Verification email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending verification email: $e');
    }
  }
}
