(
// GUI Module - gui.scd
// Full-screen canvas with directory browser for audio files
var win;

// Warning: this should be changed - once the functionality is completed,
//          the window will be used in the fullScreen.
var height = 500;
var width = 500;

~gui = { |window|
    var signalSuccess = false;
    var signalFailure = false;
    var directoryLabel;
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
                };
            } {
                ("Error: Selected path is not a valid directory: " ++ path).postln;
            };
        },
        fileMode: 2, // Directory mode
        acceptMode: 0, // Open mode
        stripResult: true,

        // Warning: fix this!
        //path: PathName(thisProcess.nowExecutingPath).pathOnly
        );
    };

    // Create directory label in upper left corner
    directoryLabel = StaticText(window, Rect(10, 10, 800, 30))
        .string_("No directory selected - Press Ctrl+O to open")
        .stringColor_(Color.white)
        .background_(Color.clear)
        .font_(Font("Arial", 14));

    // Set up canvas draw function
    win.draw {
        var bounds = win.bounds;

        // Draw basic grid or other canvas elements here if needed
        Pen.strokeColor_(Color.gray(0.1));
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

        // Draw circles for each key in ~samples
        if (~samples.notNil and: { ~samples.size > 0 }) {
            var numKeys = ~samples.keys.size;
            var gridSize = 50; // Grid spacing
            var circleRadius = 20;
            var maxCirclesPerRow = ((bounds.width / gridSize).floor - 2).max(1); // Leave margin
            var numRows = (numKeys / maxCirclesPerRow).ceil;
            var actualCirclesPerRow, startX, startY;

            ~samples.keys.do({ |key, index|
                var row = (index / maxCirclesPerRow).floor;
                var col = index % maxCirclesPerRow;
                var x, y, gridX, gridY;
                
                // Calculate how many circles in this row
                actualCirclesPerRow = if (row == (numRows - 1)) {
                    numKeys - (row * maxCirclesPerRow); // Last row might have fewer
                } {
                    maxCirclesPerRow;
                };
                
                // Calculate starting position to center the row
                startX = (bounds.width - ((actualCirclesPerRow - 1) * gridSize)) * 0.5;
                startY = (bounds.height - ((numRows - 1) * gridSize)) * 0.5;
                
                // Calculate position
                x = startX + (col * gridSize);
                y = startY + (row * gridSize);
                
                // Snap to grid intersection
                gridX = (x / gridSize).round * gridSize;
                gridY = (y / gridSize).round * gridSize;
                
                // Draw circle
                Pen.strokeColor_(Color.white);
                Pen.fillColor_(Color.blue(0.3, 0.7));
                Pen.width_(2);
                
                Pen.addOval(Rect(
                    gridX - circleRadius, 
                    gridY - circleRadius, 
                    circleRadius * 2, 
                    circleRadius * 2
                ));
                Pen.fillStroke;
                
                // Draw key label in center of circle
                Pen.stringCenteredIn(
                    key.asString,
                    Rect(
                        gridX - circleRadius,
                        gridY - circleRadius,
                        circleRadius * 2,
                        circleRadius * 2
                    ),
                    Font("Arial", 12),
                    Color.white
                );
            });
        };

        // // If audio files are loaded, you could draw visualizations here
        // if (audioFiles.notNil) {
        //     // Example: draw file count in center
        //     var text = "% audio files loaded".format(audioFiles.size);
        //     Pen.stringAtPoint(text, 
        //         Point(bounds.width * 0.5 - 100, bounds.height * 0.5),
        //         Font("Arial", 24), Color.white);
        // };
    };
    win.play;

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
        currentDirectory: { ~rootDir },
        samples: { ~samples },
        openDirectory: openDirectory
    );
};

// Create the main window
win = RedWindow("Han[ging] Gar[den] Sampler", Rect(0, 0, width, height), resizable: false)
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