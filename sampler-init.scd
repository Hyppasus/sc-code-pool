	// Sampler
(
Server.default.waitForBoot{

	Server.default = s;

	s.sync;

	//MIDI controllers
	~ampCC = 0;
	~rateCC = 1;
	~startLoopCC = 3;
	~endLoopCC = 4;
	~reverseCC = 64;
	~bufPrevCC = 65;
	~bufNextCC = 66;


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
	~bufSize = ~paths.size;
	~buffer = Buffer.read(s, ~paths[~bufNum], bufnum:0);

	s.sync;

	// synth
	//"rev"(1=normal, -1=reverse)

	(
		SynthDef(\sampler,{|bus=0, bufnum=0, rate=1, rev=1, start=0, end=1, loop=1, amp=1|
			var output, lenght, phase, bufframes;
			bufframes = BufFrames.ir(bufnum);
			start = start * bufframes;
			end = end * bufframes;
			lenght = (start + end) % bufframes;
			phase = Phasor.ar(
				0,
				rate * rev * BufRateScale.ir(bufnum),
				start,
				lenght,
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
	~endLoop = {|end = 1| s.sendMsg(\n_set, 1010, \end, end)};
	~reverse = {|rev = 1| s.sendMsg(\n_set, 1010, \rev, rev)};



	//MIDI mapping

	MIDIFunc.cc({|val,num,ch,src| ~amp.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampCC, ~channelMIDI);

	MIDIFunc.cc({|val,num,ch,src| ~rate.value(val.linlin(0, 127, 0.125, 4))}, ~rateCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~startLoop.value(val.linlin(0, 127, 0.0, 1.0))}, ~startLoopCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~endLoop.value(val.linlin(0, 127, 0.02, 1.0))}, ~endLoopCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~reverse.value(val.linlin(0, 127, 1, -1))}, ~reverseCC, ~channelMIDI);


	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~bufNum = ~bufNum + 1 % ~bufSize;
		~buffer = Buffer.read(s, ~paths[~bufNum], bufnum:0)
	}}, ~bufPrevCC, ~channelMIDI);

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~bufNum = ~bufNum - 1 % ~bufSize;
		~buffer = Buffer.read(s, ~paths[~bufNum], bufnum:0)
	}}, ~bufNextCC, ~channelMIDI);



	"\n \n \n Ready to play".postln;
}
)





