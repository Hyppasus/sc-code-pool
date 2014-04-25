// Wave table Frequency Modulation 1024 (10 bit) resolution
(
Server.default.waitForBoot{

	Server.default = s;

	s.sync;

	//MIDI controllers
	~ampCarCC = 4; // if the limit of 4 sliders left this one out
	~freqCarCC = 0;
	~freqModCC = 1;
	~mulModCC = 2;
	~addModCC = 3;
	~tableCarNextCC = 64; // next carrier table
	~tableCarPrevCC = 65; // previous modulator table
	~tableModNextCC = 66; // next carrier table
	~tableModPrevCC = 67; // previous modulator table
	~freqCarRangeCC = 68; // multiply the freq by a factor of 5
	~freqModRangeCC = 69; // multiply the freq by a factor of 10


	~channelMIDI = 0;


	~bufTableCar=Buffer.alloc(s, 1024, bufnum:0);
	~bufTableMod=Buffer.alloc(s, 1024, bufnum:1);

	s.sync;

	// Default wave tables
	~envTableCar = Signal.sineFill(512,[1],[0]).asWavetable;~bufTableCar.setn(0,~envTableCar); //sine
	~envTableMod = Signal.sineFill(512,[1],[0]).asWavetable;~bufTableMod.setn(0,~envTableMod); //sine

	s.sync;

	// MIDI init
	MIDIClient.init;
	MIDIIn.connectAll;

	s.sync;

	//Wavetable carrier Synth
	SynthDef(\carWable,{|freq=400, fMod = 1, amp=0.5, bus=0, bufnum=0, gate=1|
			var output, env;
			env = EnvGen.ar(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
			output = Osc.ar(bufnum, freq + fMod);
			Out.ar(bus, output * amp * env);
		}).add;

	//Wavetable modulator Synth
	SynthDef(\modWable,{|freq=4, mul=1, add=0, bus=0, bufnum=1, gate=1, lag=1|
			var output, env;
			env = EnvGen.ar(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
			output = Osc.kr(bufnum, freq.lag(lag), 0, mul, add);
			Out.kr(bus, output * env);
		}).add;

	s.sync;

	s.sendMsg(\s_new, "carWable", 1010, 1, 1);

	s.sync;

	s.sendMsg(\c_set, 40, 300); // create the bus

	s.sendMsg(\n_map, 1010, "fMod", 40); // ask this synth to read the freq from this bus

	s.sync;

	s.sendMsg(\s_new, "modWable", 1030, 1, 1, \bus, 40, \mul, 1000); // create a synth playing in the bus 40


// Declare functions to control the synths


	~getWaveCar = {
		|kind = 0|
		case
		{kind == 0}
	{~envTableCar = Signal.sineFill(512,[1],[0]).asWavetable;~bufTableCar.setn(0,~envTableCar);}//sine
		{kind == 1}
	{~envTableCar = Signal.sineFill(512, 1.0/[1,2,3,4,5,6]).asWavetable;~bufTableCar.setn(0,~envTableCar);}//semi-saw
		{kind == 2}
	{~envTableCar = Signal.sineFill(512, 1.0/(1..512)).asWavetable;~bufTableCar.setn(0,~envTableCar);}//saw
		{kind == 3}
	{~envTableCar = Env([0]++ [-1, 1]++(0), [0.0, 0.1, 0.0],\lin).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar);}//reverse saw
		{kind == 4}
	{~envTableCar = Env([0]++ [-1, 0, 1]++(0), [0.1, 0.1, 0.1, 0.1],\lin).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar);}//triangle
		{kind == 5}
	{~envTableCar = Env([0, -1, 1], [0.1, 0.1],\step).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar);}//square
		{kind == 6}
	{~envTableCar = Env([0]++ Array.rand(10,-1,1.0)++(0), Array.rand(11,0.01,1.0),Array.fill(11,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar);}//rand soft
		{kind == 7}
	{~envTableCar = Env([0]++ Array.rand(100,-1,1.0)++(0), Array.rand(101,0.01,1.0),Array.fill(101,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar);}//rand mid
		{kind == 8}
	{~envTableCar = Env([0]++ Array.rand(510,-1,1.0)++(0), Array.rand(511,0.01,1.0),Array.fill(511,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar);}//rand extreme


	};


	~getWaveMod = {
		|kind = 0|
		case
		{kind == 0}
	{~envTableMod = Signal.sineFill(512,[1],[0]).asWavetable;~bufTableMod.setn(0,~envTableMod);}//sine
		{kind == 1}
	{~envTableMod = Signal.sineFill(512, 1.0/[1,2,3,4,5,6]).asWavetable;~bufTableMod.setn(0,~envTableMod);}//semi-saw
		{kind == 2}
	{~envTableMod = Signal.sineFill(512, 1.0/(1..512)).asWavetable;~bufTableMod.setn(0,~envTableMod);}//saw
		{kind == 3}
	{~envTableMod = Env([0]++ [-1, 1]++(0), [0.0, 0.1, 0.0],\lin).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}//reverse saw
		{kind == 4}
	{~envTableMod = Env([0]++ [-1, 0, 1]++(0), [0.1, 0.1, 0.1, 0.1],\lin).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}//triangle
		{kind == 5}
	{~envTableMod = Env([0, -1, 1], [0.1, 0.1],\step).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}//square
		{kind == 6}
	{~envTableMod = Env([0]++ Array.rand(10,-1,1.0)++(0), Array.rand(11,0.01,1.0),Array.fill(11,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}//rand soft
		{kind == 7}
	{~envTableMod = Env([0]++ Array.rand(100,-1,1.0)++(0), Array.rand(101,0.01,1.0),Array.fill(101,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}//rand mid
		{kind == 8}
	{~envTableMod = Env([0]++ Array.rand(510,-1,1.0)++(0), Array.rand(511,0.01,1.0),Array.fill(511,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}//rand extreme
		{kind == 9}
	{~envTableMod = Env([0]++ Array.rand(4,-1,1.0)++(0), Array.rand(5,0.01,1.0),\step).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod)}//rand 4 step
		{kind == 10}
	{~envTableMod = Env([0]++ Array.rand(8,-1,1.0)++(0), Array.rand(9,0.01,1.0),\step).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod)}//rand 8 step
		{kind == 11}
	{~envTableMod = Env(([0] ++ [0, 16, 27, 36, 40, 43, 44, 47, 50, 51, 53, 55, 57, 58, 60, 61, 63, 65, 67, 67, 68, 70, 71, 72, 72, 72, 72, 72, 73, 74, 77, 78, 80, 82, 84, 86, 87, 88, 88, 87, 81, 71, 70, 69, 69, 68, 59, 60, 63, 63, 60, 58, 57, 57, 58, 58, 54, 50, 42, 35, 27, 18,11,0]++0)*0.01,Array.fill(63,0.1),\sine).asSignal(512).asWavetable; ~bufTableMod.setn(0, ~envTableMod);}//The profil of Stockhausen as a Wavetable
	};
	/*
	~envTableMod.plot;
	~envTableCar.plot;
	*/

	~ampCar = {|amp = 0| s.sendMsg(\n_set, 1010, \amp, amp)};
	~freqCar = {|freq = 440| s.sendMsg(\n_set, 1010, \freq, freq)};
	~freqMod = {|freq = 440| s.sendMsg(\n_set, 1030, \freq, freq)};
	~mulMod = {|mul = 0| s.sendMsg(\n_set, 1030, \mul, mul)};
	~addMod = {|add = 0| s.sendMsg(\n_set, 1030, \add, add)};


//MIDI mapping
	~freqCarRange = 1;
	~freqModRange = 1;

	MIDIFunc.cc({|val,num,ch,src| ~ampCar.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampCarCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~freqCar.value(val.linexp(0, 127, 20, 5000) * ~freqCarRange)}, ~freqCarCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~freqMod.value(val.linexp(0, 127, 0.05, 1000) * ~freqModRange)}, ~freqModCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~mulMod.value(val.linlin(0, 127, 1.0, 1000.0))}, ~mulModCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~addMod.value(val.linlin(0, 127, 1.0, 1000.0))}, ~addModCC, ~channelMIDI);

	~indexFreqCarRange = Pseq(#[5, 1],inf).asStream;
	~indexFreqModRange = Pseq(#[10, 1],inf).asStream;

	MIDIFunc.cc({|val, num, ch, src| if(val == 127){~freqCarRange = ~indexFreqCarRange.nextN(1)[0].value}}, ~freqCarRangeCC, ~channelMIDI);
	MIDIFunc.cc({|val, num, ch, src| if(val == 127){~freqModRange = ~indexFreqModRange.nextN(1)[0].value}}, ~freqModRangeCC, ~channelMIDI);

	~tableCar = 0;    //init a variable to scan the tables

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~tableCar = ~tableCar + 1 % 9;
		~getWaveCar.value(~tableCar);
	}}, ~tableCarNextCC, ~channelMIDI);

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~tableCar = ~tableCar - 1 % 9;
		~getWaveCar.value(~tableCar);
	}}, ~tableCarPrevCC, ~channelMIDI);

	~tableMod = 0;

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~tableMod = ~tableMod + 1 % 12;
		~getWaveMod.value(~tableMod);
	}}, ~tableModNextCC, ~channelMIDI);

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~tableMod = ~tableMod - 1 % 12;
		~getWaveMod.value(~tableMod);
	}}, ~tableModPrevCC, ~channelMIDI);

	"\n \n \n Ready to play".postln;
}
)
