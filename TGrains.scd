ServerOptions.outDevices
Server.default.options.outDevice_("Soundflower (2ch)");
s.quit
(
Server.default.waitForBoot{

	Server.default = s;

	s.sync;

	//MIDI controllers
	~trateCC = 1;
	~durCC = 2;
	~posCC = 3;

	~channelMIDI = 0;

	s.sync;


	// MIDI init
	MIDIClient.init;
	MIDIIn.connectAll;

	s.sync;

	p = "/Sounds/KlappenTonal_1.aif";
	b = Buffer.read(s, p);



SynthDef(\granulator, {|trate = 0, dur = 8, pos = 0, amp = 0.5, bus = 0|
    var output, clk;
    dur = 8 / trate;
    clk = Impulse.kr(trate);
	pos = MouseX.kr(0,BufDur.kr(b));
    output = TGrains.ar(2, clk, b, 2 ** WhiteNoise.kr(2), pos, dur, 0.1);
	Out.ar(bus, output*amp);
}).add;


s.sync;

	s.sendMsg(\s_new, "granulator", 1010, 1, 1);

	s.sync;


~trate = {|trate = 0| s.sendMsg(\n_set, 1010, \amp, trate)};
~dur = {|dur = 8| s.sendMsg(\n_set, 1010, \trate, dur)};
~pos = {|pos = 0| s.sendMsg(\n_set, 1010, \pos, pos)};


	MIDIFunc.cc({|val,num,ch,src| ~trate.value(val.linlin(0, 127, 1, 400))}, ~trateCC, ~channelMIDI);

	MIDIFunc.cc({|val,num,ch,src| ~dur.value(val.linlin(0, 127, 0, 0, 1))}, ~durCC, ~channelMIDI);
	MIDIFunc.cc({|val,num,ch,src| ~pos.value(val.linlin(0, 127, 0.0, 1.0))}, ~posCC, ~channelMIDI);

});
