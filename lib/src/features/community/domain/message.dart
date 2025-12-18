/// Sistema de Mensagens Diretas (DM)

/// Conversa entre dois usuários
class Conversation {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Retorna o ID do outro participante
  String getOtherUserId(String currentUserId) {
    return participant1Id == currentUserId ? participant2Id : participant1Id;
  }

  Conversation copyWith({
    Message? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      participant1Id: participant1Id,
      participant2Id: participant2Id,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'participant1Id': participant1Id,
    'participant2Id': participant2Id,
    'lastMessage': lastMessage?.toJson(),
    'unreadCount': unreadCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'],
    participant1Id: json['participant1Id'],
    participant2Id: json['participant2Id'],
    lastMessage: json['lastMessage'] != null
        ? Message.fromJson(json['lastMessage'])
        : null,
    unreadCount: json['unreadCount'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

/// Mensagem individual
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.isRead = false,
    required this.createdAt,
  });

  Message copyWith({bool? isRead}) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'content': content,
    'type': type.name,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    conversationId: json['conversationId'],
    senderId: json['senderId'],
    content: json['content'],
    type: MessageType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => MessageType.text,
    ),
    isRead: json['isRead'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

enum MessageType {
  text,
  image,
  emoji,
  system, // Mensagem do sistema (ex: "Conversa iniciada")
}

/// DTO para criar mensagem
class CreateMessageDto {
  final String receiverId;
  final String content;
  final MessageType type;

  const CreateMessageDto({
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
  });
}
