import 'dart:math';

import 'package:midi/src/byte_writer.dart';

abstract class MidiEvent {
  String type;
  int deltaTime = 0;
  bool meta = false;
  bool running = false;

  // ByteWriter stuff
  int lastEventTypeByte;
  bool useByte9ForNoteOff = false;

  int writeEvent(ByteWriter w);
}

class SequenceNumberEvent extends MidiEvent {
  int number;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x00);
    w.writeVarInt(2);
    w.writeUInt16(number);
    return -1;
  }
}

class EndOfTrackEvent extends MidiEvent {
  bool meta = true;
  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x2F);
    w.writeVarInt(0);
    return -1;
  }
}

class ProgramChangeMidiEvent extends MidiEvent {
  int channel;
  int programNumber;
  int writeEvent(ByteWriter w) {
    var eventTypeByte = 0xC0 | channel;
    if (eventTypeByte != lastEventTypeByte) w.writeUInt8(eventTypeByte);
    w.writeUInt8(programNumber);
    return eventTypeByte;
  }
}

class ChannelAfterTouchEvent extends MidiEvent {
  int channel;
  int amount;

  int writeEvent(ByteWriter w) {
    var eventTypeByte = 0xD0 | channel;
    if (eventTypeByte != lastEventTypeByte) w.writeUInt8(eventTypeByte);
    w.writeUInt8(amount);
    return eventTypeByte;
  }
}

class PitchBendEvent extends MidiEvent {
  int channel;
  int value;

  int writeEvent(ByteWriter w) {
    var eventTypeByte = 0xE0 | channel;
    if (eventTypeByte != lastEventTypeByte) w.writeUInt8(eventTypeByte);
    var value14 = 0x2000 + value;
    var lsb14 = (value14 & 0x7F);
    var msb14 = (value14 >> 7) & 0x7F;
    w.writeUInt8(lsb14);
    w.writeUInt8(msb14);
    return eventTypeByte;
  }
}

class ControllerEvent extends MidiEvent {
  int controllerType;
  int channel;
  int value;
  int number;

  int writeEvent(ByteWriter w) {
    var eventTypeByte = 0xB0 | channel;
    if (eventTypeByte != lastEventTypeByte) w.writeUInt8(eventTypeByte);
    w.writeUInt8(controllerType);
    w.writeUInt8(value);
    return eventTypeByte;
  }
}

class NoteOnEvent extends MidiEvent {
  int noteNumber;
  int velocity;
  int channel;
  bool byte9 = false;

  int writeEvent(ByteWriter w) {
    var eventTypeByte = 0x90 | channel;
    if (eventTypeByte != lastEventTypeByte) w.writeUInt8(eventTypeByte);
    w.writeUInt8(noteNumber);
    w.writeUInt8(velocity);
    return eventTypeByte;
  }
}

class NoteAfterTouchEvent extends MidiEvent {
  int noteNumber;
  int amount;
  int channel;

  int writeEvent(ByteWriter w) {
    var eventTypeByte = 0xA0 | channel;
    if (eventTypeByte != lastEventTypeByte) w.writeUInt8(eventTypeByte);
    w.writeUInt8(noteNumber);
    w.writeUInt8(amount);
    return eventTypeByte;
  }
}

class NoteOffEvent extends MidiEvent {
  int noteNumber;
  int channel;
  int velocity;
  bool byte9 = false;

  int writeEvent(ByteWriter w) {
    // Use 0x90 when opts.useByte9ForNoteOff is set and velocity is zero, or when event.byte9 is explicitly set on it.
    // parseMidi will set event.byte9 for each event, so that we can get an exact copy by default.
    // Explicitly set opts.useByte9ForNoteOff to false, to override event.byte9 and always use 0x80 for noteOff events.
    var noteByte = ((useByte9ForNoteOff != false && byte9) ||
            (useByte9ForNoteOff && velocity == 0))
        ? 0x90
        : 0x80;

    var eventTypeByte = noteByte | channel;
    if (eventTypeByte != lastEventTypeByte) w.writeUInt8(eventTypeByte);
    w.writeUInt8(noteNumber);
    w.writeUInt8(velocity);
    return eventTypeByte;
  }
}

class TextEvent extends MidiEvent {
  String text;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x01);
    w.writeVarInt(text.length);
    w.writeString(text);
    return -1;
  }
}

class CopyrightNoticeEvent extends MidiEvent {
  String text;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x02);
    w.writeVarInt(text.length);
    w.writeString(text);
    return -1;
  }
}

class LyricsEvent extends MidiEvent {
  String text;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x05);
    w.writeVarInt(text.length);
    w.writeString(text);
    return -1;
  }
}

class MarkerEvent extends MidiEvent {
  String text;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x06);
    w.writeVarInt(text.length);
    w.writeString(text);
    return -1;
  }
}

class CuePointEvent extends MidiEvent {
  String text;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x07);
    w.writeVarInt(text.length);
    w.writeString(text);
    return -1;
  }
}

class InstrumentNameEvent extends MidiEvent {
  String text;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x04);
    w.writeVarInt(text.length);
    w.writeString(text);
    return -1;
  }
}

class TrackNameEvent extends MidiEvent {
  String text;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x03);
    w.writeVarInt(text.length);
    w.writeString(text);
    return -1;
  }
}

class ChannelPrefixEvent extends MidiEvent {
  int channel;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x20);
    w.writeVarInt(1);
    w.writeUInt8(channel);
    return -1;
  }
}

class PortPrefixEvent extends MidiEvent {
  int port;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x21);
    w.writeVarInt(1);
    w.writeUInt8(port);
    return -1;
  }
}

class SetTempoEvent extends MidiEvent {
  int microsecondsPerBeat;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x51);
    w.writeVarInt(3);
    w.writeUInt24(microsecondsPerBeat);
    return -1;
  }
}

class SequencerSpecificEvent extends MidiEvent {
  List<int> data;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x7F);
    w.writeVarInt(data.length);
    w.writeBytes(data);

    return -1;
  }
}

class SystemExclusiveEvent extends MidiEvent {
  List<int> data;
  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xF0);
    w.writeVarInt(data.length);
    w.writeBytes(data);

    return -1;
  }
}

class EndSystemExclusiveEvent extends MidiEvent {
  List<int> data;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xF7);
    w.writeVarInt(data.length);
    w.writeBytes(data);
    return -1;
  }
}

class UnknownMetaEvent extends MidiEvent {
  bool meta = true;

  List<int> data;
  int metatypeByte;

  int writeEvent(ByteWriter w) {
    if (metatypeByte != null) {
      w.writeUInt8(0xFF);
      w.writeUInt8(metatypeByte);
      w.writeVarInt(data.length);
      w.writeBytes(data);
    }

    return -1;
  }
}

class SmpteOffsetEvent extends MidiEvent {
  bool meta = true;

  int frameRate;
  int hour;
  int min;
  int sec;
  int frame;
  int subFrame;
  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x54);
    w.writeVarInt(5);
    var frameRates = {24: 0x00, 25: 0x20, 29: 0x40, 30: 0x60};
    var hourByte = (hour & 0x1F) | frameRates[frameRate];
    w.writeUInt8(hourByte);
    w.writeUInt8(min);
    w.writeUInt8(sec);
    w.writeUInt8(frame);
    w.writeUInt8(subFrame);
    return -1;
  }
}

class TimeSignatureEvent extends MidiEvent {
  bool meta = true;

  int numerator;
  int denominator;
  int metronome;
  int thirtyseconds;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x58);
    w.writeVarInt(4);
    w.writeUInt8(numerator);
    var _denominator = (log(denominator) / ln2).floor() & 0xFF;
    w.writeUInt8(_denominator);
    w.writeUInt8(metronome);
    w.writeUInt8(thirtyseconds ?? 8);
    return -1;
  }
}

class KeySignatureEvent extends MidiEvent {
  int key;
  int scale;
  bool meta = true;

  int writeEvent(ByteWriter w) {
    w.writeUInt8(0xFF);
    w.writeUInt8(0x59);
    w.writeVarInt(2);
    w.writeInt8(key);
    w.writeUInt8(scale);
    return -1;
  }
}