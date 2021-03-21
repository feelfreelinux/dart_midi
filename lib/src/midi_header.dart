class MidiHeader {
  final int? framesPerSecond;
  final int? ticksPerBeat;
  final int? ticksPerFrame;
  final int numTracks;
  final int format;
  final int? timeDivision;

  MidiHeader(
      {this.framesPerSecond,
      this.ticksPerBeat,
      required this.format,
      required this.numTracks,
      this.ticksPerFrame,
      this.timeDivision});
}