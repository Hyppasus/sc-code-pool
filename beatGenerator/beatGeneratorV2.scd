(
Server.default.waitForBoot{

	Server.default.options.inDevice_("Built-in Input");
	Server.default.options.outDevice_("Built-in Output");

	s.sync;

	Server.default = s;

	s.sync;

	MIDIClient.init;
	MIDIIn.connectAll;

	s.sync;

	m = MIDIOut.newByName("nanoKONTROL2", "CTRL");
	m.latency_(0.001);

	s.sync;

	// MIDI cc

	~chMIDI = 0;

	~patternKKCC = 17;
	~pitchKKCC = 16;
	~ampKKCC = 0;


	~patternSNCC = 19;
	~pitchSNCC = 18;
	~ampSNCC = 2;

	~patternHHCC = 21;
	~pitchHHCC = 20;
	~ampHHCC = 4;

	~muteShufKKCC = 42;
	~muteShufSNCC = 41;
	~muteShufHHCC = 45;

	~freezeFftCC = 46;

	~ampDryCC = 6;
	~ampShufCC = 22;
	~ampFftCC = 23;
	//~delayAmpInCC = 44;

	~ledsKKCC = 32; // from 32 to 40
	~ledsSNCC = 48;
	~ledsHHCC = 64;

	~ampMasterCC = 7;

	// val init.

	~events = 4; // number of events of the patterns

	~pitchKK = 150;
	~ampKK = 0;
	~probKK = [1, 1].normalizeSum;



	8.do{ |i|
		currentEnvironment.put(("stepKK0"++i).asSymbol, x=0);
		currentEnvironment.put(("stepSN0"++i).asSymbol, x=0);
		currentEnvironment.put(("stepHH0"++i).asSymbol, x=0);
	};


	~pitchSN = 100;
	~ampSN = 0;
	~probSN = [1, 1].normalizeSum;


	~pitchHH = 4000;
	~ampHH = 0;
	~probHH = [1, 1].normalizeSum;

	s.sync;

	// BUFFERs alloc

	~samplerate = 44100;
	~bufShuf = Buffer.alloc(s, ~samplerate * 1, 2, bufnum:0);
	//~bufDelay = Buffer.alloc(s, ~samplerate * 1, 2, bufnum:1);

	s.sync;

	// BUSs definition

	~busKK = Bus.audio(s, 2);
	~busSN = Bus.audio(s, 2);
	~busHH = Bus.audio(s, 2);

	~shufBus = Bus.audio(s, 2);
	~fftBus = Bus.audio(s, 2);
	//~delayBus = Bus.audio(s, 2);


	s.sync;

	// INSTRUMENTs declaration

	SynthDef(\kick, {|bus = 0, pitch = 150, amp = 0|
		var
		pitchEnv = EnvGen.kr(Env.perc(0.001,0.8,1,-4), 1, doneAction: 2),
		bd = SinOsc.ar(pitch * pitchEnv),
		volEnv = EnvGen.kr(Env.perc(0.001, 0.8, 1, -4), 1, doneAction: 2);
		Out.ar(~busKK, Pan2.ar(bd * volEnv, 0, amp));
	}).add;

	SynthDef(\snare, {|bus = 0, pitch = 100, amp = 0|
		var
		pitchEnv = EnvGen.kr(Env.perc(0.01, 0.2, 1, -1), 1, doneAction:2),
		snareTop = SinOsc.ar(pitch * pitchEnv) - WhiteNoise.ar(0.5, 0.5),
		snareBottom = PinkNoise.ar(1),
		volEnv = EnvGen.kr(Env.perc(0.001, 0.2, 1, -10), 1, doneAction: 2);
		Out.ar(~busSN, Pan2.ar((snareTop + snareBottom) * volEnv, 0, amp));
	}).add;

	SynthDef(\hithat, {|bus = 0, pitch = 4000, amp = 0|
		var
		pitchEnv = EnvGen.kr(Env([1.0, 0.2, 0.2], [0.5, 0.5]), 1, doneAction: 2),
		hatNoise = PinkNoise.ar(1),
		hatPing = SinOsc.ar(pitch * pitchEnv, mul: 0.5),
		hatMod = SinOsc.ar(110, mul:0.2),
		ringMod = hatPing * hatMod,
		volEnv = EnvGen.kr(Env.perc(0.01, 0.01, 1, -20), 1, doneAction: 2);
		Out.ar(~busHH, Pan2.ar((ringMod + hatNoise) * volEnv, 0, amp));
	}).add;

	// FX declaration

	SynthDef(\recShufBuf,
		{ | bufnum=0, trig=1, muteKK=0, muteSN=0, muteHH=0 |
			var
			inKK = In.ar(~busKK.index, 2) * muteKK,
			inSN = In.ar(~busSN.index, 2) * muteSN,
			inHH = In.ar(~busHH.index, 2) * muteHH,
			in = inKK + inSN + inHH,
			rec = RecordBuf.ar(in, ~bufShuf, trigger: trig);
	}).add;


	SynthDef(\shuffler,
		{
			| bufnum=0, rate=1, startPos=0, startLoop=0, lenghtLoop=1, pos=0, ipol=2, mute=1, amp=0, out |
			var
			frames = BufFrames.kr(~bufShuf),
			endLoop = (startLoop + lenghtLoop) * frames,
			sig = LoopBuf.ar(
				2,
				~bufShuf,
				BufRateScale.kr(~bufShuf) * rate,
				mute,
				startPos * frames,
				startLoop * frames,
				endLoop,
				ipol);
			Out.ar(~shufBus, Pan2.ar(sig, pos, amp))}
	).add;


	SynthDef(\fftFx,
		{
			| freeze=0, amp=0 |
			var
			bufSize = 2048,
			dry = (In.ar(~busKK.index, 2) + In.ar(~busSN.index, 2) + In.ar(~busHH.index, 2)),
			shuff = In.ar(~shufBus.index, 2),
			sig = dry + shuff,
			chain = FFT({LocalBuf(bufSize)} ! 2, sig);
			chain = PV_MagFreeze(chain, freeze);
			chain = PV_MagNoise(chain);
			chain = PV_Invert(chain);
			Out.ar(~fftBus, ((IFFT(chain)).tanh.fold(-1,1)) * amp);
	}).add;

/*
	SynthDef(\delay,
		{
			| ampIn=0, delayTime=0.5, feedback=0.2 |
			var
			dry = (In.ar(~busKK.index, 2) +
				In.ar(~busSN.index, 2) +
				In.ar(~busHH.index, 2) +
				In.ar(~shufBus.index, 2) +
				In.ar(~fftBus.index, 2)),

			sig = PingPong.ar(~bufDelay, (dry * ampIn)!2, delayTime, feedback, 1);

			Out.ar(~delayBus, sig.tanh.fold(-1,1));
	}).add;
*/


	// MASTER

	SynthDef(\masterOut,
		{
			| out=0, ampDry=0, ampShuf=0, ampFft=0, amp=0|
			var
			dry = (In.ar(~busKK.index, 2) + In.ar(~busSN.index, 2) + In.ar(~busHH.index, 2))
			* ampDry,
			shuff = In.ar(~shufBus.index, 2),
			fft =  In.ar(~fftBus.index, 2),
			//delay = In.ar(~delayBus.index, 2),
			sig = dry + shuff + fft, // + delay
			output = Limiter.ar(sig, 0.9);
			Out.ar(out, sig * amp);
	}).add;


	s.sync;


	~shuffler = Pmono( \shuffler,
		\trig, 1,
		\startLoop, Pxrand((1/8!2)++(1/4!4)++(1/2!2),inf),
		\lenghtLoop, Pxrand((1/8!2)++(1/6!4)++(1/16!8)++(1/32!2),inf),
		\pos, {rrand(-1, 1)},
		\dur, Pxrand((1/8!2)++(1!4)++(1/2!2),inf),
	).play;

	s.sync;

	// INIT instruments

	s.sendMsg(\s_new, "recShufBuf", 2000, 1, 1);
	s.sendMsg(\s_new, "fftFx", 2010, 1, 1);
	//s.sendMsg(\s_new, "delay", 2020, 1, 1);
	s.sendMsg(\s_new, "masterOut", 3000, 1, 1);

	s.sync;

	// CONTROL functions

	~muteShufKK = {|mute = 0| s.sendMsg(\n_set, 2000, \muteKK, mute)};
	~muteShufSN = {|mute = 0| s.sendMsg(\n_set, 2000, \muteSN, mute)};
	~muteShufHH = {|mute = 0| s.sendMsg(\n_set, 2000, \muteHH, mute)};
	~ampShuf = {|amp = 0| s.sendMsg(\n_set, 2000, \amp, amp)};

	~freezeFft = {|freeze = 0| s.sendMsg(\n_set, 2010, \freeze, freeze)};
	~ampFft = {|amp = 0| s.sendMsg(\n_set, 2010, \amp, amp)};

	//~delayAmpIn = {|ampIn = 0| s.sendMsg(\n_set, 2020, \ampIn, ampIn)};

	~ampDry = {|amp = 0| s.sendMsg(\n_set, 3000, \ampDry, amp)};
	~ampMaster = {|amp = 0| s.sendMsg(\n_set, 3000, \amp, amp)};






	// MIDI FUNCTIONs

	/*||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	||||||||||||||||||||||||||| KICK controls ||||||||||||||||||||||||||
	||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

	// pattern generation

	MIDIFunc.cc({ |val|
		var
		pb1 = val.linlin(0, 127, 1.0, 0.5),
		pb2 = val.linlin(0, 127, 0.5, 1.0);
		~probKK = [pb1, pb2].normalizeSum;
		~patternKK = Array.fill(8, {[ 127, 0].wchoose(~probKK)});
		8.do{ |i|
			m.control(0,~ledsKKCC+i,~patternKK.at(i));
			currentEnvironment.put(("stepKK0"++i).asSymbol,
				x = ~patternKK.at(i)/127;
		)};

		~patternKK = Pseq(
				[~stepKK00, ~stepKK01, ~stepKK02, ~stepKK03, ~stepKK04, ~stepKK05, ~stepKK06, ~stepKK07], inf);

		Pdef(\playKK,
				Pbind (\instrument, \kick,
					\pitch, Pfunc({~pitchKK}),
					\amp, Pfunc({~ampKK}),
					\noteOrRest, Pif(~patternKK > 0, 1, Rest),
					\dur, 0.25)
			);
		//~patternKK.postln;
	}, ~patternKKCC, ~chMIDI);



	// step by step control

	8.do { |i|
		MIDIFunc.cc({ |val|
			currentEnvironment.put(("stepKK0"++i).asSymbol,
				x = val.linlin(0, 127, 0, 1);
			);

		~patternKK = Pseq(
				[~stepKK00, ~stepKK01, ~stepKK02, ~stepKK03, ~stepKK04, ~stepKK05, ~stepKK06, ~stepKK07]
				, inf);

		Pdef(\playKK,
				Pbind (\instrument, \kick,
					\pitch, Pfunc({~pitchKK}),
					\amp, Pfunc({~ampKK}),
					\noteOrRest, Pif(~patternKK > 0, 1, Rest),
					\dur, 0.25)
			);

			m.control(0, ~ledsKKCC + i, val); //for the LED

		}, ~ledsKKCC+i, ~chMIDI);
	};


	MIDIFunc.cc({|val| ~pitchKKFunc.value(val.linlin(0, 127, 80.0, 800.0))}, ~pitchKKCC, ~chMIDI);
	MIDIFunc.cc({|val| ~ampKKFunc.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampKKCC, ~chMIDI);
	~pitchKKFunc = {|pitch = 0| ~pitchKK = pitch};
	~ampKKFunc = {|amp = 0| ~ampKK = amp};





	/*||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	||||||||||||||||||||||||||| SNARE controls |||||||||||||||||||||||||
	||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

	// pattern generation

	MIDIFunc.cc({ |val|
		var
		pb1 = val.linlin(0, 127, 1.0, 0.5),
		pb2 = val.linlin(0, 127, 0.5, 1.0);
		~probSN = [pb1, pb2].normalizeSum;
		~patternSN = Array.fill(8, {[ 127, 0].wchoose(~probSN)});
		8.do{ |i|
			m.control(0,~ledsSNCC+i,~patternSN.at(i));
			currentEnvironment.put(("stepSN0"++i).asSymbol,
				x = ~patternSN.at(i)/127;
		)};

		~patternSN = Pseq(
				[~stepSN00, ~stepSN01, ~stepSN02, ~stepSN03, ~stepSN04, ~stepSN05, ~stepSN06, ~stepSN07], inf);

		Pdef(\playSN,
				Pbind (\instrument, \snare,
					\pitch, Pfunc({~pitchSN}),
					\amp, Pfunc({~ampSN}),
					\noteOrRest, Pif(~patternSN > 0, 1, Rest),
					\dur, 0.25)
			);
	}, ~patternSNCC, ~chMIDI);


	// step by step control

	8.do { |i|
		MIDIFunc.cc({ |val|
			currentEnvironment.put(("stepSN0"++i).asSymbol,
				x = val.linlin(0, 127, 0, 1);
			);

		~patternSN = Pseq(
				[~stepSN00, ~stepSN01, ~stepSN02, ~stepSN03, ~stepSN04, ~stepSN05, ~stepSN06, ~stepSN07]
				, inf);

		Pdef(\playSN,
				Pbind (\instrument, \snare,
					\pitch, Pfunc({~pitchSN}),
					\amp, Pfunc({~ampSN}),
					\noteOrRest, Pif(~patternSN > 0, 1, Rest),
					\dur, 0.25)
			);

			m.control(0, ~ledsSNCC + i, val); //for the LED

		}, ~ledsSNCC+i, ~chMIDI);
	};

	MIDIFunc.cc({|val| ~pitchSNFunc.value(val.linlin(0, 127, 80.0, 1000.0))}, ~pitchSNCC, ~chMIDI);
	MIDIFunc.cc({|val| ~ampSNFunc.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampSNCC, ~chMIDI);
	~pitchSNFunc = {|pitch = 0| ~pitchSN = pitch};
	~ampSNFunc = {|amp = 0| ~ampSN = amp};




	/*||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	||||||||||||||||||||||||||| HITHAT controls ||||||||||||||||||||||||
	||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

	// pattern generation

	MIDIFunc.cc({ |val|
		var
		pb1 = val.linlin(0, 127, 1.0, 0.5),
		pb2 = val.linlin(0, 127, 0.5, 1.0);
		~probHH = [pb1, pb2].normalizeSum;
		~patternHH = Array.fill(8, {[ 127, 0].wchoose(~probHH)});
		8.do{ |i|
			m.control(0,~ledsHHCC+i,~patternHH.at(i));
			currentEnvironment.put(("stepHH0"++i).asSymbol,
				x = ~patternHH.at(i)/127;
		)};

		~patternHH = Pseq(
				[~stepHH00, ~stepHH01, ~stepHH02, ~stepHH03, ~stepHH04, ~stepHH05, ~stepHH06, ~stepHH07], inf);

		Pdef(\playHH,
				Pbind (\instrument, \hithat,
					\pitch, Pfunc({~pitchHH}),
					\amp, Pfunc({~ampHH}),
					\noteOrRest, Pif(~patternHH > 0, 1, Rest),
					\dur, 0.25)
			);
	}, ~patternHHCC, ~chMIDI);



	// step by step control

	8.do { |i|
		MIDIFunc.cc({ |val|
			currentEnvironment.put(("stepHH0"++i).asSymbol,
				x = val.linlin(0, 127, 0, 1);
			);

		~patternHH = Pseq(
				[~stepHH00, ~stepHH01, ~stepHH02, ~stepHH03, ~stepHH04, ~stepHH05, ~stepHH06, ~stepHH07]
				, inf);

		Pdef(\playHH,
				Pbind (\instrument, \hithat,
					\pitch, Pfunc({~pitchHH}),
					\amp, Pfunc({~ampHH}),
					\noteOrRest, Pif(~patternHH > 0, 1, Rest),
					\dur, 0.25)
			);
			m.control(0, ~ledsHHCC + i, val); //for the LED
		}, ~ledsHHCC+i, ~chMIDI);
	};



	MIDIFunc.cc({|val| ~pitchHHFunc.value(val.linlin(0, 127, 4000.0, 12000.0))}, ~pitchHHCC, ~chMIDI);
	MIDIFunc.cc({|val| ~ampHHFunc.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampHHCC, ~chMIDI);
	~pitchHHFunc = {|pitch = 0| ~pitchHH = pitch};
	~ampHHFunc = {|amp = 0| ~ampHH = amp};





	/*||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	||||||||||||||||||||||||||| Fx controls ||||||||||||||||||||||||||||
	||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

	MIDIFunc.cc({|val|
		~muteShufKK.value(val.linlin(0, 127, 0, 1));
		m.control(0, ~muteShufKKCC, val);
	}, ~muteShufKKCC, ~chMIDI);

	MIDIFunc.cc({|val|
		~muteShufSN.value(val.linlin(0, 127, 0, 1));
		m.control(0, ~muteShufSNCC, val);
	}, ~muteShufSNCC, ~chMIDI);

	MIDIFunc.cc({|val|
		~muteShufHH.value(val.linlin(0, 127, 0, 1));
		m.control(0, ~muteShufHHCC, val);
	}, ~muteShufHHCC, ~chMIDI);

	MIDIFunc.cc({|val| ~ampShuf.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampShufCC, ~chMIDI);



	MIDIFunc.cc({|val|
		~freezeFft.value(val.linlin(0, 127, 0, 1));
		m.control(0, ~freezeFftCC, val);
	}, ~freezeFftCC, ~chMIDI);

	MIDIFunc.cc({|val| ~ampFft.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampFftCC, ~chMIDI);
/*
	MIDIFunc.cc({|val|
		~delayAmpIn.value(val.linlin(0, 127, 0.0, 1.0));
		m.control(0, ~delayAmpInCC, val);
	}, ~delayAmpInCC, ~chMIDI);
*/





	/*||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	||||||||||||||||||||||||||| Master controls ||||||||||||||||||||||||
	||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

	MIDIFunc.cc({|val| ~ampDry.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampDryCC, ~chMIDI);
	MIDIFunc.cc({|val| ~ampMaster.value(val.linlin(0, 127, 0.0, 1.0))}, ~ampMasterCC, ~chMIDI);

	s.sync;

	TempoClock.default.tempo = 140/60;

	s.sync;

	Pdef(\playKK).play(quant:Quant(1));
	Pdef(\playSN).play(quant:Quant(1));
	Pdef(\playHH).play(quant:Quant(1));

	s.sync;

	"\n \n  Ready to play".postln;
	"\n \n ".postln;
}
)