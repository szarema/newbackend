import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final String smtpUsername = 'petownerapp@outlook.com';
  final String smtpPassword = 'karandash1029!';

  final SmtpServer smtpServer;

  EmailService()
      : smtpServer = SmtpServer(
    'smtp.office365.com',
    port: 587,
    ssl: false,
    username: 'petownerapp@outlook.com',
    password: 'karandash1029!',
  );

  Future<void> sendWelcomeEmail(String recipientEmail) async {
    final message = Message()
      ..from = Address(smtpUsername, 'Dog Owner App')
      ..recipients.add(recipientEmail)
      ..subject = 'Добро пожаловать в Dog Owner App!'
      ..text = 'Вы успешно зарегистрировались в нашем приложении.';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  Future<void> sendVerificationEmail(String recipientEmail, String verificationLink) async {
    final message = Message()
      ..from = Address(smtpUsername, 'Dog Owner App')
      ..recipients.add(recipientEmail)
      ..subject = 'Подтвердите вашу регистрацию'
      ..text = 'Пожалуйста, подтвердите вашу регистрацию, перейдя по ссылке: $verificationLink';

    try {
      final sendReport = await send(message, smtpServer);
      print('Verification email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending verification email: $e');
    }
  }
}
