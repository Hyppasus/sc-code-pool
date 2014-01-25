// Use id node 1010 for the carrier and 1011 for the modulator
// use doneAction 4 to replace a node
// use buttons to change the wave form

~busModulator = Bus.control(s,1);
~busModulator.index;
s.sendMsg(\s_new, "carPulse", 1010, 1, 1);
s.sendMsg(\n_map, 1010, "freq", ~busModulator.index);
s.sendMsg(\c_set, ~busModulator.index, 300);
s.sendMsg(\c_set, ~busModulator.index, 600);
s.sendMsg(\s_new, "modPulse", 1011, 0, 4, \bus, ~busModulator.index, \freq, 1, \mul, 1000);
s.sendMsg(\n_set, 1011, \freq, 300, \mul, 10000, \add, 20)
s.sendMsg(\n_set, 1011, \freq, 1, \mul, 1000, \add, 100)




MIDIClient.init;
MIDIIn.connectAll;

~freqCC = MIDIFunc.cc({|value, num, ch, src|s.sendMsg(\n_set, 1011, \freq, value.map(0,127,20,20000))},1)//respond to cc 1

~freqCC.free;

a = MIDIFunc.cc({arg ...args; args.postln});
a.free;


x=0;
a = MIDIFunc.cc({|value, num, ch, src| if(value == 127){x=x+1%12;y[x].postln}});