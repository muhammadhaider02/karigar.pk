class ToolCall {
  final String name;
  final Map<String, dynamic> args;
  final dynamic result;
  final int latencyMs;

  ToolCall({
    required this.name,
    required this.args,
    this.result,
    required this.latencyMs,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
        name: json['name'] ?? '',
        args: Map<String, dynamic>.from(json['args'] ?? {}),
        result: json['result'],
        latencyMs: json['latency_ms'] ?? 0,
      );
}

class AgentTraceEvent {
  final int step;
  final String agent;
  final String phase;
  final Map<String, dynamic> input;
  final Map<String, dynamic> output;
  final List<ToolCall> toolCalls;
  final int latencyMs;
  final String reasoning;
  final String? triggeredBy;

  // UI-compatibility aliases
  int get stage => step;
  int get durationMs => latencyMs;
  String get status => 'completed';

  // Backend doesn't send these in SSE trace events — populated via session snapshot
  List<dynamic>? get candidateProviders => null;
  String? get antigravityDecision => null;

  AgentTraceEvent({
    required this.step,
    required this.agent,
    required this.phase,
    required this.input,
    required this.output,
    required this.toolCalls,
    required this.latencyMs,
    required this.reasoning,
    this.triggeredBy,
  });

  factory AgentTraceEvent.fromJson(Map<String, dynamic> json) {
    return AgentTraceEvent(
      step: json['step'] ?? 0,
      agent: json['agent'] ?? '',
      phase: json['phase'] ?? '',
      input: Map<String, dynamic>.from(json['input'] ?? {}),
      output: Map<String, dynamic>.from(json['output'] ?? {}),
      toolCalls: (json['tool_calls'] as List? ?? [])
          .map((t) => ToolCall.fromJson(t as Map<String, dynamic>))
          .toList(),
      latencyMs: json['latency_ms'] ?? 0,
      reasoning: json['reasoning'] ?? '',
      triggeredBy: json['triggered_by'],
    );
  }
}
