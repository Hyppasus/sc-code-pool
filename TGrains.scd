//add closing function; free buffer, free syths, free midi;

s.quit
(
Server.default.waitForBoot{

	Server.default = s;

	s.sync;

	//MIDI controllers
	~trateCC = 1;
	~durCC = 2;
	~posCC = 3;
	~rateCC = 4;
	~selectPitchCC = 5;

	~channelMIDI = 0;

	s.sync;

	// MIDI init
	MIDIClient.init;
	MIDIIn.connectAll;

	s.sync;


	p = [];
	"/Sounds/*.aif".pathMatch.collect{|path|p=p.add(path)};
	b = Buffer.read(s, p[1],bufnum:0);
	b.normalize;

	//select for clock

	SynthDef(\granulator,{|trate = 2, pos = 0, amp = 1, bus = 0, dur = 2, rate = 1, selectPitch = 0|
    var clk, output;
    dur = (BufDur.kr(b))*dur / trate;
    clk = Impulse.kr(trate, 0,1,0);
    pos =(BufDur.kr(b))*pos;
		output = TGrains.ar(2, clk, b, Select.kr(selectPitch,[(2 ** WhiteNoise.kr(2)),rate]), pos, dur, 0.1);
	Out.ar(bus, output*amp);
}).add;





s.sync;

s.sendMsg(\s_new, "granulator", 1010, 1, 1);

s.sync;


~trate = {|trate = 2| s.sendMsg(\n_set, 1010, \trate, trate)};
~dur = {|dur = 8| s.sendMsg(\n_set, 1010, \dur, dur)};
~pos = {|pos = 0| s.sendMsg(\n_set, 1010, \pos, pos)};
~rate = {|rate = 1| s.sendMsg(\n_set, 1010, \rate, rate)};
~selectPitch = {|selectPitch = 1| s.sendMsg(\n_set, 1010, \selectPitch, selectPitch)};



MIDIFunc.cc({|val,num,ch,src| ~trate.value(val.linlin(0, 127, 1, 20))}, ~trateCC, ~channelMIDI);
MIDIFunc.cc({|val,num,ch,src| ~dur.value(val.linlin(0, 127, 0, 20))}, ~durCC, ~channelMIDI);
MIDIFunc.cc({|val,num,ch,src| ~pos.value(val.linlin(0, 127, 0 , 0.5))}, ~posCC, ~channelMIDI);
MIDIFunc.cc({|val,num,ch,src| ~rate.value(val.linlin(0, 127, -10, 20))}, ~rateCC, ~channelMIDI);
MIDIFunc.cc({|val,num,ch,src| ~selectPitch.value(val.linlin(0, 127, 0, 1))}, ~selectPitchCC, ~channelMIDI);



});

