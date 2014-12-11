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
	~loopJittCC = 67;
	~loopJittDepth = 68;

	~pitchJittCC = 69;
	~pitchJittDepthCC = 70;

	~channelMIDI = 0;

	s.sync;

	// MIDI init
	MIDIClient.init;
	MIDIIn.connectAll;

	s.sync;

	~ljdepth=0;
	~pjdepth=0;

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
			|bus=0, bufnum=0, rate=1, rev=1, start=0, lenght=1, loop=1, loopJitt=0, loopJittDepth=0, pitchJitt=0, pitchJittDepth=0, amp=1|
			var output, end, phase, bufframes, jitStart, jitLenght, jitRate;
			bufframes = BufFrames.kr(bufnum);
			jitStart = LFNoise0.ar(10, loopJittDepth) * loopJitt;
			jitLenght = LFNoise0.ar(20, loopJittDepth) * loopJitt;
			start = ((start + jitStart) * bufframes) % bufframes;
			lenght = ((lenght + jitLenght) * bufframes) % bufframes;
			end = start + lenght;
			jitRate = LFNoise0.ar(5, pitchJittDepth) * pitchJitt;
			phase = Phasor.ar(
				0,
				(rate + jitRate) * rev * BufRateScale.ir(bufnum),
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
	~loopJitt = {|jit = 0| s.sendMsg(\n_set, 1010, \loopJitt, jit)};
	~loopJittDepth = {|depth = 0| s.sendMsg(\n_set, 1010, \loopJittDepth, depth)};
	~pitchJitt = {|jit = 0| s.sendMsg(\n_set, 1010, \pitchJitt, jit)};
	~pitchJittDepth = {|depth = 0| s.sendMsg(\n_set, 1010, \pitchJittDepth, depth)};

	s.sync;

	// MIDI mapping

	MIDIFunc.cc({|val,num,ch,src| ~amp.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampCC, ~channelMIDI);

	MIDIFunc.cc({|val,num,ch,src| ~rate.value(val.linlin(0, 127, 0.125, 4))}, ~rateCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~startLoop.value(val.linlin(0, 127, 0.0, 1.0))}, ~startLoopCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~lenghtLoop.value(val.linlin(0, 127, 0.02, 1.0))}, ~lenghtLoopCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~reverse.value(val.linlin(0, 127, 1, -1))}, ~reverseCC, ~channelMIDI);

	MIDIFunc.cc({|val,num,ch,src| ~loopJitt.value(val.linlin(0, 127, 0, 1))}, ~loopJittCC, ~channelMIDI);

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~ljdepth = (~ljdepth + 1 % 5) + 1;
		~loopJittDepth.value(~ljdepth * 0.2);
		//~depth.postln
	}}, ~loopJittDepthCC, ~channelMIDI);

	MIDIFunc.cc({|val,num,ch,src| ~pitchJitt.value(val.linlin(0, 127, 0, 1))}, ~pitchJittCC, ~channelMIDI);

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~pjdepth = (~pjdepth + 1 % 10) + 1;
		~pitchJittDepth.value(~pjdepth * 0.1);
		//~depth.postln
	}}, ~loopJittDepthCC, ~channelMIDI);

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



/*
add more scanning mode, see Mix.fill or Select
random pitch
jitter crazy mode?

~buffer.plot
*/
