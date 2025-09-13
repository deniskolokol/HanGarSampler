// GUI Module - gui.scd

(
// GUI
//
// Warning: this should be changed - once the functionality is completed,
//          the window will be used in the fullScreen.
var noDirSelected = "No directory selected - Press Ctrl+O to open";
var transparent = Color.grey(alpha:0.0);
var gridSize = 200; // Grid spacing
var intersections; // Grid centers (coords of the points of attraction)
var height = Window.screenBounds.height;
var width = Window.screenBounds.width;
var gui; // Event containing GUI elements

var toggleFullscreen = { |window|
    if (window.bounds == Window.screenBounds) {
        window.endFullScreen
    } {
        window.fullScreen
    }
};

// Open directory dialog
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

                // Log success
                postf("Successfully loaded audio files from: %\n", ~rootDir);

                // Clean-up existing players, if any
                ~players.do({ |player| player.cleanup });

                // Create new players and fill them with samples
                ~samples.keysValuesDo({ |key, value|
                    ~players[key] = ~cSamplePlayer.(name: key.asString, samples: value);
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


// Function to get grid intersection points
var getGridIntersections = { |width, height, gridSize|
    var intersections = List.new;
    var numX = (width / gridSize).floor + 1;
    var numY = (height / gridSize).floor + 1;
    var proximity = gridSize / 3;
    
    numY.do({ |row|
        numX.do({ |col|
            var x = col * gridSize;
            var y = row * gridSize;
            
            // Only add if not too close to borders
            if ((x >= proximity) and: { x <= (width - proximity) } and: 
                { y >= proximity } and: { y <= (height - proximity) }) {
                intersections.add([x, y]);
            };
        });
    });
    
    intersections;
};

var distributeEvenly = { |numItems|
    var maxCirclesPerRow = ((width / gridSize).floor - 2).max(1); // Leave margin
    var numRows = (numItems / maxCirclesPerRow).ceil;
    var actualCirclesPerRow, startX, startY;
    var result = List.new;

    numItems.do({ |index|
        var row = (index / maxCirclesPerRow).floor;
        var col = index % maxCirclesPerRow;
        var x, y, gridX, gridY;
        
        // Calculate how many circles in this row
        actualCirclesPerRow = if (row == (numRows - 1)) {
            numItems - (row * maxCirclesPerRow); // Last row might have fewer
        } {
            maxCirclesPerRow;
        };
        
        // Calculate starting position to center the row
        startX = (width - ((actualCirclesPerRow - 1) * gridSize)) * 0.5;
        startY = (height - ((numRows - 1) * gridSize)) * 0.5;
        
        // Calculate position
        x = startX + (col * gridSize);
        y = startY + (row * gridSize);
        
        // Snap to grid intersection
        gridX = (x / gridSize).round * gridSize;
        gridY = (y / gridSize).round * gridSize;

        result.add([gridX, gridY]);
    });

    // return List of coordinates
    result
};


var makeGUI = { |window|
    var signalSuccess = false;
    var signalFailure = false;
    var audioFiles = nil;

    var canvas = UserView(window, window.bounds)
        .background_(Color.black);

    // Create directory label in upper left corner
    var directoryLabel = StaticText(canvas, Rect(10, 10, 800, 30))
        .string_(noDirSelected)
        .stringColor_(Color.white)
        .background_(Color.clear)
        .font_(Font("Arial", 14));

    // Set up canvas draw function
    canvas.drawFunc = { |view|
        var bounds = ~window.bounds;
        var circleRadius = 20;

        // Update directory label
        directoryLabel.string_(
            if (~rootDir.notNil and: { ~rootDir.trim != "" }) { ~rootDir } { noDirSelected }
            );

        // Draw basic grid or other canvas elements here if needed
        Pen.strokeColor_(Color.gray(0.1));
        Pen.width_(1);

        // Draw a subtle grid
        (0, gridSize .. bounds.width.asInteger).do({ |x|
            Pen.moveTo(Point(x, 0));
            Pen.lineTo(Point(x, bounds.height));
        });

        (0, gridSize .. bounds.height.asInteger).do({ |y|
            Pen.moveTo(Point(0, y));
            Pen.lineTo(Point(bounds.width, y));
        });

        Pen.stroke;

        if (~players.notNil and: { ~players.size > 0 }) {
            var numKeys = ~players.keys.size;
            var maxCirclesPerRow = ((bounds.width / gridSize).floor - 2).max(1); // Leave margin
            var numRows = (numKeys / maxCirclesPerRow).ceil;
            var coords;

            // Check if players aren't placed yet, and calculate default spacing:
            if (~players.any { |player| player.position.isNil }) {
                coords = distributeEvenly.(~players.keys.size);
            };

            ~players.keysValuesDo({ |key, player, i|
                if (player.position.isNil) {
                    player.setPosition(coords[i][0], coords[i][1], circleRadius);
                };

                // Draw circle
                Pen.strokeColor_(Color.white);
                Pen.fillColor_(Color.blue(0.3, 0.7));
                Pen.width_(2);

                Pen.addOval(Rect(
                    player.position.x - player.position.radius, 
                    player.position.y - player.position.radius, 
                    player.position.radius * 2, 
                    player.position.radius * 2
                ));
                Pen.fillStroke;

                // Draw key label in center of circle
                Pen.stringCenteredIn(
                    key.asString,
                    Rect(
                        player.position.x - player.position.radius,
                        player.position.y - player.position.radius,
                        player.position.radius * 2,
                        player.position.radius * 2
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

    // React to mouse
    canvas.mouseDownAction = { |view, x, y, modifiers, buttonNumber, clickCount|
        var players;

        // First figure out the player(s) under the mouse
        players = ~players.select({ |player|
            (player.position.notNil and: { player.position.contains(x, y) })
        });

        postf("modifiers %, button %, clickCount: %\n", modifiers, buttonNumber, clickCount);

        case
        // no modifiers left button double click
        { [0, 256].includes(modifiers) && (buttonNumber == 0) && (clickCount == 2) } {
            players.keysValuesDo({ |key, player|
                "Caught double-click on player '%' at (%, %)".format(key, x, y).postln;
                // Double-clicked within this player's radius
                if (player.synthActive.notNil) {
                    // Currently playing - kill it
                    player.terminate;
                    ("Player '%' stopped".format(player.name)).postln;
                } {
                    // Not playing - start it
                    player.start;
                    ("Player '%' started".format(player.name)).postln;
                };
            });
        }
        // no modifiers left button single click
        { [0, 256].includes(modifiers) && (buttonNumber == 0) && (clickCount == 1) } {
            // TODO: move player around
            nil
        };
    };
    canvas.mouseMoveAction = canvas.mouseDownAction;

    // Animate!
    canvas.animate = true;


    // Set up key handlers
    window.view.keyDownAction_({ |view, char, modifiers, unicode, keycode|
        case
        // Cmd+O: open directory
        { (modifiers.bitAnd(1048576) != 0) && (char == $o) } { openDirectory.() }
        // Ctrl+F: toggle fullscreen
        { (modifiers.bitAnd(1048576) != 0) && (char == $f) } { toggleFullscreen.(~window) }
        // ESC: exit fullscreen
        { (modifiers == 0) && (keycode == 53) } {  ~window.endFullScreen }
        // ...all the rest
        { [view, char, modifiers, unicode, keycode].postln }
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
        openDirectory: openDirectory
    );
};

// Get the intersections to create static particles - centers of attraction
intersections = getGridIntersections.(width, height, gridSize);

// Create the main window
~window = Window("Han[ging] Gar[den] Sampler", Rect(0, 0, width, height), resizable: false)
    .background_(Color.black)
    .front;
gui = makeGUI.(~window);

{ // Global app clock
    var tick;
    while {~window.isClosed.not} {
        tick = Main.elapsedTime + (1/60);
        gui.canvas.refresh;

        (tick - Main.elapsedTime).max(0.001).wait;
    }
}.fork(AppClock);
)