Buffer.read(s, "/Users/Tenuria/Sounds/Voix/liisa4.aif", bufnum:0);
Buffer.read(s, "/Users/Tenuria/Sounds/SuperColliderSounds/break.aiff", bufnum:1);
(
{
	var in, chain, mod, bufSize=1024;
	in = PlayBuf.ar(1, 0, BufRateScale.kr(0), loop:1);
	//in = SoundIn.ar;
	chain = FFT(LocalBuf(bufSize), in);
	v = MouseX.kr(-1, 1);
/*	chain = chain.pvcollect(1024, {|freq, phase, index|
		freq + DelayN.kr(freq, 1, v);}, 0, 256, 1);
	*/

	//chain = PV_MagFreeze(chain, SinOsc.kr(0.5));
	chain = PV_BinScramble(chain,MouseX.kr, MouseY.kr,Impulse.kr(1));
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
