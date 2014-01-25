// use carSomething for the carrier synths. Out.ar
// use modSomething for the modulator synth. Out.kr(bus..
// explore deterministic and non deterministic waveforms
// restrict the amount of arguments to 4!

/*######### Carriers ##############*/

(
SynthDef("carSine", {|bus=0, freq=440, iphase=0, amp=1|
	Out.ar(bus, LFPar.ar(freq, iphase, amp));}).add;
);


(
SynthDef("carPulse", {|bus=0, freq=440, iphase=0, width=0.5, amp=1|
	Out.ar(bus, LFPulse.ar(freq, iphase, width, amp));}).add;
);



/*######### Modulators ##############*/

(
SynthDef("modPulse", {|bus=4, freq=200, iphase=0, width=0.5, mul=1, add=0|
	Out.kr(bus, LFPulse.kr(freq, iphase, width, mul, add));}).add;
);


(
SynthDef("modPar", {|bus=4, freq=200, iphase=0, mul=1, add=0|
	Out.kr(bus, LFPar.kr(freq, iphase, mul, add));}).add;
);

(
SynthDef("modSaw", {|bus=4, freq=200, iphase=0, mul=1, add=0|
	Out.kr(bus, LFSaw.kr(freq, iphase, mul, add));}).add;
);


(
SynthDef("modNoise2", {|bus=4, freq=200, mul=1, add=0|
	Out.kr(bus, LFNoise2.kr(freq, mul, add));}).add;
);


//
// (
// SynthDef("modLine", {|bus=4, start=200, end=2000, dur=20, mul=1, add=0, doneAction=2|
// Out.kr(bus, XLine.kr(start, end, dur, mul, add, doneAction));}).add;
// )
//
