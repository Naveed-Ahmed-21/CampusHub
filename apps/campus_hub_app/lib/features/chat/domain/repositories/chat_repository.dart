abstract class ChatRepository {
  Future<List<dynamic>> getRoomMessages(String roomId);
}
