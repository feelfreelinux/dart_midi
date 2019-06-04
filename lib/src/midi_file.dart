import 'package:midi/src/midi_events.dart';
import 'package:midi/src/midi_header.dart';

class MidiFile {
  final List<List<MidiEvent>> tracks;
  final MidiHeader header;
  MidiFile(this.tracks, this.header);
}