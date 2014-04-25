/*
	Vector mixer/FFT processor module.

Idea:

2in, 2out

4 buffers, user can record in each of them by pressing a corresponding button
a 2d carthagian plane, representing playback ratio of these 4 buffers.
The movement of the control point is randomized and the
user can 'attract' the ratio point to one of the corners.

User can effect the individual sources with FFT smudge and freeze.



The code:

*/

Server.default.waitForBoot{ s = Server.default;

/*
	Allocate four 10sec buffers for the four stereo sound sources.
*/
(
a = Buffer.alloc(s, s.sampleRate * 10, 2);
b = Buffer.alloc(s, s.sampleRate * 10, 2);
c = Buffer.alloc(s, s.sampleRate * 10, 2);
d = Buffer.alloc(s, s.sampleRate * 10, 2);
); s.sync;

/*
	For now, we're allocating the files from the HDD.
*/
(
a.allocRead("/home/andre/Documents/SibA/Supercollider/git/sounds/1.wav");
b.allocRead("/home/andre/Documents/SibA/Supercollider/git/sounds/5.wav");
c.allocRead("/home/andre/Documents/SibA/Supercollider/git/sounds/6.wav");
d.allocRead("/home/andre/Documents/SibA/Supercollider/git/sounds/7.wav");
); s.sync;

/*
	Prepare SynthDefs for buffer playback and amp control.
*/
(
SynthDef(\buf, {
	| out = 0, amp = 1, bufnum=99 , frz=0, sft=0|
	var in, chain, mod, bufSize = 1024;
	in = PlayBuf.ar(2, bufnum, 1, 1, 0, 1)*amp;
	chain = FFT(LocalBuf(bufSize), in);
	chain = PV_MagFreeze(chain, frz);
	chain = PV_MagSmear(chain, sft, sft);
	chain = PV_BinScramble(chain, sft, sft);
	Out.ar(0, tanh(IFFT(chain).dup*amp*SinOsc.ar(sft*10)*(sft/2+5)));
	/*
	Out.ar(
	out,
	PlayBuf.ar(2, bufnum, 1, 1, 0, 1)*amp;
	)*/
	}).add;
); s.sync;

/*
	Set SynthDef default values
*/

(
e = Synth(\buf);
e.set(\bufnum, a);
e.set(\amp, 0);
f = Synth(\buf);
f.set(\bufnum, b);
f.set(\amp, 0);
g = Synth(\buf);
g.set(\bufnum, c);
g.set(\amp, 0);
h = Synth(\buf);
h.set(\bufnum, d);
h.set(\amp, 0);

); s.sync;

/*
	Control point movement vars init.
*/
(
  ~x;
  ~y; //current positions
  ~tX;
  ~tY; //target positions
  ~t; //timer
  ~speed; //less is more!
  ~maxT; //max timer
  ~x = 0.5;
  ~y = 0.5; //we begin in the center
  ~tX = ~x;
  ~tY = ~y;
  ~t = 0; //tick timer
  ~speed = 2;
  ~maxT = 1; //max timer

  ~pullToX=0;
  ~pullToY=0;
  ~channelMidi = 0;
  ~lastNote="-1";
  ~nTX=0;
  ~nTY=0;

  //clockwise from top left
  ~freeze1=0;
  ~freeze2=0;
  ~freeze3=0;
  ~freeze4=0;

  ~shift1=0;
  ~shift2=0;
  ~shift3=0;
  ~shift4=0;
); s.sync;

//midi binding
(
MIDIClient.init;
MIDIIn.connect;


MIDIIn.noteOn = { arg src, chan, num, vel; ~lastNote=num;};
MIDIIn.noteOff = { arg src, chan, num, vel; ~lastNote="-1";};

~control={arg port, ch, num, val;
	//TODO: switch
	if(num==1){~freeze1=val.linlin(0, 127, 0.0, 1.0)};
	if(num==2){~freeze2=val.linlin(0, 127, 0.0, 1.0)};
	if(num==5){~freeze3=val.linlin(0, 127, 0.0, 1.0)};
	if(num==6){~freeze4=val.linlin(0, 127, 0.0, 1.0)};

	if(num==3){~shift1=val.linlin(0, 127, 0.0, 1.0)};
	if(num==4){~shift2=val.linlin(0, 127, 0.0, 1.0)};
	if(num==8){~shift3=val.linlin(0, 127, 0.0, 1.0)};
	if(num==7){~shift4=val.linlin(0, 127, 0.0, 1.0)};
};

MIDIIn.addFuncTo('control', ~control);

); s.sync;

//control point movement call
(
m = {
   //assing user pull values, give -1 to disable pull
	//TODO swith override
	~pullToX = if (~lastNote == 36, //magic number!
		{
			0;
		},
		{
			if (~lastNote == 37, //magic number!
				{
					1;
				},
				{
					if (~lastNote == 40, //magic number!
						{
							0;
						},
						{
							if (~lastNote == 41, //magic number!
								{
									1;
								},
								{
									-1;
								}
							);
						}
					);
				}
			);
		}
	);

	~pullToY = if (~lastNote == 36, //magic number!
		{
			0;
		},
		{
			if (~lastNote == 37, //magic number!
				{
					0;
				},
				{
					if (~lastNote == 40, //magic number!
						{
							1;
						},
						{
							if (~lastNote == 41, //magic number!
								{
									1;
								},
								{
									-1;
								}
							);
						}
					);
				}
			);
		}
	);





	//timer check
	~t = if (~t > ~maxT,
		{
			/*
				Timer has ran up, randomly
				choose a new target position.
			*/

			~maxT=rand(300);
			~tX=rand(1.0);
			~tY=rand(1.0);
			~speed=rand(100.0)+1;
			0; //return 0 for reset timer
	    },
		{
			// tick
			~t+1;
		}
	);

	/*
		Pull code. The user will be able to manually pull
		the control point towards one of the corners.
		This shalt be a temporary pull, with the control
		point returning to its original position upon
		releasing the pull.
	*/
	//override ~tX by user?
	~nTX =  if (~pullToX < 0,
		{
			//nope
			~tX;
	    },
		{
			//override!
			~pullToX;
		}
	);
	//override ~tY by user?
	~nTY =  if (~pullToY < 0,
		{
			//nope
			~tY
	    },
		{
			//override!
			~pullToY;
		}
	);

	~x = ~x + ((~nTX-~x)/~speed);
	~y = ~y + ((~nTY-~y)/~speed);

	//set FFT parameter based on CC which are stored in ~diffuse<num>
	e.set(\frz, ~freeze4);
	f.set(\frz, ~freeze3);
	g.set(\frz, ~freeze2);
	h.set(\frz, ~freeze1);

	e.set(\sft, ~shift4);
	f.set(\sft, ~shift3);
	g.set(\sft, ~shift2);
	h.set(\sft, ~shift1);

	//set amp values for each based on the control point distance from the individual sources
	//bottom-left
	e.set(\amp, 1-sqrt((~x*~x) + (~y*~y)));
	//bottom-right
	f.set(\amp, 1-sqrt(((1-~x)*(1-~x)) + (~y*~y)));
	//top-right
	g.set(\amp, 1-sqrt(((1-~x)*(1-~x)) + ((1-~y)*(1-~y))));
	//top-left
	h.set(\amp, 1-sqrt((~x*~x) + ((1-~y)*(1-~y))));
	//celebrate
	~t;

	/*
	TODO:
		Freeze and smudge FFT functions for individual sources,
		pull towards one of the corners

	*/
}
); s.sync;



//timer clock to call the movement
(SystemClock.sched(0.0,
	{
		m.value;
		0.01;
	}
);); s.sync;





//x, y tracer
(
p = {
	x = round(~x*100);
	y = round(~y*100);
	[x, y].postln;
	//~shift4.postln;
};



); s.sync;

//what does this do??
(SystemClock.sched(0.0,
	{

		p.value;
		0.01;
	}
);); s.sync;

};


//cleanup the mess
/*SystemClock.clear;

(
a.free;
b.free;
c.free;
d.free;
)*/