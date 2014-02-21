	// basic loop Sampler
(
Server.default.waitForBoot{

	Server.default = s;

	s.sync;

	//MIDI controllers
	~ampCC = 0;
	~rateCC = 1;
	~startLoopCC = 3;
	~lenghtLoopCC = 4;

	~channelMIDI = 0;

	s.sync;


	// MIDI init
	MIDIClient.init;
	MIDIIn.connectAll;

	s.sync;

	// allocate buffer
	// p = "~/Sounds/";
	p = "/Users/alfredoardia/Documents/Ableton/User Library/Samples/My samples/doors/door1.wav";
	b = Buffer.read(s, p,);

	// synth
	// !!!! PROBLEM IN THE LOOP START, LENGHT, RETRIGGER !!!

	(
		SynthDef(\sampler,{|bus=0, bufnum=0, start=0, rate=1, lenght=1, loop=1, amp=1|
			var output, env, end, phase, trig;
			end = start + lenght;
			// trig = Impulse.ar(2 / BufDur.ir(b));
			phase = Phasor.ar(
				1, //trig,
				rate * BufRateScale.ir(b),
				start,
				end * BufFrames.ir(b),
				start);
			output = BufRd.ar(1, b, phase, loop);
			Out.ar(bus, output * amp);
		}).add;
	);

	s.sync;

	s.sendMsg(\s_new, "sampler", 1010, 1, 1);

	s.sync;

	// Declare functions to control the synths

	~amp = {|amp = 0| s.sendMsg(\n_set, 1010, \amp, amp)};
	~rate = {|rate = 440| s.sendMsg(\n_set, 1010, \rate, rate)};
	~startLoop = {|start = 440| s.sendMsg(\n_set, 1010, \start, start)};
	~leghtLoop = {|lenght = 0| s.sendMsg(\n_set, 1030, \lenght, lenght)};



	//MIDI mapping

	MIDIFunc.cc({|val,num,ch,src| ~amp.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampCC, ~channelMIDI);

	MIDIFunc.cc({|val,num,ch,src| ~rate.value(val.linlin(0, 127, 0.125, 4))}, ~rateCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~startLoop.value(val.linlin(0, 127, 0.0, 1.0))}, ~startLoopCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~lenghtLoop.value(val.linlin(0, 127, 0.0, 1.0))}, ~lenghtLoopCC, ~channelMIDI);



	"\n \n \n Ready to play".postln;
}
)


