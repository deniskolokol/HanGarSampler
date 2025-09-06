(
// Prototype of a sampler player class.
// Lazy-loading: upon creation of the instance only the first buffer is loaded,
// others are being loaded when the previous are being played.
~samplePlayer = {
    arg name, // <String> name of the player instance
        samples; // <Array> of <String> sample filenames with full path

    // <Event> as an object prototype
    var player = (
        name: name,  // <String> player's name
        samples: samples,  // <Array> of sample filenames
        buffers: nil, // <Array> of loaded buffers
        synths: nil, // <Array> of active synths
        currentIndex: nil, // <Integer> index of currently playing sample
        currentlyPlaying: nil, // <String> filename of currently playing sample

        init: { arg self;
            // Initialize buffers and synths arrays
            self.buffers = Array.fill(self.samples.size, nil);
            self.synths = Array.fill(self.samples.size, nil);

            // Initialization means loading the first sample in `samples`
            self.currentIndex = 0; // start from the first sample
            self.load;

            // Return self for chaining
            self
        },

        start: { |self ... args|
            // The logic is very straightforward: every time `start` is called,
            // it advances to the next sample, i.e.:
            // - always play the next sample in the list
            // - if no samples were played yet, start from the first one
            // - if a sample is already playing, first stop it and then play the
            // next one
            // - wrap around to the first sample after the last one
            //
            // WARNING: we do not load all samples at .init, only the first one.
            // Therefore at the same time a sample is played, it is necessary to
            // load the next one.
            //
            // Args: variable arguments passed to Synth as parameter pairs

            var samplePath, synthArgs;

            if (self.samples.isNil.not and: { self.samples.size > 0 }) {
                if (self.currentIndex.isNil) {
                    // Start from the first sample
                    self.currentIndex = 0;
                } {
                    // Wrap around
                    self.currentIndex = self.getNextIndex;
                };

                // Within one player, only one sample can be played at a time
                if (self.currentlyPlaying.notNil) { self.kill };

                samplePath = self.samples[self.currentIndex];
                self.currentlyPlaying = samplePath;
                
                // Build synth arguments: always include buffer, then add user args
                synthArgs = [\buf, self.buffers[self.currentIndex]] ++ args;
                
                self.synths[self.currentIndex] = Synth(\bufplay, synthArgs);

                // Load the next sample in the background
                self.load(self.getNextIndex);
            } {
                "No samples available to play.".postln;
            };
        },

        kill: { |self|
            if (self.currentlyPlaying.notNil) {
                self.synths[self.currentIndex].set(\gate, 0, \lag, 0.5);
                self.currentlyPlaying = nil;
            };
        },

        getNextIndex: { |self|
            (self.currentIndex + 1) % self.samples.size
        },

        isBufferLoaded: { |self, index|
            if (self.buffers.notNil) {
                var buf = self.buffers[index];
                if (buf.notNil) {
                    (buf.numFrames.notNil and: { buf.numFrames > 0 })
                } { 
                    false
                }
            } { 
                false 
            };
        },

        load: { |self, index=0|
            var buf;
            var loadingRoutine;

            if (self.samples.notNil and: {self.samples.size > 0}) {
                // Preload the buffer
                if (self.isBufferLoaded(index).not) {
                    "Loading buffer for sample %...".format(self.samples[index]).postln;
                    buf = Buffer.read(
                        s,
                        self.samples[index],
                        action: {|buf|
                            self.buffers[index] = buf;
                        }
                    );
                    loadingRoutine = Routine({
                        while { buf.numFrames.isNil } {
                            0.1.wait; // wait until buffer is loaded
                        };
                        loadingRoutine.stop;
                    }).play;
                };
            } {
                "No samples available to load.".postln;
            };
        }
    );

    // return player
    player.init.();
};


// Walk through samples directory and build the Event
~getSamples = {
    arg path; // <String>
    var result = Event.new;

    // Get folders and sort them to ensure consistent order
    var dirNames = PathName(path).folders.sort({ |a, b| 
        a.folderName < b.folderName 
    });

    dirNames.do({ |dirName|
        var audioFiles;
        
        // Get all .wav, .aif, and .aiff files in this dirName
        audioFiles = dirName.entries.select({ |file|
            var extension = file.extension.toLower;
            (extension == "wav") || (extension == "aif") || (extension == "aiff")
        }).collect({ |file|
            file.fullPath
        });

        // Add to Event if we found any audio files
        if(audioFiles.size > 0) {
            result.put(dirName.folderName.asSymbol, audioFiles);
        };
    });

    // returns Event (ordered dictionary)
    result
};


// Load external file
~loadExternal = { 
    arg path,
        descr,
        requiresSync=true;

    postf("> Loading %... ", descr);
    if (this.executeFile(path).isNil.not) {
        "OK".postln;
        if (requiresSync) {
            "[i] Server sync... ".post;
            s.sync; // wait until all asynchronous tasks are finished
            "OK".postln;
        };
    } {
        postf("ERROR: Could not load %!\n", path);
    };
};


// Initialize empty Event for samples (maintains order of keys)
~samples = Event.new;

// Root directory is empty string before the first choice accepted
~rootDir = "";

// Initialize Dictionary for sample players
~players = Dictionary.new;

// Show the GUI
~loadExternal.(
    PathName(thisProcess.nowExecutingPath).parentPath +/+ "gui.scd",
    "GUI",
    false
);
)

// (
// // Use it like this:
// ~players[\high].name
// ~players[\high].currentlyPlaying; // nil
// ~players[\high].currentIndex
// ~players[\high].samples
//
// ~players[\mid].buffers
// ~players[\mid].start // plays first sample in ~samples[\low]
// ~players[\mid].currentlyPlaying; // "sample1.wav" (for example)
// ~players[\mid].kill // stops playing current sample
// )
