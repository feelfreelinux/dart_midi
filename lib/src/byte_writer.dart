import 'package:dart_midi/src/data_chunk.dart';

class ByteWriter {
  final List<int> buffer = [];
  int pos = 0;
  bool get eof => this.pos >= buffer.length;

  ByteWriter();

  void writeUInt8(int v) {
    this.buffer.add(v & 0xFF);
  }

  void writeInt8(int v) => writeUInt8(v);

  void writeUInt16(int v) {
    var b0 = (v >> 8) & 0xFF, b1 = v & 0xFF;

    this.writeUInt8(b0);
    this.writeUInt8(b1);
  }

  void writeInt16(int v) => writeUInt16(v);

  void writeUInt24(int v) {
    var b0 = (v >> 16) & 0xFF, b1 = (v >> 8) & 0xFF, b2 = v & 0xFF;

    this.writeUInt8(b0);
    this.writeUInt8(b1);
    this.writeUInt8(b2);
  }

  void writeInt24(int v) => writeUInt24(v);

  void writeUInt32(int v) {
    var b0 = (v >> 24) & 0xFF,
        b1 = (v >> 16) & 0xFF,
        b2 = (v >> 8) & 0xFF,
        b3 = v & 0xFF;

    this.writeUInt8(b0);
    this.writeUInt8(b1);
    this.writeUInt8(b2);
    this.writeUInt8(b3);
  }

  void writeBytes(List<int> bytes) {
    this.buffer.addAll(bytes);
  }

  void writeString(String str) {
    int i, len = str.length;
    List<int> arr = [];

    for (i = 0; i < len; i++) {
      arr.add(str.codeUnitAt(i));
    }
    this.writeBytes(arr);
  }

  void writeVarInt(int v) {
    if (v < 0) throw "Cannot write negative variable-length integer";

    if (v <= 0x7F) {
      this.writeUInt8(v);
    } else {
      var i = v;
      List<int> bytes = [];
      bytes.add(i & 0x7F);
      i >>= 7;
      while (i != 0) {
        var b = i & 0x7F | 0x80;
        bytes.add(b);
        i >>= 7;
      }
      this.writeBytes(bytes.reversed.toList());
    }
  }

  void writeChunk(DataChunk chunk) {
    this.writeString(chunk.id);
    this.writeUInt32(chunk.bytes.length);
    this.writeBytes(chunk.bytes);
  }
}