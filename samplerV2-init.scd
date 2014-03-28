	// Sampler
(
Server.default.waitForBoot{

	Server.default = s;

	s.sync;

	//MIDI controllers

	// sliders and knobs
	~ampCC = 0;
	~rateCC = 1;
	~startLoopCC = 3;
	~lenghtLoopCC = 4;

	// buttons in temporary mode
	~bufPrevCC = 65;
	~bufNextCC = 66;

	// buttons in toggle mode
	~reverseCC = 64;
	~jitterCC = 67;


	~channelMIDI = 0;

	s.sync;

	// MIDI init
	MIDIClient.init;
	MIDIIn.connectAll;

	s.sync;

	// allocate buffer
	~paths = [];
	~bufNum = 0;
	"~/Sounds/*.wav".pathMatch.collect{|path| ~paths = ~paths.add(path)};
	~pathSize = ~paths.size;
	~buffer = Buffer.read(s, ~paths[~bufNum],action:{~buffer.normalize}, bufnum:0);


	s.sync;

	/* SYNTH def
	"rev"(1=normal, -1=reverse)
	"jitter" (0=off, 1=on) */

	(
		SynthDef(\sampler,{
			|bus=0, bufnum=0, rate=1, rev=1, start=0, lenght=1, loop=1, amp=1, jitter=0|
			var output, end, phase, bufframes, jitStart, jitLenght;
			bufframes = BufFrames.ir(bufnum);
			jitStart = LFNoise0.ar(5, 0.2) * jitter;
			jitLenght = LFNoise0.ar(4, 0.2) * jitter;
			start = ((start + jitStart) * bufframes) % bufframes;
			lenght = ((lenght + jitLenght) * bufframes) % bufframes;
			end = start + lenght;
			phase = Phasor.ar(
				0,
				rate * rev * BufRateScale.ir(bufnum),
				start,
				end,
			);
			output = BufRd.ar(1, bufnum, phase, loop);
			Out.ar(bus, output * amp);
		}).add;
	);

	s.sync;

	s.sendMsg(\s_new, "sampler", 1010, 1, 1);

	s.sync;

	// Declare functions to control the synths

	~amp = {|amp = 0| s.sendMsg(\n_set, 1010, \amp, amp)};
	~rate = {|rate = 1| s.sendMsg(\n_set, 1010, \rate, rate)};
	~startLoop = {|start = 0| s.sendMsg(\n_set, 1010, \start, start)};
	~lenghtLoop = {|lenght = 1| s.sendMsg(\n_set, 1010, \lenght, lenght)};
	~reverse = {|rev = 1| s.sendMsg(\n_set, 1010, \rev, rev)};
	~jitter = {|jit = 0| s.sendMsg(\n_set, 1010, \jitter, jit)};

	s.sync;

	// MIDI mapping

	MIDIFunc.cc({|val,num,ch,src| ~amp.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampCC, ~channelMIDI);

	MIDIFunc.cc({|val,num,ch,src| ~rate.value(val.linlin(0, 127, 0.125, 4))}, ~rateCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~startLoop.value(val.linlin(0, 127, 0.0, 1.0))}, ~startLoopCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~lenghtLoop.value(val.linlin(0, 127, 0.02, 1.0))}, ~lenghtLoopCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~reverse.value(val.linlin(0, 127, 1, -1))}, ~reverseCC, ~channelMIDI);

	MIDIFunc.cc({|val,num,ch,src| ~jitter.value(val.linlin(0, 127, 0, 1))}, ~jitterCC, ~channelMIDI);

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		var depthJitter;
		depthJitter = depthJitter
	}}, ~bufPrevCC, ~channelMIDI);

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~bufNum = ~bufNum + 1 % ~pathSize;
		~buffer = Buffer.read(s, ~paths[~bufNum], action:{~buffer.normalize}, bufnum:0);
	}}, ~bufPrevCC, ~channelMIDI);

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~bufNum = ~bufNum - 1 % ~pathSize;
		~buffer = Buffer.read(s, ~paths[~bufNum], action:{~buffer.normalize}, bufnum:0);
	}}, ~bufNextCC, ~channelMIDI);



	"\n \n \n Ready to play".postln;
}
)