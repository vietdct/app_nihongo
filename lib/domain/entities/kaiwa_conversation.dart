/// 1 phiên hội thoại của người dùng với 1 persona trong 1 scenario.
class KaiwaConversation {
  const KaiwaConversation({
    required this.id,
    required this.personaId,
    required this.scenarioId,
    required this.startedAt,
    required this.lastMessageAt,
  });

  final String id;
  final String personaId;
  final String scenarioId;
  final DateTime startedAt;
  final DateTime lastMessageAt;
}
