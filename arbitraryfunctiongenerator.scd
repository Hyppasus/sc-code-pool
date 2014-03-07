
//Debugging

y={|bus=65, out=0|Out.ar(out,SinOsc.ar(In.ar(bus)+200,0,1,0))}.play;
x={|freq=440, out=0, mul=1,add=0|Out.ar(out,SinOsc.ar(freq,0,mul,add))}.play;
x.set(\out,65);
x.set(\freq, 1);
x.set(\mul, 100);
x.set(\add, 100);


/*#####################################################################################################################################*/
// new version

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
	~testenvelope = Env(~allvalues ++ ~allvalues[0], [1, 1, 1, 1, 1, 1, 1, 1, 1], \sine).asSignal(512).asWavetable;
	~bufTableCar.setn(0,~testenvelope);
};
);


// SynthDefs
(
SynthDef(\arbitrary,{|freq=400, amp=1.0, bus=0, bufnum=0|
	var output;
	output = Osc.ar(bufnum, freq, 0);
	Out.ar(bus, output * amp);
}).add;
);


(
//changing it to control a sinosc
SynthDef(\sinewave, {|freq = 1, amp=0.5, bus=0, inBus=65|
	var output = SinOsc.ar(In.ar(inBus).linexp(-1, 1, 100, 1000) /*freq.linexp(-1, 1, 100, 1000)*/); //this sine oscillator takes a frequency control value between -1,1
	Out.ar(bus, output*amp);
}).add;
);

s.sendMsg(\s_new, "arbitrary", 1010, 1, 1);

s.sendMsg(\s_new, "sinewave", 1020, 1, 1);

s.sendMsg(\n_set, 1010, \bus, 65); //change to "control-mode"

s.sendMsg(\n_set, 1010, \bus, 0); //change to "oscillator-mode"

//next line is an alternative to "inBus", uncomment it in the synthdef for sinewave as well. Why isn't this working?
s.sendMsg(\n_map, 1020, "freq", 65); // ask this synth to read the freq from this bus

//s.reboot
//s.boot