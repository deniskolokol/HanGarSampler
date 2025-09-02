// SynthDefs for HanGarSampler
(
SynthDef(\bufplay, {
    arg out=0, buf=0, rate=1, amp=1, pan=0, lag=0.1, gate=1;

    var bufDur = BufDur.kr(buf) / rate;
    
    // Envelope that automatically releases after buffer duration
    var env = EnvGen.kr(
        Env.new(
            levels: [0, 1, 1, 0],
            times: [lag, max(bufDur - (2 * lag), 0.01), lag],
            curve: [\sin, \lin, \sin]
        ),
        gate: gate,
        doneAction: 2
    );
    
    var signal = PlayBuf.ar(1, buf, BufRateScale.ir(buf)*rate, doneAction: 0);
    signal = signal * env * amp;
    signal = Pan2.ar(signal, pan);
    Out.ar(out, signal)
}).add;
)
