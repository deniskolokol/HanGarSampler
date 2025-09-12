// SynthDefs for HanGarSampler
(
SynthDef(\bufplay, {
    arg out=0, buf=0, rate=1, amp=1, pan=0, lag=0.1, gate=1;
    var signal, env;
    
    // Combine manual gate with automatic release trigger
    env = EnvGen.kr(
        Env.asr(
            attackTime: lag,
            sustainLevel: 1,
            releaseTime: lag,
            curve: \sin
        ),
        gate: gate,
        doneAction: Done.freeSelf
    );
    
    signal = PlayBuf.ar(1, buf, BufRateScale.ir(buf)*rate, doneAction: Done.freeSelf);
    signal = signal * env * amp;
    signal = Pan2.ar(signal, pan);
    Out.ar(out, signal)
}).add;
)
