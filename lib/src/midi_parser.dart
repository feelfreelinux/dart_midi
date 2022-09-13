import 'package:dart_midi/src/byte_reader.dart';
import 'package:dart_midi/src/midi_events.dart';
import 'package:dart_midi/src/midi_file.dart';
import 'package:dart_midi/src/midi_header.dart';
import 'dart:io';

/// MidiParser is a class responsible of parsing MIDI data into dart objects
class MidiParser {
  int? _lastEventTypeByte;

  MidiParser();

  /// Reads a midi file from provided [buffer]
  ///
  /// Returns parsed [MidiFile]
  MidiFile parseMidiFromBuffer(List<int> buffer) {
    var p = new ByteReader(buffer);

    var headerChunk = p.readChunk();
    if (headerChunk.id != 'MThd')
      throw "Bad MIDI file.  Expected 'MHdr', got: '${headerChunk.id}'";
    var header = parseHeader(headerChunk.bytes);

    List<List<MidiEvent>> tracks = [];
    for (var i = 0; !p.eof && i < header.numTracks; i++) {
      var trackChunk = p.readChunk();
      if (trackChunk.id != 'MTrk')
        throw "Bad MIDI file.  Expected 'MTrk', got: '${trackChunk.id}'";
      var track = parseTrack(trackChunk.bytes);
      tracks.add(track);
    }

    return MidiFile(tracks, header);
  }

  /// Reads a provided byte [data] into [MidiHeader]
  MidiHeader parseHeader(List<int> data) {
    final ByteReader p = ByteReader(data);

    final int format = p.readUInt16();
    final int numTracks = p.readUInt16();
    int? framesPerSecond;
    int? ticksPerFrame;
    int? ticksPerBeat;

    final int timeDivision = p.readUInt16();
    if (timeDivision & 0x8000 != 0) {
      framesPerSecond = 0x100 - (timeDivision >> 8);
      ticksPerFrame = timeDivision & 0xFF;
    } else {
      ticksPerBeat = timeDivision;
    }

    return MidiHeader(
      format: format,
      framesPerSecond: framesPerSecond,
      numTracks: numTracks,
      ticksPerBeat: ticksPerBeat,
      ticksPerFrame: ticksPerFrame,
    );
  }

  /// Parses provided [file] and returns [MidiFile]
  MidiFile parseMidiFromFile(File file) {
    return parseMidiFromBuffer(file.readAsBytesSync());
  }

  /// Reads event from provided [p] and returns parsed [MidiEvent]
  MidiEvent readEvent(ByteReader p) {
    var deltaTime = p.readVarInt();

    var eventTypeByte = p.readUInt8();

    if ((eventTypeByte & 0xf0) == 0xf0) {
      // system / meta event
      if (eventTypeByte == 0xff) {
        // meta event
        final int metatypeByte = p.readUInt8();
        final int length = p.readVarInt();
        switch (metatypeByte) {
          case 0x00:
            final SequenceNumberEvent event = SequenceNumberEvent();
            event.deltaTime = deltaTime;
            event.type = 'sequenceNumber';
            if (length != 2)
              throw 'Expected length for sequenceNumber event is 2, got ${length.toString()}';
            event.number = p.readUInt16();
            return event;
          case 0x01:
            var event = TextEvent();
            event.type = 'text';
            event.deltaTime = deltaTime;
            event.text = p.readString(length);
            return event;
          case 0x02:
            var event = CopyrightNoticeEvent();
            event.type = 'copyrightNotice';
            event.deltaTime = deltaTime;
            event.text = p.readString(length);
            return event;
          case 0x03:
            var event = TrackNameEvent();
            event.type = 'trackName';
            event.deltaTime = deltaTime;
            event.text = p.readString(length);
            return event;
          case 0x04:
            var event = InstrumentNameEvent();
            event.type = 'instrumentName';
            event.deltaTime = deltaTime;
            event.text = p.readString(length);
            return event;
          case 0x05:
            var event = LyricsEvent();
            event.type = 'lyrics';
            event.deltaTime = deltaTime;
            event.text = p.readString(length);
            return event;
          case 0x06:
            var event = MarkerEvent();
            event.type = 'marker';
            event.deltaTime = deltaTime;
            event.text = p.readString(length);
            return event;
          case 0x07:
            var event = CuePointEvent();
            event.type = 'cuePoint';
            event.deltaTime = deltaTime;
            event.text = p.readString(length);
            return event;
          case 0x20:
            var event = ChannelPrefixEvent();
            event.type = 'channelPrefix';
            event.deltaTime = deltaTime;
            if (length != 1)
              throw 'Expected length for channelPrefix event is 1, got ${length.toString()}';
            event.deltaTime = deltaTime;
            event.channel = p.readUInt8();
            return event;
          case 0x21:
            var event = PortPrefixEvent();
            event.type = 'portPrefix';

            event.deltaTime = deltaTime;
            if (length != 1)
              throw 'Expected length for portPrefix event is 1, got ${length.toString()}';
            event.port = p.readUInt8();
            return event;
          case 0x2f:
            var event = EndOfTrackEvent();
            event.deltaTime = deltaTime;
            event.type = 'endOfTrack';
            if (length != 0)
              throw 'Expected length for endOfTrack event is 0, got ${length.toString()}';
            return event;
          case 0x51:
            final event = SetTempoEvent();
            event.deltaTime = deltaTime;
            event.type = 'setTempo';
            ;
            if (length != 3)
              throw 'Expected length for setTempo event is 3, got ${length.toString()}';
            event.microsecondsPerBeat = p.readUInt24();
            return event;
          case 0x54:
            var event = SmpteOffsetEvent();
            event.deltaTime = deltaTime;
            event.type = 'smpteOffset';
            if (length != 5)
              throw 'Expected length for smpteOffset event is 5, got ${length.toString()}';
            var hourByte = p.readUInt8();
            var frameRates = {0x00: 24, 0x20: 25, 0x40: 29, 0x60: 30};
            event.frameRate = frameRates[hourByte & 0x60]!;
            event.hour = hourByte & 0x1f;
            event.min = p.readUInt8();
            event.sec = p.readUInt8();
            event.frame = p.readUInt8();
            event.subFrame = p.readUInt8();
            return event;
          case 0x58:
            var event = TimeSignatureEvent();
            event.deltaTime = deltaTime;
            event.type = 'timeSignature';
            if (length != 4)
              throw 'Expected length for timeSignature event is 4, got ${length.toString()}';
            event.numerator = p.readUInt8();
            event.denominator = (1 << p.readUInt8());
            event.metronome = p.readUInt8();
            event.thirtyseconds = p.readUInt8();
            return event;
          case 0x59:
            var event = KeySignatureEvent();
            event.deltaTime = deltaTime;
            event.type = 'keySignature';
            if (length != 2)
              throw 'Expected length for keySignature event is 2, got ${length.toString()}';
            event.key = p.readInt8();
            event.scale = p.readUInt8();
            return event;
          case 0x7f:
            var event = SequencerSpecificEvent();
            event.deltaTime = deltaTime;
            event.type = 'sequencerSpecific';
            event.data = p.readBytes(length);
            return event;
          default:
            var event = UnknownMetaEvent();
            event.deltaTime = deltaTime;
            event.type = 'unknownMeta';
            event.data = p.readBytes(length);
            event.metatypeByte = metatypeByte;
            return event;
        }
      } else if (eventTypeByte == 0xf0) {
        var event = SystemExclusiveEvent();
        event.deltaTime = deltaTime;
        event.type = 'sysEx';
        var length = p.readVarInt();
        event.data = p.readBytes(length);
        return event;
      } else if (eventTypeByte == 0xf7) {
        var event = EndSystemExclusiveEvent();
        event.deltaTime = deltaTime;
        event.type = 'endSysEx';
        var length = p.readVarInt();
        event.data = p.readBytes(length);
        return event;
      } else {
        throw 'Unrecognised MIDI event type byte: ${eventTypeByte.toString()}';
      }
    } else {
      // channel event
      int param1;
      bool running = false;
      if ((eventTypeByte & 0x80) == 0) {
        // running status - reuse lastEventTypeByte as the event type.
        // eventTypeByte is actually the first parameter
        if (_lastEventTypeByte == null)
          throw "Running status byte encountered before status byte";
        param1 = eventTypeByte;
        eventTypeByte = _lastEventTypeByte!;
        running = true;
      } else {
        param1 = p.readUInt8();
        _lastEventTypeByte = eventTypeByte;
      }
      var eventType = eventTypeByte >> 4;
      var channel = eventTypeByte & 0x0f;
      switch (eventType) {
        case 0x08:
          var event = NoteOffEvent();
          event.deltaTime = deltaTime;
          event.type = 'noteOff';
          event.running = running;
          event.channel = channel;
          event.noteNumber = param1;
          event.velocity = p.readUInt8();
          return event;
        case 0x09:
          var velocity = p.readUInt8();
          if (velocity == 0) {
            var event = NoteOffEvent();
            event.deltaTime = deltaTime;
            event.channel = channel;
            event.type = 'noteOff';
            event.noteNumber = param1;
            event.velocity = velocity;
            event.running = running;
            if (velocity == 0) event.byte9 = true;
            return event;
          } else {
            var event = NoteOnEvent();
            event.deltaTime = deltaTime;
            event.type = 'noteOn';

            event.channel = channel;
            event.running = running;
            event.noteNumber = param1;
            event.velocity = velocity;
            if (velocity == 0) event.byte9 = true;
            return event;
          }
        case 0x0a:
          var event = NoteAfterTouchEvent();
          event.channel = channel;
          event.deltaTime = deltaTime;
          event.noteNumber = param1;
          event.running = running;
          event.amount = p.readUInt8();
          return event;
        case 0x0b:
          var event = ControllerEvent();
          event.channel = channel;
          event.running = running;
          event.deltaTime = deltaTime;
          event.type = 'controller';
          event.controllerType = param1;
          event.value = p.readUInt8();
          return event;
        case 0x0c:
          var event = ProgramChangeMidiEvent();
          event.channel = channel;
          event.deltaTime = deltaTime;
          event.type = 'programChange';
          event.programNumber = param1;
          event.running = running;
          return event;
        case 0x0d:
          var event = ChannelAfterTouchEvent();
          event.channel = channel;
          event.deltaTime = deltaTime;
          event.type = 'channelAftertouch';
          event.amount = param1;
          event.running = running;
          return event;
        case 0x0e:
          var event = PitchBendEvent();
          event.channel = channel;
          event.deltaTime = deltaTime;
          event.running = running;
          event.type = 'pitchBend';
          event.value = (param1 + (p.readUInt8() << 7)) - 0x2000;
          return event;
        default:
          throw 'Unrecognised MIDI event type: ${eventType.toString()}';
      }
    }
  }

  /// Parses provided [data] and returns a list of [MidiEvent]
  List<MidiEvent> parseTrack(List<int> data) {
    var p = new ByteReader(data);

    List<MidiEvent> events = [];
    int tickFromStart = 0;
    while (!p.eof) {
      var event = readEvent(p);
      tickFromStart += event.deltaTime;
      event.tickFromStart = tickFromStart;
      events.add(event);
    }
    for (int i = 0; i < events.length; i++) {
      if (events[i] is NoteOnEvent) {
        NoteOnEvent noteOn = events[i] as NoteOnEvent;
        for (int j = i; j < events.length; j++) {
          if (events[j] is NoteOffEvent) {
            NoteOffEvent noteOff = events[j] as NoteOffEvent;
            if (noteOn.noteNumber == noteOff.noteNumber &&
                noteOn.channel == noteOff.channel) {
              noteOn.duration = noteOff.tickFromStart - noteOn.tickFromStart;
              break;
            }
          }
        }
      }
    }
    return events;
  }
}
