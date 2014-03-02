~bufTableCar=Buffer.alloc(s, 1024, bufnum:0);
~envTableCar=Env([0] ++ [-1, 0.5] ++ 0, [0.1, 0.1, 0.1], \sine).asSignal(512).asWavetable;~bufTableCar.setn(0, ~envTableCar);
~allvalues = [0, 0, 0, 0, 0, 0, 0, 0];

//~envTableCar.plot;
~ampArbitraryCC = 16;
~freqArbitraryCC = 17;
~waveformArbitraryCC = [0, 1, 2, 3, 4, 5, 6, 7]; //TODO: change the modification of the waveform into 8 pots to change between steps
//TODO LEDS: light intensity vs blinking frequency to communicate the state of each step (maybe rgb leds WS2812 ;)
//TODO: use the remaining potentiometer to control portamento/interpolation function

//Init MIDI
MIDIClient.init;
MIDIIn.connectAll;

MIDIFunc.cc({|val,num,ch,src| ~ampArbitrary.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampArbitraryCC, nil);
MIDIFunc.cc({|val,num,ch,src| ~freqArbitrary.value(val.linexp(0, 127, 0.1, 5000.0))}, ~freqArbitraryCC, nil);
MIDIFunc.cc({|val, num, ch, src| ~waveformArbitrary.value(num, val.linlin(0,127,-1,1))}, ~waveformArbitraryCC, nil);


~ampArbitrary = {|amp = 0| s.sendMsg(\n_set, 1010, \amp, amp)};
~freqArbitrary = {|freq = 0| s.sendMsg(\n_set, 1010, \freq, freq)};
(
~waveformArbitrary = {|num, val|
	~allvalues[num] = val;
	~testenvelope = Env([0] ++ ~allvalues ++ 0, [1, 1, 1, 1, 1, 1, 1, 1, 1], \sine).asSignal(512).asWavetable;
	~bufTableCar.setn(0,~testenvelope);
};
);


// SynthDefs
(
SynthDef(\arbitrary,{|freq=400, amp=0.1, bus=0, bufnum=0, gate=1, mul=1, add=0|
	var output, env;
	env = EnvGen.ar(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
	output = Osc.ar(bufnum, freq, 0, mul, add);
	Out.ar(bus, output * amp * env);
}).add;
);


(
//changing it to control a sinosc
SynthDef(\sinewave, {|freq = 1, amp=0.5, bus=0, inBus=402|
	var output = SinOsc.ar(In.ar(inBus)+freq.linlin(-1, 1, 10, 880)); //this sine oscillator takes a frequency control value between -1 and 1
	Out.ar(bus, output*amp);
}).add;
);

s.sendMsg(\s_new, "arbitrary", 1010, 1, 1);

s.sendMsg(\c_set, 402, -0.5); // create the bus

s.sendMsg(\s_new, "sinewave", 1020, 1, 1);

s.sendMsg(\n_set, 1010, \bus, 402);

s.sendMsg(\n_map, 1020, "freq", 402); // ask this synth to read the freq from this bus

s.sendMsg(\n_set, 1010, \mul, 1000);

s.sendMsg(\n_set, 1010, \add, 100);

//s.reboot
//s.boot
