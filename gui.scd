(
// GUI Module - gui.scd
// Full-screen canvas with directory browser for audio files
var win;

~gui = { |window|
    var signalSuccess = false;
    var signalFailure = false;
    var canvas, directoryLabel;
    var audioFiles = nil;

    // Function to open directory dialog
    var openDirectory = {
        FileDialog({ |path|
            var tempEvent;

            if (File.exists(path) and: { File.type(path) == \directory }) {
                tempEvent = ~getSamples.(path);
                if (tempEvent.isEmpty) {
                    // No audio files found - show error
                    ("Error: No audio files (*.wav, *.aif, *.aiff) found in directory: " ++ path).error;

                    // You could also show a visual error message on the canvas
                    {
                        signalFailure = true;
                        // Reset background after 2 seconds
                        { 
                            signalFailure = signalSuccess = false;
                        }.defer(2.0);
                    }.defer(0.1);

                } {
                    // Success - update current directory and audio files
                    ~rootDir = path;
                    ~samples = tempEvent;

                    // Update directory label
                    directoryLabel.string_(~rootDir);

                    // Log success
                    postf("Successfully loaded audio files from: %\n", ~rootDir);
                    ~samples.keysValuesDo({ |key, value|
                        "\n%:".format(key).postln;
                        value.do({ |file|
                            "\t%".format(file).postln;
                        });
                        ~players[key] = ~samplePlayer.(name: key.asString, samples: value);
                    });

                    // Visual feedback - brief green flash
                    {
                        signalSuccess = true;
                        // Reset background after 1 second
                        { 
                            signalSuccess = signalFailure = false;
                        }.defer(1.0);
                    }.defer(0.1);
                };
            } {
                ("Error: Selected path is not a valid directory: " ++ path).postln;
            };
        },
        fileMode: 2, // Directory mode
        acceptMode: 0, // Open mode
        stripResult: true,
        //path: PathName(thisProcess.nowExecutingPath).pathOnly
        );
    };

    // Create the main canvas view that takes the whole window
    canvas = UserView(window, window.bounds)
        .background_(Color.black)
        .clearOnRefresh_(true);

    // Create directory label in upper left corner
    directoryLabel = StaticText(window, Rect(10, 10, 800, 30))
        .string_("No directory selected - Press Ctrl+O to open")
        .stringColor_(Color.white)
        .background_(Color.clear)
        .font_(Font("Arial", 14));

    // Set up canvas draw function
    canvas.drawFunc_({
        var bounds = canvas.bounds;

        // Draw basic grid or other canvas elements here if needed
        Pen.strokeColor_(Color.gray(0.2));
        Pen.width_(1);

        // Draw a subtle grid
        (0, 50 .. bounds.width.asInteger).do({ |x|
            Pen.moveTo(Point(x, 0));
            Pen.lineTo(Point(x, bounds.height));
        });

        (0, 50 .. bounds.height.asInteger).do({ |y|
            Pen.moveTo(Point(0, y));
            Pen.lineTo(Point(bounds.width, y));
        });

        Pen.stroke;

        // If audio files are loaded, you could draw visualizations here
        if (audioFiles.notNil) {
            // Example: draw file count in center
            var text = "% audio files loaded".format(audioFiles.size);
            Pen.stringAtPoint(text, 
                Point(bounds.width * 0.5 - 100, bounds.height * 0.5),
                Font("Arial", 24), Color.white);
        };

        // Warning: this doesn't work!
        if (signalSuccess) {
            canvas.background_(Color.green(0.3, 0.1))
        } {
            if (signalFailure) {
                canvas.background_(Color.red(0.3, 0.1));
            } {
                // ordinary...
                canvas.background_(Color.black)
            }
        }
    });
    canvas.refresh;

    // Set up key handlers
    window.view.keyDownAction_({ |view, char, modifiers, unicode, keycode|
        // Check for Cmd+O
        if ((modifiers.bitAnd(1048576) != 0) && (char == $o)) {
            openDirectory.();
        };
    });

    // Make sure window can receive key events
    window.view.canFocus_(true);
    window.view.focus;

    // Set up window close action
    window.onClose_({
        "GUI window closed.".postln;
    });

    // Return an interface object
    (
        window: window,
        canvas: canvas,
        currentDirectory: { ~rootDir },
        samples: { ~samples },
        openDirectory: openDirectory,

        // Method to refresh display
        refresh: {
            canvas.refresh;
        }
    );
};

// Create the main window
win = Window("Audio File Browser", Rect(0, 0, Window.screenBounds.width, Window.screenBounds.height))
    .background_(Color.black);
~guiInstance = ~gui.(win);

// Show the window
win.front;

CmdPeriod.doOnce({
    "Caught signal: <shut down>".warn;
    win.close;
    postf("OK\n\n");
});
)