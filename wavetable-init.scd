// Wave table Frequency Modulation
(
Server.default.waitForBoot{

	Server.default = s;

	MIDIClient.init;
	MIDIIn.connectAll;

	s.sync;

	//MIDI controllers
	~ampCarCC = 0;
	~freqCarCC = 1;
	~freqModCC = 3;
	~mulModCC = 4;
	~addModCC = 5;
	~tableCC = 80;
	~tableCarCC = 81;
	~channelMIDI = 0;

	~bufTableCar=Buffer.alloc(s,1024, bufnum:0);
	~bufTableMod=Buffer.alloc(s,1024, bufnum:1);

	s.sync;

	// Default wave tables
	~envTableCar=Env([0]++ [-1, 0.5]++0, [0.1, 0.1, 0.1], \sine).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar);

	~envTableMod=Env([0]++ [1, 0.5]++0, [0.1, 0.1, 0.1], \sine).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);

	s.sync;

	//Wavetable carrier Synth
	SynthDef(\carWable,{|freq=400, fMod = 1, amp=0.1, bus=0, bufnum=1, gate=1|
			var output, env;
			env = EnvGen.ar(Env.asr(0.01,1,0.01), gate, doneAction:2);
			output = Osc.ar(bufnum, freq + fMod);
			Out.ar(bus, output*amp*env);
		}).add;

	//Wavetable modulator Synth
	SynthDef(\modWable,{|freq=4, mul=1, add=0, bus=0, bufnum=0, gate=1, lag=1|
			var output, env;
			env = EnvGen.ar(Env.asr(0.01,1,0.01),gate, doneAction:2);
			output = Osc.kr(bufnum, freq.lag(lag),0,mul,add);
			Out.kr(bus, output*env);
		}).add;

	s.sync;

	s.sendMsg(\s_new, "carWable", 1010, 1, 1);

	s.sync;

	s.sendMsg(\c_set, 400, 300); // create the bus

	s.sendMsg(\n_map, 1010, "fMod", 400); // ask this synth to read the freq from this bus

	s.sync;

	s.sendMsg(\s_new, "modWable", 1030, 1, 1, \bus, 400, \mul, 1000); // create a synth playing in the bus 400


// Declare functions to controle the synths


	~getWaveCar = {
		|kind=0|
		case
		{kind==0}
		{~envTableCar=Env([0]++ [-0.41, 0.8]++(0), [0.5, 0.8, 0.3],\sqr).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar)}
		{kind==1}
		{~envTableCar=Env([0]++ [-0.1, 1]++(0), [0.1, 0.2, 0.2], \wel).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar)}
		{kind==2}
		{~envTableCar=Env([0] ++ [0, -0.12, 0.5]++ (0), [0.1, 0.2, 0.2], \sin).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar)}
		{kind==3}
		{~envTableCar=Env([0] ++ [1, -0.2, 0.5, 0.2] ++ (0), [0.1, 0.2, 0.2], \sin).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar)}
		{kind==4}
		{~envTableCar=Env([0] ++ [1, -0.6, 0.5] ++(0), [0.7, 0.5, 0.2], \cub).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar)}
		{kind==5}
		{~envTableCar=Env([0] ++ [-0.2, 0.8, 1]++(0), [0.7, 0.5, 0.2], \cub).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar)}
	};


	~getWaveMod = {
		|kind=0|
		case
		{kind==0}
		{~envTableMod=Env([0]++ [1, 0.8]++(0), [0.5, 0.8, 0.3], \sqr).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod)}
		{kind==1}
		{~envTableMod=Env([0]++ [0.5, 1]++(0), [0.1, 0.2, 0.2], \wel).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod)}
		{kind==2}
		{~envTableMod=Env([0] ++ [0.7, 0.12, 0.5]++ (0), [0.1, 0.2, 0.2], \sin).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod)}
		{kind==3}
		{~envTableMod=Env([0] ++ [1, 0.2, 0.5, 0.2] ++ (0), [0.1, 0.2, 0.2], \sin).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod)}
		{kind==4}
		{~envTableMod=Env([0] ++ [1, 0.6, 0.5] ++(0), [0.7, 0.5, 0.2], \cub).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod)}
		{kind==5}
		{~envTableMod=Env([0] ++ [-0.2, 0.8, 1]++(0), [0.7, 0.5, 0.2], \cub).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod)}
};


	~ampCar = {|amp=0| s.sendMsg(\n_set, 1010, \amp, amp)};
	~freqCar = {|freq=440| s.sendBundle(nil,[\n_set, 1010, \freq, freq])};
	~freqMod = {|freq = 440| s.sendMsg(\n_set, 1030, \freq, freq)};
	~mulMod = {|mul = 0| s.sendMsg(\n_set, 1030, \mul, mul)};
	~addMod = {|add = 0| s.sendMsg(\n_set, 1030, \add, add)};


//MIDI mapping

	MIDIFunc.cc({|val,num,ch,src| ~ampCar.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampCarCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~freqCar.value(val.linlin(0, 127, 200, 2000))}, ~freqCarCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~freqMod.value(val.linlin(0, 127, 0.1, 1000))}, ~freqModCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~mulMod.value(val.linlin(0, 127, 1.0, 1000.0))}, ~mulModCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~addMod.value(val.linlin(0, 127, 1.0, 1000.0))}, ~addModCC, ~channelMIDI);



	~tableCar =0;    //init a variable to scan the tables
	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~tableCar = ~tableCar + 1 % 6;
		~getWaveCar.value(~tableCar);
	}}, ~tableCarCC, ~channelMIDI);

	~tableMod =0;
	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~tableMod = ~tableMod + 1 % 6;
		~getWaveMod.value(~tableMod);
	}}, ~tableCC, ~channelMIDI);


	"\n \n \n Ready to play".postln;
}
)


/*

~freqMod.value(100)
~freqCar.value(1000)
s.sendMsg(\n_set, 1030, \freq, 10);
s.sendMsg(\c_set, 400, 1200); // create the bus
s.sendMsg(\n_map, 1010, "freq", 400); // ask this synth to read the freq from this bus

*/