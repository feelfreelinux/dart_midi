import 'dart:io';

import 'package:dart_midi/src/byte_writer.dart';
import 'package:dart_midi/src/data_chunk.dart';
import 'package:dart_midi/src/midi_events.dart';
import 'package:dart_midi/src/midi_file.dart';
import 'package:dart_midi/src/midi_header.dart';

class MidiWriter {
  MidiWriter();

  /// Converts a [MidiFile] to byte buffer represented by [List<int>]
  ///
  /// [running] reuse previous eventTypeByte when possible, to compress file
  /// [useByte9ForNoteOff] use 0x09 for noteOff when velocity is zero
  List<int> writeMidiToBuffer(MidiFile file,
      {bool running = false, bool useByte9ForNoteOff = false}) {
    var w = new ByteWriter();
    writeHeader(w, file.header, file.tracks.length);

    file.tracks.forEach((f) => writeTrack(w, f));

    return w.buffer;
  }

  /// Writes [midiFile] as bytes into a provided [file]
  ///
  /// [running] reuse previous eventTypeByte when possible, to compress file
  /// [useByte9ForNoteOff] use 0x09 for noteOff when velocity is zero
  void writeMidiToFile(MidiFile midiFile, File file,
      {bool running = false, bool useByte9ForNoteOff = false}) {
    var bytes = this.writeMidiToBuffer(midiFile);
    file.writeAsBytesSync(bytes);
  }

  /// Writes a midi track
  void writeTrack(ByteWriter w, List<MidiEvent> track,
      {bool running = false, bool useByte9ForNoteOff = false}) {
    var t = new ByteWriter();
    int i, len = track.length;
    int? eventTypeByte;
    for (i = 0; i < len; i++) {
      // Reuse last eventTypeByte when opts.running is set, or event.running is explicitly set on it.
      // parseMidi will set event.running for each event, so that we can get an exact copy by default.
      // Explicitly set opts.running to false, to override event.running and never reuse last eventTypeByte.
      if (running == false || !running && !track[i].running)
        eventTypeByte = null;

      var event = track[i];
      event.lastEventTypeByte = eventTypeByte;
      event.useByte9ForNoteOff = useByte9ForNoteOff;

      t.writeVarInt(event.deltaTime);
      eventTypeByte = event.writeEvent(t);
    }

    w.writeChunk(DataChunk(id: 'MTrk', bytes: t.buffer));
  }

  /// Writes provided [header] into [w]
  void writeHeader(ByteWriter w, MidiHeader header, int numTracks) {
    var headerFormat = header.format;
    int format = headerFormat == null ? 1 : headerFormat;

    var timeDivision = 128;
    var headerTimeDivision = header.timeDivision;
    var headerFramesPerSecond = header.framesPerSecond;
    var headerTicksPerFrame = header.ticksPerFrame;
    if (headerTimeDivision != null) {
      timeDivision = headerTimeDivision;
    } else if (headerTicksPerFrame != null && headerFramesPerSecond != null) {
      timeDivision =
          (-(headerFramesPerSecond & 0xFF) << 8) | (headerTicksPerFrame & 0xFF);
    } else if (header.ticksPerBeat != 0) {
      timeDivision = header.ticksPerBeat & 0x7FFF;
    }

    var h = new ByteWriter();
    h.writeUInt16(format);
    h.writeUInt16(numTracks);
    h.writeUInt16(timeDivision);

    w.writeChunk(DataChunk(id: 'MThd', bytes: h.buffer));
  }
}
