import 'package:flutter/material.dart';

import '../data/session.dart';

const _dark = Color(0xFF173E35);
const _green = Color(0xFF227F64);
const _light = Color(0xFFF8F9F4);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.session});
  final AppSession session;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final password = TextEditingController();
  bool registration = false;
  bool showPassword = false;
  bool remember = true;
  String? selectedRegion;
  late final Future<List<String>> regionCatalog;

  @override
  void initState() {
    super.initState();
    name.text = widget.session.rememberedUser;
    regionCatalog = widget.session.api.request('GET', '/registration/regions', authorized: false)
      .then((data) => (data['regions'] as List<dynamic>).whereType<String>().toList());
  }

  @override
  void dispose() {
    name.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (registration && selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выбери регион проживания')));
      return;
    }
    FocusScope.of(context).unfocus();
    await widget.session.signIn(name.text.trim(), password.text,
      create: registration, remember: remember, region: registration ? selectedRegion : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _light,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: Container(
                      height: 78, width: 78,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0xFFE4F3E9), borderRadius: BorderRadius.circular(25)),
                      child: const Text('Ә', style: TextStyle(fontSize: 47, color: _green, fontWeight: FontWeight.w900)),
                    )),
                    const SizedBox(height: 18),
                    const Text('Башҡорт теле', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900, color: _dark)),
                    const SizedBox(height: 7),
                    const Text('Учим башкирский вместе', textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF77867F), fontSize: 15)),
                    const SizedBox(height: 34),
                    Row(children: [
                      Expanded(child: _switchButton('Войти', !registration, () => setState(() { registration = false; widget.session.error = null; }))),
                      const SizedBox(width: 10),
                      Expanded(child: _switchButton('Регистрация', registration, () => setState(() { registration = true; widget.session.error = null; }))),
                    ]),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: name,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: _decoration('Имя пользователя', Icons.person_outline_rounded),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.length < 3 || text.length > 32 || !RegExp(r'^[a-zA-Zа-яА-ЯәӘөӨүҮҡҠғҒҙҘҫҪңҢһҺёЁ0-9_]+$').hasMatch(text)) {
                          return 'От 3 до 32 букв, цифр или _';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    TextFormField(
                      controller: password,
                      obscureText: !showPassword,
                      autofillHints: [registration ? AutofillHints.newPassword : AutofillHints.password],
                      onFieldSubmitted: (_) => submit(),
                      decoration: _decoration('Пароль', Icons.lock_outline_rounded).copyWith(
                        suffixIcon: IconButton(
                          tooltip: showPassword ? 'Скрыть пароль' : 'Показать пароль',
                          icon: Icon(showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => showPassword = !showPassword),
                        ),
                      ),
                      validator: (value) => (value ?? '').length < 6 ? 'Минимум 6 символов' : null,
                    ),
                    if (registration) ...[
                      const SizedBox(height: 13),
                      FutureBuilder<List<String>>(
                        future: regionCatalog,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return const Text('Не удалось загрузить регионы. Проверь подключение к серверу.');
                          if (!snapshot.hasData) return const LinearProgressIndicator();
                          return DropdownButtonFormField<String>(
                            value: selectedRegion, isExpanded: true,
                            decoration: _decoration('Регион России', Icons.location_on_outlined),
                            hint: const Text('Выбери свой регион'),
                            items: [for (final region in snapshot.data!)
                              DropdownMenuItem(value: region, child: Text(region, overflow: TextOverflow.ellipsis))],
                            onChanged: (value) => setState(() => selectedRegion = value),
                            validator: (value) => registration && value == null ? 'Укажи регион' : null,
                          );
                        },
                      ),
                    ],
                    if (!registration) ...[
                      const SizedBox(height: 5),
                      Align(alignment: Alignment.centerRight, child: TextButton(
                        onPressed: widget.session.busy ? null : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => ForgotPasswordScreen(session: widget.session)),
                        ),
                        child: const Text('Забыли пароль?'),
                      )),
                    ],
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: remember,
                      activeColor: _green,
                      title: const Text('Запомнить меня на этом устройстве', style: TextStyle(fontSize: 13, color: _dark)),
                      onChanged: (value) => setState(() => remember = value ?? true),
                    ),
                    if (widget.session.error != null) ...[
                      const SizedBox(height: 15),
                      Text(widget.session.error!, textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFAD4E37), fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 23),
                    SizedBox(height: 54, child: FilledButton(
                      onPressed: widget.session.busy ? null : submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: widget.session.busy
                          ? const SizedBox(width: 23, height: 23, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(registration ? 'Создать аккаунт' : 'Войти', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    )),
                    const SizedBox(height: 19),
                    const Text('Вход сохраняется отдельно в каждом браузере. Уроки и прогресс хранятся в аккаунте.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF77867F)), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchButton(String label, bool selected, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFFE4F3E9) : Colors.white,
        foregroundColor: selected ? _green : _dark,
        side: BorderSide(color: selected ? _green : const Color(0xFFE3EAE3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE3EAE3))),
  );
}

class ReconnectScreen extends StatelessWidget {
  const ReconnectScreen({super.key, required this.session});
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.all(30),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 58, color: _green),
          const SizedBox(height: 15),
          const Text('Сервер недоступен', style: TextStyle(fontSize: 23, color: _dark, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(session.error ?? 'Проверь подключение к серверу.', textAlign: TextAlign.center),
          if (session.rememberedUser.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Последний аккаунт на этом устройстве: ${session.rememberedUser}', textAlign: TextAlign.center),
          ],
          const SizedBox(height: 22),
          FilledButton(onPressed: session.restore, child: const Text('Повторить подключение')),
          TextButton(onPressed: session.signOut, child: const Text('Войти в другой аккаунт')),
        ])),
    )));
  }
}


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.session});
  final AppSession session;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final username = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool success = false;
  String? notice;

  @override
  void initState() {
    super.initState();
    username.text = widget.session.rememberedUser;
  }

  @override
  void dispose() {
    username.dispose(); code.dispose(); password.dispose();
    super.dispose();
  }

  Future<void> requestCode() async {
    if (username.text.trim().length < 3) return;
    setState(() { loading = true; notice = null; });
    try {
      final reply = await widget.session.api.request('POST', '/auth/password/request',
          body: {'login': username.text.trim()}, authorized: false);
      if (mounted) setState(() => notice = reply['message'] as String?);
    } catch (error) {
      if (mounted) setState(() => notice = '$error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    if (username.text.trim().length < 3 || code.text.trim().length < 6 || password.text.length < 6) {
      setState(() => notice = 'Заполни имя, код и новый пароль (от 6 символов).');
      return;
    }
    setState(() { loading = true; notice = null; });
    try {
      await widget.session.api.request('POST', '/auth/password/confirm', body: {
        'login': username.text.trim(),
        'code': code.text.trim(),
        'new_password': password.text,
      }, authorized: false);
      if (mounted) setState(() { success = true; notice = 'Пароль изменён. Теперь можно войти.'; });
    } catch (error) {
      if (mounted) setState(() => notice = '$error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Восстановление пароля'), backgroundColor: _light),
    backgroundColor: _light,
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const Icon(Icons.lock_reset_rounded, color: _green, size: 55),
        const SizedBox(height: 15),
        const Text('Восстановить доступ', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: _dark)),
        const SizedBox(height: 15),
        const Text('Используй резервный код, полученный при регистрации или в профиле. Если аккаунт связан с Telegram, можно запросить одноразовый код.'),
        const SizedBox(height: 20),
        TextField(controller: username, decoration: _input('Имя пользователя')),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: loading || success ? null : requestCode,
          child: const Text('Отправить код в Telegram')),
        const SizedBox(height: 12),
        TextField(controller: code, decoration: _input('Резервный код или код из Telegram')),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: true,
          decoration: _input('Новый пароль (не менее 6 символов)')),
        const SizedBox(height: 20),
        FilledButton(onPressed: loading || success ? null : resetPassword,
          child: Text(loading ? 'Подождите...' : 'Сменить пароль')),
        if (notice != null) Padding(padding: const EdgeInsets.only(top: 15),
          child: Text(notice!, textAlign: TextAlign.center, style: const TextStyle(color: _dark))),
        if (success) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Вернуться ко входу')),
      ]),
    )),
  );

  InputDecoration _input(String label) => InputDecoration(
    labelText: label, filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );
}
