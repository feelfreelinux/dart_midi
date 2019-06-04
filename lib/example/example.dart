import 'dart:io';

import 'package:dart_midi/dart_midi.dart';

void main() {
  // Open a file containing midi data
  var file = File('sample_midi.mid');

  // Construct a midi parser
  var parser = MidiParser();

  // Parse midi directly from file. You can also use parseMidiFromBuffer to directly parse List<int>
  MidiFile parsedMidi = parser.parseMidiFromFile(file);

  // You can now access your parsed [MidiFile]
  print(parsedMidi.tracks.length.toString());

  // Construct a midi writer
  var writer = MidiWriter();

  // Let's write and encode our midi data again
  // You can also control `running` flag to compress file and  `useByte9ForNoteOff` to use 0x09 for noteOff when velocity is zero
  writer.writeMidiToFile(parsedMidi, File('output.mid'));
}
