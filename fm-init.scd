// This will be the script for initializing the synth
//
Server.local.waitForBoot{

	s = Server.local;

// add synths to server
	// this could be replace with a "loadPath" method pointing to the location of the file containing the synthDefs

/*######### Carriers ##############*/

(
SynthDef("carSine", {|bus=0, freq=440, iphase=0, amp=1, gate=1|
	var env = EnvGen.ar(Env.asr(0.01,1,0.01),gate, doneAction:2);
	var sig = LFPar.ar(freq, iphase, amp);
	Out.ar(bus, sig*env);}).add;
);


(
SynthDef("carPulse", {|bus=0, freq=440, iphase=0, width=0.5, amp=1, gate=1|
	var env = EnvGen.ar(Env.asr(0.01,1,0.01),gate, doneAction:2);
	var sig = LFPulse.ar(freq, iphase, width, amp);
	Out.ar(bus, sig*env);}).add;
);

(
SynthDef("carSaw", {|bus=0, freq=440, iphase=0, amp=1, gate=1|
	var env = EnvGen.ar(Env.asr(0.01,1,0.01), gate, doneAction:2);
	var sig = Saw.ar(freq, amp);
	Out.ar(bus, sig*env)}).add;
);



/*######### Modulators ##############*/

SynthDef("modPulse", {|bus=4, freq=200, iphase=0, width=0.5, mul=1, add=0|
	Out.kr(bus, LFPulse.kr(freq, iphase, width, mul, add));}).add;

SynthDef("modPar", {|bus=4, freq=200, iphase=0, mul=1, add=0|
	Out.kr(bus, LFPar.kr(freq, iphase, mul, add));}).add;

SynthDef("modSaw", {|bus=4, freq=200, iphase=0, mul=1, add=0|
	Out.kr(bus, LFSaw.kr(freq, iphase, mul, add));}).add;

SynthDef("modNoise", {|bus=4, freq=200, mul=1, add=0|
	Out.kr(bus, LFNoise2.kr(freq, mul, add));}).add;

SynthDef("modDust", {|bus=4, freq=200, mul=1, add=0|
	Out.kr(bus, Dust.kr(freq, mul, add));}).add;

SynthDef("modGendy", {|bus=4, freq=200, mul=1, add=0|
	Out.kr(bus, Gendy3.kr(Rand(1,6), Rand(1,6), 1, 1, freq, 1, 1, 12 ,12, mul, add));}).add;


s.sync;

MIDIClient.init;
MIDIIn.connectAll;

s.sync;


}