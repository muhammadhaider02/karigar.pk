// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';

Stream<Map<String, dynamic>> webStreamSession(String url) {
  final controller = StreamController<Map<String, dynamic>>();
  final es = html.EventSource(url);

  void emit(String eventType, html.Event event) {
    final me = event as html.MessageEvent;
    final raw = me.data;
    if (raw is String && raw.isNotEmpty) {
      try {
        controller.add({'event': eventType, 'data': json.decode(raw)});
      } catch (_) {
        controller.add({'event': eventType, 'data': raw});
      }
    }
    if (eventType == 'done') {
      es.close();
      controller.close();
    }
  }

  es.addEventListener('trace', (e) => emit('trace', e));
  es.addEventListener('done', (e) => emit('done', e));
  es.addEventListener('ping', (e) => emit('ping', e));
  es.addEventListener('slot_conflict', (e) => emit('slot_conflict', e));

  es.onError.listen((_) {
    if (!controller.isClosed) {
      controller.addError('EventSource error');
      es.close();
      controller.close();
    }
  });

  controller.onCancel = () {
    es.close();
  };

  return controller.stream;
}
