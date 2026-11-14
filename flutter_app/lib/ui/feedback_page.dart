import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';

/// A simple support form shared by mobile, web and desktop clients.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, required this.api});
  final ApiClient api;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final formKey = GlobalKey<FormState>();
  final message = TextEditingController();
  final email = TextEditingController();
  String category = 'problem';
  bool sending = false;
  String? result;
  bool savedOnly = false;

  static const categories = <String, String>{
    'problem': 'Ошибка в приложении',
    'idea': 'Предложение',
    'translation': 'Ошибка перевода',
    'lesson': 'Урок или задание',
    'other': 'Другое',
  };

  @override
  void dispose() {
    message.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (sending || !(formKey.currentState?.validate() ?? false)) return;
    setState(() { sending = true; result = null; savedOnly = false; });
    try {
      final response = await widget.api.request('POST', '/extras/feedback', body: {
        'category': category,
        'message': message.text.trim(),
        'contact_email': email.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        savedOnly = response['status'] != 'sent';
        result = (response['message'] as String?) ?? 'Обращение сохранено';
        if (!savedOnly) message.clear();
      });
    } catch (error) {
      if (mounted) setState(() => result = '$error');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> openEmail() async {
    final uri = Uri(scheme: 'mailto', path: 'mysterystudios444@gmail.com', queryParameters: {
      'subject': 'Фидбек по приложению — ${categories[category]}',
      'body': '${message.text.trim()}\n\nКонтакт: ${email.text.trim()}',
    });
    if (!(await launchUrl(uri)) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Почтовое приложение не открылось')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Отправить фидбек')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Form(
          key: formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const Icon(Icons.mark_email_read_outlined, size: 42),
            const SizedBox(height: 12),
            Text('Помоги нам стать лучше',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Расскажи об ошибке в уроке, переводе или работе приложения. ' 
              'Мы получим сообщение от твоего аккаунта.', textAlign: TextAlign.center),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Тема обращения', border: OutlineInputBorder()),
              items: [for (final item in categories.entries)
                DropdownMenuItem(value: item.key, child: Text(item.value))],
              onChanged: sending ? null : (value) => setState(() => category = value ?? category),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: message, minLines: 5, maxLines: 9, maxLength: 3000,
              enabled: !sending,
              decoration: const InputDecoration(
                labelText: 'Опиши проблему или идею', alignLabelWithHint: true,
                hintText: 'Что произошло? На каком уроке? Что ожидалось?',
                border: OutlineInputBorder()),
              validator: (value) => (value?.trim().length ?? 0) < 10
                  ? 'Напиши хотя бы 10 символов' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: email, keyboardType: TextInputType.emailAddress, enabled: !sending,
              decoration: const InputDecoration(
                labelText: 'Почта для ответа (необязательно)', border: OutlineInputBorder()),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return null;
                return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
                    ? null : 'Проверь адрес почты';
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: sending ? null : send,
              icon: sending ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(sending ? 'Отправка…' : 'Отправить фидбек'),
            ),
            if (result != null) ...[
              const SizedBox(height: 18),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(result!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (savedOnly) ...[
                    const SizedBox(height: 8),
                    const Text('Когда почта сервера недоступна, сообщение остаётся в базе. ' 
                      'Можно отправить его вручную через почтовую программу.'),
                    TextButton.icon(onPressed: openEmail,
                      icon: const Icon(Icons.alternate_email), label: const Text('Открыть почту')),
                  ],
                ],
              ))),
            ],
          ]),
        ),
      )),
    );
  }
}
