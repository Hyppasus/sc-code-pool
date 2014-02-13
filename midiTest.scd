

MIDIClient.init;
MIDIIn.connectAll;

o=MIDIFunc.noteOn({arg vel, note, ch, src;[vel, note, ch, src].postln});
p=MIDIFunc.noteOff({arg ...args; args.postln});
q=MIDIFunc.cc({arg ...args; args.postln});
r=MIDIFunc.touch({arg ...args; args.postln}); // match any ch
m=MIDIFunc.bend({arg ...args; args.postln}); // match any ch
n=MIDIFunc.program({arg ...args; args.postln}); // match any ch

[o,p,q,r,m,n].free;