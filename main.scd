(
// Initialize empty Event for samples (maintains order of keys)
~samples = Event.new;

// Function to walk through samples directory and build the Event
~buildSamplesDict = {
    var samplesPath = thisProcess.nowExecutingPath.dirname +/+ "samples";
    var orderedFolders;
    
    // Get folders and sort them to ensure consistent order
    orderedFolders = PathName(samplesPath).folders.sort({ |a, b| 
        a.folderName < b.folderName 
    });
    
    orderedFolders.do({ |folder|
        var audioFiles;
        
        // Get all .wav, .aif, and .aiff files in this folder
        audioFiles = folder.entries.select({ |file|
            var extension = file.extension.toLower;
            (extension == "wav") || (extension == "aif") || (extension == "aiff")
        }).collect({ |file|
            file.fileName  // store just the filename
        });
        
        // Add to Event if we found any audio files
        if(audioFiles.size > 0) {
            ~samples.put(folder.folderName.asSymbol, audioFiles);
        };
    });
};

// Build the dictionary
~buildSamplesDict.value;

// Print the results for verification
"Dictionary contents:".postln;
~samples.keysValuesDo({ |key, value|
    "\n%:".format(key).postln;
    value.do({ |file| 
        "\t%".format(file).postln;
    });
});
)
