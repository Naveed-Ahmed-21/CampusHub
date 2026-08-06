abstract class ChatRemoteDataSource {
  Future<List<dynamic>> fetchRoomMessages(String roomId);
}
