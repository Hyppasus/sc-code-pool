// Use id node 1010 for the carrier and 1030 for the modulator
// use buttons to change the wave form
// we need a button to activate the modulation
// another button could activate the type of modulation amplitude modulation or frequency modulation
// another button could change the type of interaction between the two oscillators, i.e. adding delays with lag

// WE NEED LEDS!!!!! 8??

/*############################################################################################################*/
// The concept:

~busModulator = Bus.control(s,1);
~busModulator.index;
// or setting a value in a bus creates it, so let's use message style instead objects
s.sendMsg(\c_set, 400, 300);
// control bus will be on id 400


//s.sendMsg(\g_new, 1000, 1, 1);
s.sendMsg(\s_new, "carPulse", 1010, 1, 1);
s.sendMsg(\s_new, "carSine", 1011, 4, 1010);
s.sendMsg(\s_new, "carPulse", 1010, 4, 1011);

//s.sendMsg(\n_map, 1010, "freq", ~busModulator.index);
s.sendMsg(\n_map, 1010, "freq", 400);


//s.sendMsg(\c_set, ~busModulator.index, 300);
//s.sendMsg(\c_set, ~busModulator.index, 600);
s.sendMsg(\c_set, 400, 600);
s.sendMsg(\c_set, 400, 300);
s.sendMsg(\c_set, 400, 700);
//s.sendMsg(\s_new, "modPulse", 1030, 1, 1, \bus, ~busModulator.index, \freq, 1, \mul, 1000);
s.sendMsg(\s_new, "modPulse", 1030, 1, 1, \bus, 400, \freq, 1, \mul, 1000);
s.sendMsg(\n_set, 1030, \freq, 300, \mul, 10000, \add, 20)
s.sendMsg(\n_set, 1030, \freq, 1, \mul, 1, \add, 1)
s.sendMsg(\n_set, 1030, \freq, 1, \mul, 100, \add, 100)


/*############################################################################################################*/

// send several messages to the server, creating a new synth, mapping the frequency to the bus and mapping to the modulator

(
s.sendBundle(nil,
	[\s_new, "carPulse", 1010, 1, 1],
	[\n_map, 1010, "freq", 400],
	[\s_new, "modPulse", 1030, 1, 1, \bus, 400, \freq, 1, \mul, 1000]
);
);

s.sendMsg(\n_set, 1030, \freq, 1, \mul, 100, \add, 100)

(
s.sendBundle(nil,
	[\n_free, 1010],
	[\n_free, 1030],
	[\s_new, "carSine", 1010, 1, 1],
	[\n_map, 1010, "freq", 400],
	[\s_new, "modPulse", 1030, 1, 1, \bus, 400, \freq, 1, \mul, 1000]
);
);

// using the envelop and schedulling 0.2 sec for chenging the wave form
(
s.sendBundle(nil,[\n_set, 1010, \gate, -0.2],[\n_free,1030]);
s.sendBundle(0.2,
	[\s_new, "carSaw", 1010, 1, 1],
	[\n_map, 1010, "freq", 400],
	[\s_new, "modPulse", 1030, 1, 1, \bus, 400, \freq, 1, \mul, 1000]
);
);

(
s.sendBundle(nil,[\n_set, 1010, \gate, -0.2],[\n_free,1030]);
s.sendBundle(0.2,
	[\s_new, "carSine", 1010, 1, 1],
	[\n_map, 1010, "freq", 400],
	[\s_new, "modPulse", 1030, 1, 1, \bus, 400, \freq, 1, \mul, 1000]
);
);

(
s.sendBundle(nil,[\n_set, 1010, \gate, -0.2],[\n_free,1030]);
s.sendBundle(0.2,
	[\s_new, "carSine", 1010, 1, 1],
	[\n_map, 1010, "freq", 400],
	[\s_new, "modGendy", 1030, 1, 1, \bus, 400, \freq, 1, \mul, 400, \add, 400]
);
);

(
s.sendBundle(nil,[\n_set, 1010, \gate, -0.2],[\n_free,1030]);
s.sendBundle(0.2,
	[\s_new, "carSaw", 1010, 1, 1],
	[\n_map, 1010, "freq", 400],
	[\s_new, "modNoise", 1030, 1, 1, \bus, 400, \freq, 1, \mul, 400, \add, 400]
);
);

/*############################################################################################################*/
/*############ MIDI CONTROL ########*/

MIDIClient.init;
MIDIIn.connectAll;

~freqCC = MIDIFunc.cc({|value, num, ch, src|s.sendMsg(\n_set, 1011, \freq, value.map(0,127,20,20000))},1)//respond to cc 1

~freqCC.free;

a = MIDIFunc.cc({arg ...args; args.postln});
a.free;


x=0;
a = MIDIFunc.cc({|value, num, ch, src| if(value == 127){x=x+1%12;y[x].postln}});