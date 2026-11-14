import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import 'cheat_mode.dart';

class AdminWorkspace extends StatefulWidget {
  const AdminWorkspace({super.key, required this.api, required this.token});
  final ApiClient api;
  final String token;
  @override State<AdminWorkspace> createState() => _AdminWorkspaceState();
}

class _AdminWorkspaceState extends State<AdminWorkspace> {
  final username = TextEditingController();
  final coins = TextEditingController();
  final region = TextEditingController();
  final search = TextEditingController();
  final translation = TextEditingController();
  final deepSeekKey = TextEditingController();
  final tutorKey = TextEditingController();
  final tutorModel = TextEditingController();
  String tutorProvider = 'deepseek';
  String? tutorTestResult;
  Map<String, dynamic> integrations = {};
  bool installing = false;
  String? error;
  bool loading = true;
  Map<String, dynamic> overview = {};
  List<Map<String,dynamic>> users=[], reviews=[], classes=[], requests=[], audit=[];

  @override void initState() { super.initState(); refresh(); }
  @override void dispose() { for (final c in [username,coins,region,search,translation,deepSeekKey,tutorKey,tutorModel]) { c.dispose(); } super.dispose(); }

  Future<Map<String,dynamic>> call(String method, String path, [Map<String,dynamic>? body]) async {
    final uri=Uri.parse('${widget.api.baseUrl}$path');
    final headers={'Authorization':'Bearer ${widget.token}', 'Content-Type':'application/json'};
    late http.Response reply;
    if (method=='GET') reply=await http.get(uri, headers:headers);
    else if (method=='PATCH') reply=await http.patch(uri, headers:headers, body:jsonEncode(body ?? {}));
    else if (method=='DELETE') reply=await http.delete(uri, headers:headers);
    else if (method=='PUT') reply=await http.put(uri, headers:headers, body:jsonEncode(body ?? {}));
    else reply=await http.post(uri, headers:headers, body:jsonEncode(body ?? {}));
    final response = jsonDecode(utf8.decode(reply.bodyBytes)) as Map<String,dynamic>;
    if (reply.statusCode>=400) throw ApiError('${response['detail'] ?? reply.statusCode}');
    return response;
  }

  Future<void> refresh() async {
    setState(() {loading=true; error=null;});
    try {
      final responses = await Future.wait([
        call('GET','/extras/admin/overview'),
        call('GET','/extras/admin/users?q=${Uri.encodeComponent(search.text)}'),
        call('GET','/extras/admin/reviews'),
        call('GET','/extras/admin/classes'),
        call('GET','/extras/admin/course-requests'),
        call('GET','/extras/admin/audit'),
        call('GET','/extras/admin/integrations'),
      ]);
      if (mounted) setState(() {
        overview=responses[0]; users=_items(responses[1]); reviews=_items(responses[2]);
        classes=_items(responses[3]); requests=_items(responses[4]); audit=_items(responses[5]); integrations=responses[6];
        final tutor = responses[6]['tutor'] as Map<String,dynamic>? ?? {};
        tutorProvider = tutor['provider'] as String? ?? 'deepseek';
        tutorModel.text = tutor['model'] as String? ?? 'deepseek-chat';
      });
    } catch (e) { if (mounted) setState(() => error='$e'); }
    finally { if (mounted) setState(() => loading=false); }
  }
  List<Map<String,dynamic>> _items(Map<String,dynamic> data) =>
    ((data['items'] as List<dynamic>?) ?? []).whereType<Map<String,dynamic>>().toList();

  Future<void> changeUser() async {
    try {
      await call('PATCH','/extras/admin/user',{
        'username':username.text.trim(),
        if (coins.text.trim().isNotEmpty) 'coins': int.parse(coins.text),
        if (region.text.trim().isNotEmpty) 'region':region.text.trim(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Данные обновлены')));
      await refresh();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'))); }
  }

  Future<void> markDelivered(String name) async {
    final yes = await showDialog<bool>(context:context, builder:(c) => AlertDialog(
      title:const Text('Подтвердить выдачу ключей?'),
      content:Text('Только после реальной отправки всех 4 ключей пользователю $name.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false), child:const Text('Отмена')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Ключи отправлены'))]));
    if (yes != true) return;
    try { await call('POST','/extras/admin/course-requests/delivered',{'username':name}); await refresh(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'))); }
  }

  Future<void> approve(Map<String,dynamic> review) async {
    translation.text = review['translation'] as String? ?? '';
    final chosen = await showDialog<String>(context:context, builder:(c)=>AlertDialog(
      title: const Text('Разрешить спорный перевод'),
      content:Column(mainAxisSize:MainAxisSize.min, children:[
        Text(review['text_ba'] as String? ?? ''), const SizedBox(height:10),
        TextField(controller:translation, minLines:2, maxLines:5,
          decoration:const InputDecoration(labelText:'Подтверждённый вариант',border:OutlineInputBorder())),
      ]), actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Отмена')),
        FilledButton(onPressed:()=>Navigator.pop(c,translation.text.trim()),child:const Text('Подтвердить'))]));
    if (chosen==null || chosen.isEmpty) return;
    try { await call('POST','/extras/admin/reviews/${review['id']}',{'translation':chosen}); await refresh(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'))); }
  }

  Future<void> copyAudit() async {
    await Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(audit)));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Журнал скопирован')));
  }

  Future<void> setDeepSeek() async {
    final key = deepSeekKey.text.trim();
    if (key.isEmpty) return;
    try {
      await call('PUT', '/extras/admin/integrations/deepseek', {'key': key});
      deepSeekKey.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ключ сохранён на сервере. В ответах API он не раскрывается.')));
      await refresh();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> configureTutor() async {
    try {
      final result = await call('PUT', '/extras/admin/integrations/tutor', {
        'provider': tutorProvider,
        'model': tutorModel.text.trim(),
        'key': tutorKey.text.trim(),
      });
      tutorKey.clear();
      if (mounted) setState(() {
        integrations['tutor'] = result['active'];
        integrations['tutor_providers'] = result['providers'];
        tutorTestResult = 'Настройки преподавателя сохранены на сервере';
      });
    } catch (e) { if (mounted) setState(() => tutorTestResult = '$e'); }
  }

  Future<void> testTutor() async {
    setState(() => tutorTestResult = 'Отправка тестового вопроса…');
    try {
      final data = await call('POST', '/extras/admin/integrations/tutor/test');
      if (mounted) setState(() => tutorTestResult = '✓ ${data['preview']}');
    } catch (e) { if (mounted) setState(() => tutorTestResult = '$e'); }
  }

  Future<void> installModel(String kind) async {
    if (installing) return;
    setState(() => installing = true);
    try {
      await call('POST', '/extras/admin/integrations/models/$kind/install');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Установка запущена. Открой статус после загрузки.')));
      await refresh();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => installing = false);
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:const Text('Центр управления'),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body: loading ? const Center(child:CircularProgressIndicator()) : ListView(padding:const EdgeInsets.all(16),children:[
      if (error!=null) Text('Ошибка: $error'),
      const Text('Обзор платформы',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900)),
      const SizedBox(height:10),
      Wrap(spacing:10,runSpacing:10,children:[
        for (final pair in <String,String>{'users':'Аккаунты','schools':'Классы','answers':'Переводы','achievements':'Достижения',
          'custom_lessons':'Доп. уроки','pending_course_rewards':'Заявки на ключи'}.entries)
          Chip(label:Text('${pair.value}: ${overview[pair.key] ?? 0}')),
      ]),
      const SizedBox(height:18),
      Card(child: ListTile(
        leading: const Icon(Icons.bolt_outlined),
        title: const Text('Cheat Mode', style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: const Text('Монеты, прогресс, награды, достижения и сбросы'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => CheatModePage(api: widget.api,
            adminToken: widget.token, initialUsername: username.text.trim()))),
      )),
      const SizedBox(height: 8),
      ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.extension_outlined),
        title: const Text('Интеграции: DeepSeek и голосовые модели',
          style: TextStyle(fontWeight: FontWeight.bold)),
        children: [Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(integrations['deepseek_configured'] == true
              ? 'DeepSeek: настроен ✓' : 'DeepSeek: ключ не задан',
              style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            TextField(controller: deepSeekKey, obscureText: true,
              autocorrect: false, enableSuggestions: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: 'Новый ключ DeepSeek',
                helperText: 'Сохраняется только в конфигурации Python-сервера')),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: setDeepSeek, icon: const Icon(Icons.key),
              label: const Text('Сохранить ключ')),
            const Divider(height: 28),
            const Text('Выбор движка преподавателя', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: tutorProvider, isExpanded: true,
              decoration: const InputDecoration(labelText: 'ИИ-провайдер', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek API')),
                DropdownMenuItem(value: 'openrouter', child: Text('OpenRouter · бесплатные модели')),
                DropdownMenuItem(value: 'ollama', child: Text('Ollama · локальная модель')),
              ],
              onChanged: (value) { if (value == null) return;
                setState(() { tutorProvider = value; tutorModel.text =
                  value == 'openrouter' ? 'openrouter/free' : value == 'ollama' ? 'qwen2.5:3b' : 'deepseek-chat'; });
              }),
            const SizedBox(height: 8),
            TextField(controller: tutorModel, decoration: const InputDecoration(
              labelText: 'ID модели', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: tutorKey, obscureText: true,
              autocorrect: false, enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'API-ключ выбранного провайдера (если нужен)',
                border: OutlineInputBorder())),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(onPressed: configureTutor, icon: const Icon(Icons.save),
                label: const Text('Сохранить модель')),
              OutlinedButton.icon(onPressed: testTutor, icon: const Icon(Icons.play_circle_outline),
                label: const Text('Проверить ответ')),
            ]),
            if (tutorTestResult != null) Padding(padding: const EdgeInsets.only(top: 10),
              child: SelectableText(tutorTestResult!, style: const TextStyle(fontSize: 12))),
            const SizedBox(height: 8),
            const Text('OpenRouter: бесплатные модели ограничены квотой и могут быть недоступны из некоторых сетей. Ollama работает локально без внешнего API-ключа.',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const Divider(height: 28),
            Text('Silero: ${integrations['tts_installed'] == true ? 'библиотеки установлены' : 'не установлен'}'),
            Text('Распознавание речи: ${integrations['asr_installed'] == true ? 'библиотеки установлены' : 'не установлено'}'),
            const SizedBox(height: 8),
            Wrap(spacing: 9, runSpacing: 9, children: [
              FilledButton.tonalIcon(onPressed: installing ? null : () => installModel('tts'),
                icon: const Icon(Icons.volume_up), label: const Text('Скачать Silero')),
              FilledButton.tonalIcon(onPressed: installing ? null : () => installModel('asr'),
                icon: const Icon(Icons.mic), label: const Text('Скачать распознавание')),
              OutlinedButton.icon(onPressed: refresh, icon: const Icon(Icons.refresh),
                label: const Text('Обновить статус')),
            ]),
            const SizedBox(height: 8),
            for (final entry in ((integrations['model_jobs'] as Map<String, dynamic>?) ?? {}).entries)
              Text('${entry.key.toUpperCase()}: ${(entry.value as Map<String, dynamic>)['state']} — ${(entry.value as Map<String, dynamic>)['detail']}'),
            const SizedBox(height: 6),
            const Text('Модели могут занимать много места. Установка выполняется на сервере; не закрывай его во время скачивания.',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ))],
      ),
      ExpansionTile(title:const Text('Управление пользователями',style:TextStyle(fontWeight:FontWeight.bold)),children:[
        Padding(padding:const EdgeInsets.all(10),child:Column(children:[
          TextField(controller:search,decoration:InputDecoration(labelText:'Поиск аккаунта',suffixIcon:IconButton(onPressed:refresh,icon:const Icon(Icons.search)))),
          const SizedBox(height:8),
          for (final user in users) ListTile(title:Text('@${user['username']}'),
            subtitle:Text('${user['region']} · ${user['coins']} 🪙 · Telegram: ${user['telegram_linked'] == true ? 'да' : 'нет'}'),
            onTap:(){ username.text='${user['username']}'; coins.text='${user['coins']}'; region.text='${user['region']}'; }),
          TextField(controller:username,decoration:const InputDecoration(labelText:'Имя пользователя')),
          TextField(controller:coins,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Баланс монет (0–1 000 000)')),
          TextField(controller:region,decoration:const InputDecoration(labelText:'Полное название региона РФ (необязательно)')),
          const SizedBox(height:8), FilledButton.icon(onPressed:changeUser,icon:const Icon(Icons.save),label:const Text('Сохранить изменения')),
        ])),
      ]),
      ExpansionTile(title:Text('Школы и классы (${classes.length})',style:const TextStyle(fontWeight:FontWeight.bold)),children:[
        for (final school in classes) ListTile(leading:const Icon(Icons.school), title:Text('${school['school']} · ${school['name']}'),
          subtitle:Text('Учитель: ${school['teacher']} · Участников: ${school['students']}')),
      ]),
      ExpansionTile(title:Text('Спорные переводы (${reviews.length})',style:const TextStyle(fontWeight:FontWeight.bold)),children:[
        for (final item in reviews) ListTile(leading:const Icon(Icons.gavel),
          title:Text(item['text_ba'] as String? ?? ''),
          subtitle:Text('${item['language_pair']} · ${item['translation']}'),
          trailing:FilledButton.tonal(onPressed:()=>approve(item),child:const Text('Проверить'))),
        if (reviews.isEmpty) const ListTile(title:Text('Спорных переводов нет')),
      ]),
      ExpansionTile(title:Text('Заявки Night Project (${requests.length})',style:const TextStyle(fontWeight:FontWeight.bold)),children:[
        for (final item in requests) ListTile(leading:Icon(item['delivered']==true?Icons.check_circle:Icons.mail_outline),
          title:Text('@${item['username']}'), subtitle:SelectableText('${item['email']}'),
          trailing:item['delivered']==true?const Icon(Icons.check,color:Colors.green):TextButton(onPressed:()=>markDelivered(item['username'] as String),child:const Text('Выдано'))),
      ]),
      ExpansionTile(title:const Text('Журнал действий администратора',style:TextStyle(fontWeight:FontWeight.bold)),children:[
        OutlinedButton.icon(onPressed:copyAudit,icon:const Icon(Icons.copy),label:const Text('Скопировать JSON')),
        for (final item in audit.take(25)) ListTile(dense:true,title:Text('${item['action']} · ${item['target']}'),
          subtitle:Text('${item['at']}')),
      ]),
      const SizedBox(height:18),
      const Text('Операции сохраняются в журнале. Доступ к этому меню требует отдельной административной сессии.',
        style:TextStyle(fontSize:12,color:Colors.blueGrey)),
    ]));
}
