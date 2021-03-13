class DataChunk {
  final String id;
  final int? length;
  final List<int> bytes;
  DataChunk({required this.id, this.length, required this.bytes});
}