// Wave table Frequency Modulation 1024 (10 bit) resolution
(
Server.default.waitForBoot{

	Server.default = s;

	//allocate the buffers
	16.do{|i|currentEnvironment.put(("buf"++i).asSymbol, Buffer.alloc(s, 1024, bufnum:i);)};

	s.sync;

	// default wavetables carrier
	//16.do{|i|currentEnvironment.at(("buf"++i).asSymbol).setn(0, Signal.sineFill(512,Array.rand(512,0.1,1),Array.rand(512,-pi,pi)).asWavetable)};

	//16.do{|i|currentEnvironment.at(("buf"++i).asSymbol).setn(0, Signal.sineFill(512, Array.fill(512,{1.0/(i+1)})).asWavetable)};

	8.do({|i| var n, a;
			n = (i+1)**2;
			a = Array.fill(n, { arg j; ((n-j)/n).squared.round(0.001) });
			s.performList(\sendMsg, \b_gen, i, \sine1, 7, a);
	});

	8.do({|i| var  a;
			a = Array.fill(i, 0) ++ [0.5, 1, 0.5];
			s.performList(\sendMsg, \b_gen, i+8, \sine1, 7, a);
		});
/*
~buf15.plot
*/
	s.sync;

	// Frequency Modulation with Wavetables and interpolation

	SynthDef(\interpWable,{ |bus=0, gate=1, amp=1.0, bufoffset=0, bufoffsetMod=8, freq=440, detune=1, freqMod=1, detuneMod=0,  mul=100, add=10|
		var env, sig, modulator;
		env = EnvGen.ar(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
		modulator = VOsc.ar(bufoffsetMod, [freqMod, freqMod + detuneMod], 0, mul, add);
		sig =  VOsc.ar(bufoffset, [freq, freq + detune] + modulator);
		Out.ar(bus, sig * env * amp)
		}).add;

	s.sync;

	s.sendMsg(\s_new, "interpWable", 1040, 1, 1, \bus, 0,\bufoffset, 0); // create a synth playing in the bus 0

	s.sync;

/* ################################ Declare functions to control the synths  ###################################*/

	~ampCar = {|amp = 0| s.sendMsg(\n_set, 1040, \amp, amp)};
	~bufoffset = {|bufoffset = 0| s.sendMsg(\n_set, 1040, \bufoffset, bufoffset)};
	~bufoffsetMod = {|bufoffset = 0| s.sendMsg(\n_set, 1040, \bufoffsetMod, bufoffset)};
	~freqCar = {|freq = 440| s.sendMsg(\n_set, 1040, \freq, freq)};
	~freqMod = {|freq = 440| s.sendMsg(\n_set, 1040, \freqMod, freq)};
	~mulMod = {|mul = 0| s.sendMsg(\n_set, 1040, \mul, mul)};
	~addMod = {|add = 0| s.sendMsg(\n_set, 1040, \add, add)};
	~detuneCar = {|val = 0| s.sendMsg(\n_set, 1040, \detune, val)};
	~detuneMod = {|val = 0| s.sendMsg(\n_set, 1040, \detuneMod, val)};

	~getWaveCar = {|kind = 0|
		case
		{kind == 0}
		{8.do({|i| var n, a;
			// generate array of harmonic amplitudes
			n = (i+1)**2;
			a = Array.fill(n, { arg j; ((n-j)/n).squared.round(0.001) });
			// fill table
			s.performList(\sendMsg, \b_gen, i, \sine1, 7, a);
		});}

		{kind == 1}
		{8.do({|i| var  a;
			a = Array.fill(i, 0) ++ [0.5, 1, 0.5];
			s.performList(\sendMsg, \b_gen, i, \sine1, 7, a);
		});}

		{kind == 2}
		{8.do({|i| var a;
			    a = Array.fill(32,0);
			    12.do({ arg i; a.put(32.rand, 1) });
			s.performList(\sendMsg, \b_gen, i, \sine1, 7, a);
		});}

		{kind == 3}
		{8.do({|i| var n, a;
			n = (i+1)**2;
		    a = Array.fill(n, { arg j; 1.0.rand2 });
			s.performList(\sendMsg, \b_gen, i, \sine1, 7, a);
		});}

		{kind == 4}
		{8.do({|i| var n, a;
			n = (i+1)**2;
			a = Array.fill(n, { arg j; ((n-j)/n).squared.round(0.001) });
			s.performList(\sendMsg, \b_gen, i, \sine1, 7, a);
		});}

		{kind == 5}
		{8.do{|i|currentEnvironment.at(("buf"++i).asSymbol).setn(0, Signal.sineFill(512,Array.rand(512,0.001,0.01)).asWavetable)};}

		{kind == 6}
		{8.do{|i|currentEnvironment.at(("buf"++i).asSymbol).setn(0,Env([0]++ [(i+1).reciprocal.neg, (i+1).reciprocal]++(0), [0.0, 0.1, 0.0],\lin).asSignal(512).asWavetable)};}

		{kind == 7}
		{8.do{|i|currentEnvironment.at(("buf"++i).asSymbol).setn(0, Signal.sineFill(512,Array.rand(512,0.001,0.01)).asWavetable)};}

		{kind == 8}
		{
			~buf0.setn(0, Signal.sineFill(512, 1.0/[1,2,3,4,5,6]).asWavetable);
			~buf0.setn(0, Signal.sineFill(512, 1.0/(1..512)).asWavetable);
			~buf0.setn(0, Env([0]++ [-1, 1]++(0), [0.0, 0.1, 0.0],\lin).asSignal(512).asWavetable);
			~buf0.setn(0, Env([0]++ [-1, 0, 1]++(0), [0.1, 0.1, 0.1, 0.1],\lin).asSignal(512).asWavetable);
			~buf0.setn(0, Env([0, -1, 1], [0.1, 0.1],\step).asSignal(512).asWavetable);
			~buf0.setn(0, Env([0]++ Array.rand(10,-1,1.0)++(0), Array.rand(11,0.01,1.0),Array.fill(11,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable);
				~buf0.setn(0, Env([0]++ Array.rand(100,-1,1.0)++(0), Array.rand(101,0.01,1.0),Array.fill(101,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable);
			~buf0.setn(0, Env([0]++ Array.rand(510,-1,1.0)++(0), Array.rand(511,0.01,1.0),Array.fill(511,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable);



		}

	};


	~getWaveMod = {|kind = 0|
		case
		{kind == 0}
		{8.do({|i| var n, a;
			n = (i+1)**2;
			a = Array.fill(n, { arg j; ((n-j)/n).squared.round(0.001) });
			s.performList(\sendMsg, \b_gen, i+8, \sine1, 7, a);
		});}

		{kind == 1}
		{8.do({|i| var  a;
			a = Array.fill(i, 0) ++ [0.5, 1, 0.5];
			s.performList(\sendMsg, \b_gen, i+8, \sine1, 7, a);
		});}

		{kind == 2}
		{8.do({|i| var a;
			    a = Array.fill(32,0);
			    12.do({ arg i; a.put(32.rand, 1) });
			s.performList(\sendMsg, \b_gen, i+8, \sine1, 7, a);
		});}

		{kind == 3}
		{8.do({|i| var n, a;
			n = (i+1)**2;
		    a = Array.fill(n, { arg j; 1.0.rand2 });
			s.performList(\sendMsg, \b_gen, i+8, \sine1, 7, a);
		});}

		{kind == 4}
		{8.do({|i| var n, a;
			n = (i+1)**2;
			a = Array.fill(n, { arg j; ((n-j)/n).squared.round(0.001) });
			s.performList(\sendMsg, \b_gen, i+8, \sine1, 7, a);
		});}

		{kind == 5}
		{8.do{|i|currentEnvironment.at(("buf"++i).asSymbol).setn(0, Signal.sineFill(512,Array.rand(512,0.001,0.01)).asWavetable)};}

		{kind == 6}
		{8.do{|i|currentEnvironment.at(("buf"++i).asSymbol).setn(0,Env([0]++ [(i+1).reciprocal.neg, (i+1).reciprocal]++(0), [0.0, 0.1, 0.0],\lin).asSignal(512).asWavetable)};}

		{kind == 7}
		{8.do{|i|currentEnvironment.at(("buf"++i).asSymbol).setn(0, Signal.sineFill(512,Array.rand(512,0.001,0.01)).asWavetable)};}

		{kind == 8}
		{
			~buf0.setn(0, Signal.sineFill(512, 1.0/[1,2,3,4,5,6]).asWavetable);
			~buf0.setn(0, Signal.sineFill(512, 1.0/(1..512)).asWavetable);
			~buf0.setn(0, Env([0]++ [-1, 1]++(0), [0.0, 0.1, 0.0],\lin).asSignal(512).asWavetable);
			~buf0.setn(0, Env([0]++ [-1, 0, 1]++(0), [0.1, 0.1, 0.1, 0.1],\lin).asSignal(512).asWavetable);
			~buf0.setn(0, Env([0, -1, 1], [0.1, 0.1],\step).asSignal(512).asWavetable);
			~buf0.setn(0, Env([0]++ Array.rand(10,-1,1.0)++(0), Array.rand(11,0.01,1.0),Array.fill(11,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable);
				~buf0.setn(0, Env([0]++ Array.rand(100,-1,1.0)++(0), Array.rand(101,0.01,1.0),Array.fill(101,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable);
			~buf0.setn(0, Env([0]++ Array.rand(510,-1,1.0)++(0), Array.rand(511,0.01,1.0),Array.fill(511,{[\lin, \sin, \wel].choose})).asSignal(512).asWavetable);



		}
	};


/* ######################################## MIDI mapping  ########################################*/

	s.sync;
	// MIDI init
	MIDIClient.init;
	MIDIIn.connectAll;


	//MIDI controllers
	~ampCC = 4;
	~bufoffsetCC = 16;
	~bufoffsetModCC = 17;
	~freqCarCC = 0;
	~freqModCC = 1;
	~mulModCC = 2;
	~addModCC = 18;
	~detuneCarCC = 3;
	~detuneModCC = 19;
	~tableCarNextCC = 64; // next carrier table
	~tableCarPrevCC = 65; // previous modulator table
	~tableModNextCC = 66; // next carrier table
	~tableModPrevCC = 67; // previous modulator table
	~freqCarRangeCC = 68; // multiply the freq by a factor of 5
	~freqModRangeCC = 69; // multiply the freq by a factor of 10


	~channelMIDI = 0;
	~freqCarRange = 1;
	~freqModRange = 1;
	~indexFreqCarRange = Pseq(#[5, 1],inf).asStream;
	~indexFreqModRange = Pseq(#[10, 1],inf).asStream;
	~tableCar = 0;    //init a variable to scan the tables
	~tableMod = 0;

	MIDIFunc.cc({|val,num,ch,src| ~ampCar.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~bufoffset.value(val.linlin(0, 127, 0.0, 7.0))}, ~bufoffsetCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~bufoffsetMod.value(val.linlin(0, 127, 8.0, 14.0))}, ~bufoffsetModCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~freqCar.value(val.linexp(0, 127, 20, 5000) * ~freqCarRange)}, ~freqCarCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~freqMod.value(val.linexp(0, 127, 0.05, 1000) * ~freqModRange)}, ~freqModCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~mulMod.value(val.linlin(0, 127, 1.0, 1000.0))}, ~mulModCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~addMod.value(val.linlin(0, 127, 1.0, 1000.0))}, ~addModCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~detuneCar.value(val.linlin(0, 127, -1000.0, 1000.0))}, ~detuneCarCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~detuneMod.value(val.linlin(0, 127, -1000.0, 1000.0))}, ~detuneModCC, ~channelMIDI);
	MIDIFunc.cc({|val, num, ch, src| if(val == 127){~freqCarRange = ~indexFreqCarRange.nextN(1)[0].value}}, ~freqCarRangeCC, ~channelMIDI);
	MIDIFunc.cc({|val, num, ch, src| if(val == 127){~freqModRange = ~indexFreqModRange.nextN(1)[0].value}}, ~freqModRangeCC, ~channelMIDI);

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~tableCar = ~tableCar + 1 % 10;
		~getWaveCar.value(~tableCar);
	}}, ~tableCarNextCC, ~channelMIDI);

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~tableCar = ~tableCar - 1 % 10;
		~getWaveCar.value(~tableCar);
	}}, ~tableCarPrevCC, ~channelMIDI);


	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~tableMod = ~tableMod + 1 % 10;
		~getWaveMod.value(~tableMod);
	}}, ~tableModNextCC, ~channelMIDI);

	MIDIFunc.cc({|val, num, ch, src| if(val == 127 and:{val != 0}){
		~tableMod = ~tableMod - 1 % 10;
		~getWaveMod.value(~tableMod);
	}}, ~tableModPrevCC, ~channelMIDI);

	"\n \n \n Ready to play".postln;
}
)
