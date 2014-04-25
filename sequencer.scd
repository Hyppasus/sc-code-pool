/*

A drum sequencer by Petri.
Contains five synthesised drums.

The note duration for all drums is controllable via a knob.
Another knob can be used for controlling the "deviation" or "randimisation" from that main duration, i.e. the possibility for other durations to occur.

Drums can be played / stopped individually with toggle buttons.

N.b. the duration knob does not trigger a modified pattern, only the deviation knob does (taking into account the set duration).

N.b. Midi CC# are hard-coded into the MIDIFuncs according to Korg nano Kontrol (scene 2, first knobs and first buttons). To change these to match another controller, just look for the 7 MIDIFuncs.

*/

(
Server.default.waitForBoot {

	Server.default = s;
	s.sync;

	// MIDI initialization

	MIDIClient.init;
	MIDIIn.connectAll;

	s.sync;

	// SynthDefs

	SynthDef(\kick, {|bus = 0, amp = 0.6|

		var pitchEnv = EnvGen.kr(Env.perc(0.001,0.2,1,-4), 1, doneAction: 2);
		var bd = SinOsc.ar(310 * pitchEnv);
		var volEnv = EnvGen.kr(Env.perc(0.001, 0.2, 1, -4), 1, doneAction: 2);

		Out.ar(bus, Pan2.ar(bd * volEnv, 0, amp));

	}).add;

	SynthDef(\snare, {|bus = 0, amp = 0.5|

		var pitchEnv = EnvGen.kr(Env.perc(0.01, 0.2, 1, -1), 1, doneAction:2);
		var snareTop = SinOsc.ar(100 * pitchEnv) - WhiteNoise.ar(0.5, 0.5);
		var snareBottom = PinkNoise.ar(1);
		var volEnv = EnvGen.kr(Env.perc(0.001, 0.2, 1, -10), 1, doneAction: 2);

		Out.ar(bus, Pan2.ar((snareTop + snareBottom) * volEnv, 0, amp));

	}).add;

	SynthDef(\hat, {|bus = 0, amp = 0.5|

		var pitchEnv = EnvGen.kr(Env([1.0, 0.2, 0.2], [0.5, 0.5]), 1, doneAction: 2);

		var hatNoise = PinkNoise.ar(1);
		var hatPing = SinOsc.ar(4000 * pitchEnv, mul: 0.5);
		var hatMod = SinOsc.ar(110, mul:0.2);
		var ringMod = hatPing * hatMod;

		var volEnv = EnvGen.kr(Env.perc(0.01, 0.01, 1, -20), 1, doneAction: 2);

		Out.ar(bus, Pan2.ar((ringMod + hatNoise) * volEnv, 0, amp));

	}).add;

	SynthDef(\hiTom, {|bus = 0, amp = 0.2|

		var pitchEnv = EnvGen.kr(Env.perc(0.001, 0.1, 1, -5), 1, doneAction:2);
		var tom = SinOsc.ar(600 * pitchEnv, mul: 0.5);
		var volEnv = EnvGen.kr(Env.perc(0.001, 0.3, 1, -1), 1, doneAction: 2);

		Out.ar(bus, Pan2.ar(tom * volEnv, 0, amp));

	}).add;

	SynthDef(\lowTom, {|bus = 0, amp = 0.05|

		var pitchEnv = EnvGen.kr(Env([1.0, 0.3, 0.2], [0.05, 0.4]), 1, doneAction:2);
		var tom = SinOsc.ar(400 * pitchEnv, mul: 0.5);
		var volEnv = EnvGen.kr(Env.perc(0.01, 0.1, 1, -1), 1, doneAction: 2);

		Out.ar(bus, Pan2.ar(tom * volEnv, 0, amp));

	}).add;

	s.sync;

	// Tempo

	TempoClock.default.tempo = 1;

	// MIDI knob mappings (note duration and deviation)

	~midiCC1 = 33;
	~midiCC2 = 34;
	~midiCC3 = 110;
	~midiCC4 = 111;
	~midiCC5 = 14;
	~midiCC6 = 15;
	~midiCC7 = 49;

	MIDIFunc.cc({|value, num, chan, src|

		var scaled = value.linlin(0, 127, 0, 3);

		if (scaled > 0.5, {~duration = 1}, {~duration = 2});
		if (scaled > 1, {~duration = 0.5});
		if (scaled > 1.5, {~duration = 0.25});
		if (scaled > 2, {~duration = 0.125});
		if (scaled > 2.5, {~duration = 0.0625});

	}, ~midiCC1);

	MIDIFunc.cc({|value, num, chan, src|

		var p = value.linlin(0, 127, 0.0000001, 1);

		if (~duration == 2, {
			~probabilities = [1, p, p/2, p/3, p/4, p/5].normalizeSum;
		});

		if (~duration == 1, {
			~probabilities = [p, 1, p, p/2, p/3, p/4].normalizeSum;
		});

		if (~duration == 0.5, {
			~probabilities = [p/2, p, 1, p, p/2, p/3].normalizeSum;
		});

		if (~duration == 0.25, {
			~probabilities = [p/3, p/2, p, 1, p, p/2].normalizeSum;
		});

		if (~duration == 0.125, {
			~probabilities = [p/4, p/3, p/2, p, 1, p].normalizeSum;
		});

		if (~duration == 0.0625, {
			~probabilities = [p/5, p/4, p/3, p/2, p, 1].normalizeSum;
		});


	}, ~midiCC2);

	// MIDI button mappings (drums play/stop)

	MIDIFunc.cc({|value|

		if (value == 127, {
			if (~kickPlay, {Pdef(\kickPattern).stop; ~kickPlay = false}, {Pdef(\kickPattern).play; ~kickPlay = true});
		});

	}, ~midiCC3);

	MIDIFunc.cc({|value|

		if (value == 127, {
			if (~snarePlay, {Pdef(\snarePattern).stop; ~snarePlay = false}, {Pdef(\snarePattern).play; ~snarePlay = true});
		});

	}, ~midiCC4);

	MIDIFunc.cc({|value|

		if (value == 127, {
			if (~hatPlay, {Pdef(\hatPattern).stop; ~hatPlay = false}, {Pdef(\hatPattern).play; ~hatPlay = true});
		});

	}, ~midiCC5);

	MIDIFunc.cc({|value|

		if (value == 127, {
			if (~hiTomPlay, {Pdef(\hiTomPattern).stop; ~hiTomPlay = false}, {Pdef(\hiTomPattern).play; ~hiTomPlay = true});
		});

	}, ~midiCC6);

	MIDIFunc.cc({|value|

		if (value == 127, {
			if (~lowTomPlay, {Pdef(\lowTomPattern).stop; ~lowTomPlay = false}, {Pdef(\lowTomPattern).play; ~lowTomPlay = true});
		});

	}, ~midiCC7);

	s.sync;

	// Instrument-control bindings

	Pdef(\kickPattern, Pbind(\instrument, \kick, \dur, Pwrand([2, 1, 0.5, 0.25, 0.125, 0.0625], Pfunc{~probabilities}, inf)));
	Pdef(\snarePattern, Pbind(\instrument, \snare, \dur, Pwrand([2, 1, 0.5, 0.25, 0.125, 0.0625], Pfunc{~probabilities}, inf)));
	Pdef(\hatPattern, Pbind(\instrument, \hat, \dur, Pwrand([2, 1, 0.5, 0.25, 0.125, 0.0625], Pfunc{~probabilities}, inf)));
	Pdef(\hiTomPattern, Pbind(\instrument, \hiTom, \dur, Pwrand([2, 1, 0.5, 0.25, 0.125, 0.0625], Pfunc{~probabilities}, inf)));
	Pdef(\lowTomPattern, Pbind(\instrument, \lowTom, \dur, Pwrand([2, 1, 0.5, 0.25, 0.125, 0.0625], Pfunc{~probabilities}, inf)));

	s.sync;

	// Play!

	Pdef(\kickPattern).play;
	Pdef(\snarePattern).play;
	Pdef(\hatPattern).play;
	Pdef(\hiTomPattern).play;
	Pdef(\lowTomPattern).play;

	// (and flag playing drums)

	~kickPlay = true;
	~snarePlay = true;
	~hatPlay = true;
	~hiTomPlay = true;
	~lowTomPlay = true;

}
)

//Pdef.clear; // (just in case...)