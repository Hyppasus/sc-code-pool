Buffer.read(s, "/Users/Tenuria/Sounds/Voix/liisa4.aif", bufnum:0);
Buffer.read(s, "/Users/Tenuria/Sounds/SuperColliderSounds/break.aiff", bufnum:1);
x=Buffer.alloc(s, 1024, bufnum:3)
x.plot
x.inspect
x.as
(
{
	var in, chain, mod, bufSize=1024;
	in = PlayBuf.ar(1, 0, BufRateScale.kr(0), loop:1);
	//in = SoundIn.ar;
	chain = FFT(LocalBuf(bufSize), in);
	//chain = FFT(3,in);
	v = MouseX.kr(0, 1.0);
/*	chain = chain.pvcollect(1024, {|freq, phase, index|
		freq + DelayN.kr(freq, 1, v);}, 0, 256, 1);
	*/
  chain = chain.pvcalc(bufSize, {|mags, phases|
      /* Play with the mags and phases, then return them */
      //[mags, phases].flop.clump(2).flop.flatten
		phases+;

	});
/*		PV_Conj*/
	//chain = PV_MagFreeze(chain, SinOsc.kr(0.5));
	//chain = PV_BinScramble(chain,MouseX.kr, MouseY.kr,Impulse.kr(1));
	Out.ar(0, IFFT(chain)+in)

}.play
);

(
{
	var inA, inB, chain, chainA, chainB, mod, bufSize=1024;
	inA = PlayBuf.ar(1, 0, BufRateScale.kr(0), loop:1);
	inB = PlayBuf.ar(1, 1, BufRateScale.kr(0), loop:1);
	chainA = FFT(LocalBuf(bufSize), inA);
	chainB = FFT(LocalBuf(bufSize), inB);
	//v = MouseX.kr(-1, 1);
/*	chain = chain.pvcollect(1024, {|freq, phase, index|
		freq + DelayN.kr(freq, 1, v);}, 0, 256, 1);
	*/

	// chain = PV_Morph(chainA, chainB, MouseX.kr(-1,1));
		chain = PV_XFade(chainA, chainB, MouseX.kr(-1,1));
	Out.ar(0, IFFT(chain).dup)

}.play
)



(
{
	var in, chain, mod, bufSize=1024;
	in = PlayBuf.ar(1, 0, BufRateScale.kr(0), loop:1);
	//in = SoundIn.ar;
	chain = FFT(LocalBuf(bufSize), in);
	v = MouseX.kr(0.1, 2);
	chain = chain.pvcollect(1024, {|freq, phase, index|
		freq + DelayN.kr(freq, 1, v*(index*512.reciprocal));}, 0, 512, 1);



	Out.ar(0, IFFT(chain)+in)

}.play
);





(
// a bit noisy
{ var in, chain, output, frames = 512;

    var ampFollow;

	in = PlayBuf.ar(1, 1, BufRateScale.kr(1), loop: 1);
    ampFollow = Amplitude.kr(in).lag(0.6, 0.8);

    chain = [FFT(LocalBuf(frames), in), nil];

    chain[0] = chain[0].pvcollect(frames, {|mag, phase, index|

        mag = mag * SinOsc.kr(0.2 + ((index.wrap(0, 6) * 0.4)), rrand(0, 0.9)).range(0.2, 1);
        mag = if(index % 9 == 0, 0.2, mag);
        phase = 10 - phase;
        phase = phase * SinOsc.kr(0.5).exprange(0.25, 8);
        phase = if(phase % 11 == 0, 4, phase);
        [mag, phase];

    }, frombin: 2, tobin: 24, zeroothers: 1);

    output = [IFFT(chain[0]), nil];
    output[0] = output[0].fold(-0.06, 0.06);

    chain[1] = FFT(LocalBuf(frames), Mix.new(output[0]));
    chain[1] = PV_BinShift(chain[1], ampFollow.range(50, 0.4), ampFollow.range(-400, 60));
    output[1] = IFFT(chain[1]);

    output = Mix.new(output * [0.8, 1.5]) ! 2;
}.play(s);
)




(
s.boot.doWhenBooted{
c = Buffer.read(s,"sounds/a11wlk01.wav");
}
)

// spectral delay - here we use a DelayN UGen to delay the bins according to MouseX location
(
{
	var in, chain, v;
	in = PlayBuf.ar(1, c, BufRateScale.kr(c), loop: 1);
	chain = FFT(LocalBuf(1024), in);

	v = MouseX.kr(0.1, 1);

	chain = chain.pvcollect(b.numFrames, {|mag, phase, index|
		mag + DelayN.kr(mag, 1, v);
	}, frombin: 0, tobin: 256, zeroothers: 1);

	Out.ar(0, 0.5 * IFFT(chain).dup);
}.play(s);
)

// another type of spectral delay where the high frequencies get longer delay times
// this is the trick: 250.do({|i|(i*(250.reciprocal)).postln;})
(
{
	var in, chain, v;
	in = PlayBuf.ar(1, c, BufRateScale.kr(c), loop: 1);
	chain = FFT(LocalBuf(1024), in);

	v = MouseX.kr(0.1, 2);

	chain = chain.pvcollect(b.numFrames, {|mag, phase, index|
		mag + DelayN.kr(mag, 1, v*(index*256.reciprocal));
	}, frombin: 0, tobin: 256, zeroothers: 0);

	Out.ar(0, 0.5 * IFFT(chain).dup);
}.play(s);
)



// yet another spectral delay where the each bin gets a random delay time
(
{
	var in, chain, v;
	in = PlayBuf.ar(1, c, BufRateScale.kr(c), loop: 1);
	chain = FFT(LocalBuf(1024), in);

	v = MouseX.kr(0.1, 2);

	chain = chain.pvcollect(b.numFrames, {|mag, phase, index|
		mag + DelayN.kr(mag, 1, v*1.0.rand);
	}, frombin: 0, tobin: 256, zeroothers: 0);

	Out.ar(0, 0.5 * IFFT(chain).dup);
}.play(s);
)

// spectral delay where the delaytimes are modulated by an oscillator
(
{
	var in, chain, v;
	in = PlayBuf.ar(1, c, BufRateScale.kr(c), loop: 1);
	chain = FFT(LocalBuf(1024), in);

	v = MouseX.kr(0.1, 2);

	chain = chain.pvcollect(b.numFrames, {|mag, phase, index|
		mag + DelayN.kr(mag, 1, v*SinOsc.ar(0.5).range(0.1,1));// play with Tri or LFSaw, etc.
	}, frombin: 0, tobin: 256, zeroothers: 0);

	Out.ar(0, 0.5 * IFFT(chain).dup);
}.play(s);
)



// amplitude controlled with MouseX and phase manipulation with MouseY
(
{
	var in, chain, v;
	in = PlayBuf.ar(1, c, BufRateScale.kr(c), loop: 1);
	chain = FFT(LocalBuf(1024), in);

	chain = chain.pvcollect(b.numFrames, {|mag, phase, index|
		[mag * MouseX.kr(0.5, 2), phase / MouseY.kr(0.5, 30)]
	}, frombin: 0, tobin: 250, zeroothers: 0);

	Out.ar(0, 0.5 * IFFT(chain).dup);
}.play(s);
)



// here we add noise to the phase
(
{
	var in, chain, v;
	in = PlayBuf.ar(1, c, BufRateScale.kr(c), loop: 1);
	chain = FFT(LocalBuf(1024), in);

	chain = chain.pvcollect(b.numFrames, {|mag, phase, index|
		[mag, LFNoise0.kr.range(0, 3.14)];
	}, frombin: 0, tobin: 250, zeroothers: 1);

	Out.ar(0, 0.5 * IFFT(chain).dup);
}.play(s);
)


// square the magnitude and put a random phase (from 0 to pi (3.14))
(
{
	var in, chain, v;
	in = PlayBuf.ar(1, c, BufRateScale.kr(c), loop: 1);
	chain = FFT(LocalBuf(1024), in);

	chain = chain.pvcollect(b.numFrames, {|mag, phase, index|
		[mag.sqrt, pi.rand];
	}, frombin: 0, tobin: 256, zeroothers: 1);

	Out.ar(0, 0.5 * IFFT(chain).dup);
}.play(s);
)

// here we use the index and we subtract it with a LFPar on a slow sweep
(
{
	var in, chain, v;
	in = PlayBuf.ar(1, c, BufRateScale.kr(c), loop: 1);
	chain = FFT(LocalBuf(1024), in);

	chain = chain.pvcollect(b.numFrames, {|mag, phase, index|
		if((index-LFPar.kr(0.1).range(2, b.numFrames/20)).abs < 10, mag, 0); // swept bandpass
	}, frombin: 0, tobin: 250, zeroothers: 0);

	Out.ar(0, 0.5 * IFFT(chain).dup);
}.play(s);
)


Post << 512.collect({|i| (22050/512)*(i+1)})




// morph - morphs between two buffers
(
SynthDef(\pvmorph, { arg out=0, soundBufnum1=2, soundBufnum2=3;
	var inA, chainA, inB, chainB, chain;
	inA = PlayBuf.ar(1, soundBufnum1, BufRateScale.kr(soundBufnum1), loop: 1);
	inB = PlayBuf.ar(1, soundBufnum2, BufRateScale.kr(soundBufnum2), loop: 1);
	chainA = FFT(LocalBuf(2048), inA);
	chainB = FFT(LocalBuf(2048), inB);
	chain = PV_Morph(chainA, chainB, MouseX.kr);
	Out.ar(out,  IFFT(chain).dup);
}).play(s,[\out, 0, \soundBufnum1, d.bufnum, \soundBufnum2, e.bufnum]);
)


// XFade - interpolates bins between two buffers
(
SynthDef(\pvmorph, { arg out=0, soundBufnum1=2, soundBufnum2=3;
	var inA, chainA, inB, chainB, chain;
	inA = PlayBuf.ar(1, soundBufnum1, BufRateScale.kr(soundBufnum1), loop: 1);
	inB = PlayBuf.ar(1, soundBufnum2, BufRateScale.kr(soundBufnum2), loop: 1);
	chainA = FFT(LocalBuf(2048), inA);
	chainB = FFT(LocalBuf(2048), inB);
	chain = PV_XFade(chainA, chainB, MouseX.kr);
	Out.ar(out,  IFFT(chain).dup);
}).play(s,[\out, 0, \soundBufnum1, d.bufnum, \soundBufnum2, e.bufnum]);
)



// softwipe - Copies low bins from one input and the high bins of the other
(
SynthDef(\pvsoftwipe, { arg out=0, soundBufnum1=2, soundBufnum2=3;
	var inA, chainA, inB, chainB, chain;
	inA = PlayBuf.ar(1, soundBufnum1, BufRateScale.kr(soundBufnum1), loop: 1);
	inB = PlayBuf.ar(1, soundBufnum2, BufRateScale.kr(soundBufnum2), loop: 1);
	chainA = FFT(LocalBuf(2048), inA);
	chainB = FFT(LocalBuf(2048), inB);
	chain = PV_SoftWipe(chainA, chainB, MouseX.kr);
	Out.ar(out,  IFFT(chain).dup);
}).play(s,[\out, 0, \soundBufnum1, d.bufnum, \soundBufnum2, e.bufnum]);
)


// magminus - subtracting spectral energy - Subtracts buffer B's magnitudes from buffer A.
(
SynthDef(\pvmagminus, { arg out=0, soundBufnum1=2, soundBufnum2=3;
	var inA, chainA, inB, chainB, chain;
	inA = PlayBuf.ar(1, soundBufnum1, BufRateScale.kr(soundBufnum1), loop: 1);
	inB = PlayBuf.ar(1, soundBufnum2, BufRateScale.kr(soundBufnum2), loop: 1);
	chainA = FFT(LocalBuf(2048), inA);
	chainB = FFT(LocalBuf(2048), inB);
	chain = PV_MagMinus(chainA, chainB, MouseX.kr(0, 1));
	Out.ar(out,  IFFT(chain).dup);
}).play(s,[\out, 0, \soundBufnum1, d.bufnum, \soundBufnum2, e.bufnum]);
)





