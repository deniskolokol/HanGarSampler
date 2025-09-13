s.quit;

(
// Server config.
Server.default = s = Server.local;

~cPosition = {
    arg x = 0, y = 0, radius = 10;
    
    // <Event> as an object prototype for position
    var position = (
        x: x,
        y: y, 
        radius: radius,

        init: { |self|
            // Initialize
            self.set(x, y, radius);
            // Return self for chaining
            self
        },

        // Method to set all coordinates at once
        set: { |self, newX, newY, newRadius|
            self.x = newX;
            self.y = newY;
            if (newRadius.notNil) { self.radius = newRadius };
        },

        // Method to get position as Point
        asPoint: { |self|
            Point(self.x, self.y);
        },

        // Method to check if a point is within this position's radius
        contains: { |self, pointX, pointY|
            var distance = ((pointX - self.x).squared + (pointY - self.y).squared).sqrt;
            distance <= self.radius;
        },

        // String representation
        asString: { |self|
            "Position(x: %, y: %, radius: %)".format(self.x, self.y, self.radius);
        }
    );

    // return position
    position
};

// Prototype of a sampler player class.
// Lazy-loading: upon creation of the instance only the first buffer is loaded,
// others are being loaded when the previous are being played.
~cSamplePlayer = {
    arg name, // <String> name of the player instance
        samples; // <Array> of <String> sample filenames with full path

    // <Event> as an object prototype
    var player = (
        name: name,  // <String> player's name
        samples: samples,  // <Array> of sample filenames
        buffers: nil, // <Array> of loaded buffers
        synthActive: nil, // <Synth> active synth
        currentIndex: nil, // <Integer> index of currently playing sample
        currentlyPlaying: nil, // <String> filename of currently playing sample
        position: nil, // <Event> position of the player on the canvas
        stateMonitor: nil, // <Routine> to monitor synth state

        init: { arg self;
            // Initialize array of buffers
            self.buffers = Array.fill(self.samples.size, nil);

            // Initialization means loading the first sample in `samples`
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

            var synthArgs, bundle;

            if (self.samples.isNil.not and: { self.samples.size > 0 }) {
                self.currentIndex = self.getNextIndex;

                // Within one player, only one sample can be played at a time
                if (self.currentlyPlaying.notNil) { self.terminate };
                self.currentlyPlaying = self.samples[self.currentIndex];

                // Build synth arguments: always include buffer, then add user args
                synthArgs = [\buf, self.buffers[self.currentIndex].bufnum] ++ args;

                // Register synth in NodeWatcher before creating on the server
                bundle = s.makeBundle(false, {
                    self.synthActive = Synth(\bufplay, synthArgs);
                    NodeWatcher.register(self.synthActive, assumePlaying: true)
                });
                s.listSendBundle(nil, bundle);

                // Start monitoring synth state
                self.startMonitoring;

                // Move forward and load the next sample in the background.
                self.load(self.getNextIndex);
            } {
                "No samples available to play.".postln;
            };
        },

        startMonitoring: { |self|
            if (self.stateMonitor.notNil) {
                self.stateMonitor.stop
            };

            if (self.synthActive.notNil) {
                self.stateMonitor = Routine({
                    while { self.synthActive.isPlaying } {
                        0.1.wait;  // Check every 100ms
                    };
                    self.synthActive = nil;
                    self.currentlyPlaying = nil;
                    self.stateMonitor.stop;
                }).play;
            };
        },

        terminate: { |self|
            if (self.synthActive.notNil) {
                self.synthActive.set(\gate, 0, \lag, 0.5);
            };
            
            // Stop the monitoring routine if it's running
            if (self.stateMonitor.notNil) {
                self.stateMonitor.stop;
                self.stateMonitor = nil;
            };
            
            self.synthActive = nil;
            self.currentlyPlaying = nil;
        },

        getNextIndex: { |self|
            if (self.currentIndex.isNil) {
                // Initialize to the first sample (next statement will make it 0)
                self.currentIndex = -1;
            };
            // Wrap around
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
        },

        // Setter for position - allows setting position object or individual
        // coordinates.
        setPosition: { |self, x, y, radius|
            if (self.position.isNil) {
                self.position = ~cPosition.(x, y, radius);
            } {
                self.position.set(x, y, radius);
            }
        },

        // Ensures all resources are properly freed and no zombie processes or
        // memory leaks are left behind.
        cleanup: { |self|
            // First stop playback if active
            if (self.synthActive.notNil) {
                self.terminate;
            };
            
            // Stop monitoring routine if running
            if (self.stateMonitor.notNil) {
                self.stateMonitor.stop;
                self.stateMonitor = nil;
            };
            
            // Free all buffers
            if (self.buffers.notNil) {
                self.buffers.do({ |buf|
                    if (buf.notNil) {
                        ("Freeing buffer: " ++ buf).postln;
                        buf.free;
                    };
                });
                self.buffers = nil;
            };
            
            // Clear all state
            self.currentIndex = nil;
            self.currentlyPlaying = nil;
            self.synthActive = nil;
            self.position = nil;
            
            // Clear samples array
            self.samples = nil;
            
            ("Player '%' cleaned up.".format(self.name)).postln;
        }
    );

    // return player
    player.init;
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

s.waitForBoot({
    var path = PathName(thisProcess.nowExecutingPath).parentPath;

    // List of external files to load in the order they should be loaded.
    // Format: [filename <str>, description <str>, requiresSync <bool>]
    var externals = [
        ["synthdef.scd", "synth definitions", true],
        ["gui.scd", "GUI", false]
    ];

    externals.do({ |elt|
        elt[0] = path +/+ elt[0];
        ~loadExternal.(*elt);
    });
});


// Clean up buffers and MIDI
~cleanup = {
    "Cleaning up".inform;
    ~window.close;

    "> Resetting bus counter...".post;
    s.newBusAllocators;
    postf("OK\n");

    "> Cleaning up players...".postln;
    ~players.do({ |player| player.cleanup });
    postf("OK\n");
};


CmdPeriod.doOnce({
    "Caught signal: <shut down>".warn;
    ~cleanup.();
    postf("OK\n\n");
})
)
