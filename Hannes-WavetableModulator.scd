// demno
s.boot;

//Evaluate line by line

~bufTableCar=Buffer.alloc(s,1024, bufnum:0);
~bufTableMod=Buffer.alloc(s,1024, bufnum:1);
~envTableCar=Env([0]++ [1, 0.5]++0, [0.1, 0.1, 0.1], \sine).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar);
~envTableMod=Env([0]++ [1, 0.5]++0, [0.1, 0.1, 0.1], \sine).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);



~getWave = { //TODO: needs normalization
	|kind=0|
	case
	{kind==0}
	{~envTableMod=Env([0]++ [1, 0.8]++(-1), [0.5, 0.8, 0.3], \sqr).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}
	{kind==1}
	{~envTableMod=Env([0]++ [0, 1]++(0), [-0.1, 0.2, 0.2], \wel).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}
	{kind==2}
	{~envTableMod=Env([1,2, 0.5]++ [0, 1]++(0), [-0.1, 0.2, 0.2], \sin).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}
	{kind==3}
	{~envTableMod=Env([1,2, 0.5, 2]++ [0, 1]++(0), [-0.1, 0.2, 0.2], \sin).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}
	{kind==4}
	{~envTableMod=Env([1,2, 0.5]++ [0, 1]++(0), [-0.7, 0.5, -0.2], \cub).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}
	{kind==5}
	{~envTableMod=Env([1,2, 0.5]++ [0, 1]++(0), [-0.7, 0.5, -0.2], \cub).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);}

}

/*
(
~envTableMod=Env([1,-2, 0.5]++ [1, -1]++(0), [-0.7, 0, -0.2], \sin).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);
~envTableMod.plot();
)
*/
~getWave.value(5);
~envTableMod.plot();


(
//a Wavetable carrier
SynthDef(\carWable,{|freq=400, amp=0.1, bus=0, bufnum=1, gate=1|
        var output, env;
        env = EnvGen.ar(Env.asr(0.01,1,0.01),gate, doneAction:2);
        output = Osc.ar(bufnum,freq);
        Out.ar(bus,output*amp*env);
}).add;
);
(
//a Wavetable modulator
SynthDef(\modWable,{|freq=4, mul=1, add=0, bus=0, bufnum=0, gate=1, lag=1|
        var output, env;
        env = EnvGen.ar(Env.asr(0.01,1,0.01),gate, doneAction:2);
        output = Osc.kr(bufnum,freq.lag(lag),0,mul,add);
        Out.kr(bus,output*env);
}).add;
);


s.sendMsg(\s_new, "carWable",1010, 1, 1);
s.sendMsg(\n_set,1010,\freq,2000, \amp, 1);

s.sendMsg(\c_set, 400, 300);
s.sendMsg(\n_map, 1010, "freq", 400);

s.sendMsg(\s_new, "modWable",1030, 1, 1, \bus, 400, \mul, 1000);
s.sendMsg(\n_set,1030,\freq,2, \mul, 100, \add, 200, \lag, 10);
s.sendMsg(\n_set,1030,\freq,200, \mul, 1000, \add, 200, \lag, 20);

~envTableCar=Env([0]++ Array.rand2(5,1.0)++0,Array.rand(6,0.01,0.9), \sine).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar);
~envTableMod=Env([0]++ Array.rand2(5,1.0)++0,Array.rand(6,0.01,0.9), \sine).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);

~envTableCar=Env([0]++ Array.rand2(510,1.0)++0,Array.rand(511,0.01,0.9), \sine).asSignal(512).asWavetable;~bufTableCar.setn(0,~envTableCar);
~envTableMod=Env([0]++ Array.rand2(510,1.0)++0,Array.rand(511,0.01,0.9), \sine).asSignal(512).asWavetable;~bufTableMod.setn(0,~envTableMod);