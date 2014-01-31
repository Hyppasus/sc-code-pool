//vector synthesis module

/*

idea:

2in, 2out
4 buffers, user can record in each of them by pressing a corresponding button
a 2d carthagian plane, representing playback ratio of these 4 buffers
random movement of the ratio point
user can 'attract' the ratio point to one of the corners


*/

//the code:

s.boot;

//allocate buffers
(
a = Buffer.alloc(s, s.sampleRate * 10, 2);
b = Buffer.alloc(s, s.sampleRate * 10, 2);
c = Buffer.alloc(s, s.sampleRate * 10, 2);
d = Buffer.alloc(s, s.sampleRate * 10, 2);
)
//allocate files
(
a.allocRead("/home/andre/Documents/SibA/Supercollider/git/sounds/1.wav");
b.allocRead("/home/andre/Documents/SibA/Supercollider/git/sounds/2.wav");
c.allocRead("/home/andre/Documents/SibA/Supercollider/git/sounds/3.wav");
d.allocRead("/home/andre/Documents/SibA/Supercollider/git/sounds/4.wav");
)

//prepare synthDefs
(
SynthDef(\buf, {
	| out = 0, amp = 1, bufnum=99|
    Out.ar(
		out,
        PlayBuf.ar(2, bufnum, 1, 1, 0, 1)*amp;
    )
}).add;
)

//init synths

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

)

//ratio point movement
//TODO: not global!
(
  ~x;
  ~y; //current position
  ~tX;
  ~tY; //target position
  ~t; //timer
  ~speed; //less is more!
  ~maxT; //max timer
  ~x = 0.5;
  ~y = 0.5;
  ~tX = ~x;
  ~tY = ~y;
  ~t = 0;
  ~speed = 2;
  ~maxT = 1;
)



//control point movement call
(
m = {
	//timer check
	~t = if (~t > ~maxT,
		{
			//yup, targetPos change

			~maxT=rand(300);
			~tX=rand(1.0);
			~tY=rand(1.0);
			~speed=rand(100.0)+1;
			0;
	    },
		{
			//nup, return increment
			~t+1;
		}
	);

	//move the point
	//haxxor
	s = ~speed;
	c = ~tX-~x;
	~x = ~x + ((~tX-~x)/~speed);
	c = ~tY-~y;
	~y = ~y + ((~tY-~y)/~speed);

	//set amp values for each
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
}
)






//timer clock to call the movement
(SystemClock.sched(0.0,
	{
		m.value;
		0.01;
	}
);)





//x, y tracer
(
p = {
	x = round(~x*100);
	y = round(~y*100);
	[x, y].postln;
}
)

(SystemClock.sched(0.0,
	{

		p.value;
		0.01;
	}
);)


//cleanup the mess
SystemClock.clear;

(
a.free;
b.free;
c.free;
d.free;
)