import 'package:darto/darto.dart';

void emailRoutes(Darto app) {
  // Get instance of DartoMailer
  final mailer = DartoMailer();

  // Create a transporter instance
  final transporter = mailer.createTransport(
    host: 'sandbox.smtp.mailtrap.io',
    port: 2525,
    ssl: false,
    auth: {'username': 'seu-username', 'password': 'sua-password'},
  );

  // Send an email using the transporter
  app.post('/send-email', (Request req, Response res) async {
    final success = await transporter.sendMail(
      from: 'seu-email@gmail.com',
      to: 'destinatario@exemplo.com',
      subject: 'Teste de Email via Gmail',
      html: '''
      <h1>Bem-vindo ao Darto Mailer!</h1>
      <p>Este é um email de teste usando Darto Mailer.</p>
    ''',
    );

    if (!res.finished) {
      if (success) {
        return res.json({'message': 'Email enviado com sucesso!'});
      } else {
        return res.status(500).json({'error': 'Falha ao enviar email'});
      }
    }
  });
}
