(
// Unit Tests for Sample Player
// Run these tests after loading your ~cSamplePlayer class

// Test setup
~runTests = {    
    // Initialize test tracking
    var testResults = [];
    var totalTests = 0;
    var passedTests = 0;
    var testSamples;
    var player1, playerEmpty, playerSingle;

    // Helper function to run a test
    var assert = { |condition, testName|
        totalTests = totalTests + 1;
        if (condition) {
            testResults = testResults.add("✓ PASS: " ++ testName);
            passedTests = passedTests + 1;
        } {
            testResults = testResults.add("✗ FAIL: " ++ testName);
        };
    };

    // Test sample files (using built-in SuperCollider sounds)
    testSamples = [
        Platform.resourceDir +/+ "sounds/a11wlk01.wav",
        Platform.resourceDir +/+ "sounds/a11wlk01-44_1.aiff"
    ];

    "Starting Sample Player Unit Tests...\n\n".postf;

    // Wait for server to be ready
    s.waitForBoot({
        // TEST 1: Initial State Tests
        "=== TEST GROUP 1: Initial State ===".postln;

        // Create player instance
        player1 = ~cSamplePlayer.(name: \collection1, samples: testSamples);

        // Wait a moment for initialization
        {
            // Test 1.1: currentIndex should be 0 after creation
            assert.(player1.currentIndex == 0, "currentIndex equals 0 after creation");

            // Test 1.2: currentlyPlaying should be nil before .start
            assert.(player1.currentlyPlaying.isNil, "currentlyPlaying is nil before start");

            // Test 1.3: buffers array should be initialized with correct size
            assert.(player1.buffers.size == testSamples.size, "buffers array has correct size");

            // Test 1.4: synths array should be initialized with correct size
            assert.(player1.synths.size == testSamples.size, "synths array has correct size");

            // Test 1.5: player name should be set correctly
            assert.(player1.name == \collection1, "player name is set correctly");

            // Test 1.6: samples array should be set correctly
            assert.(player1.samples == testSamples, "samples array is set correctly");

            // Wait for first buffer to load, then test
            {
                // Test 1.7: only first buffer should be loaded initially
                assert.(player1.isBufferLoaded(0), "first buffer is loaded after initialization");

                // Test 1.8: second buffer should not be loaded initially
                assert.(player1.isBufferLoaded(1).not, "second buffer is not loaded initially");

                // TEST 2: getNextIndex method tests
                "\n=== TEST GROUP 2: getNextIndex Method ===\n".postf;

                // Test 2.1: getNextIndex from first position
                assert.(player1.getNextIndex == 1, "getNextIndex returns 1 when currentIndex is 0");

                // Test 2.2: getNextIndex wraps around
                player1.currentIndex = 1;
                assert.(player1.getNextIndex == 0, "getNextIndex wraps around from last to first");
                player1.currentIndex = 0; // Reset for other tests

                // TEST 3: start method tests
                "\n=== TEST GROUP 3: start Method ===\n".postf;

                // Test 3.1: start sets currentlyPlaying
                //       NB: silent start
                player1.start(\amp, 0);
                {
                    var previousIndex;

                    assert.(player1.currentlyPlaying.notNil, "currentlyPlaying is set after start");

                    // Test 3.2: start creates synth
                    assert.(player1.synths[player1.currentIndex].notNil, "synth is created after start");

                    // Test 3.3: synth registered correctly
                    assert.(player1.synths[player1.currentIndex].class.asString == "Synth", "synth is registered correctly");

                    // Test 3.4: currentlyPlaying contains correct sample path
                    assert.(player1.currentlyPlaying == testSamples[player1.currentIndex], "currentlyPlaying contains correct sample path");

                    // TEST 4: Advancing to next sample
                    "\n=== TEST GROUP 4: Sample Advancement ===\n".postf;

                    // Store current index for comparison
                    previousIndex = player1.currentIndex;

                    // Start next sample (silently)
                    player1.start(\amp, 0);

                    {
                        // Test 4.1: currentIndex advances
                        assert.(player1.currentIndex == ((previousIndex + 1) % testSamples.size), "currentIndex advances correctly");

                        // Test 4.2: currentlyPlaying updates
                        assert.(player1.currentlyPlaying == testSamples[player1.currentIndex], "currentlyPlaying updates to new sample");

                        // Test 4.3: next buffer gets loaded
                        {
                            assert.(player1.isBufferLoaded(player1.getNextIndex), "next buffer is loaded in background");

                            // TEST 5: kill method tests
                            "\n=== TEST GROUP 5: kill Method ===\n".postf;

                            // Test 5.1: kill stops playback
                            player1.kill;
                            assert.(player1.currentlyPlaying.isNil, "kill sets currentlyPlaying to nil");

                            // TEST 6: Edge cases
                            "\n=== TEST GROUP 6: Edge Cases ===\n".postf;

                            // Test 6.1: Empty samples array
                            playerEmpty = ~cSamplePlayer.(name: \empty, samples: []);
                            assert.(playerEmpty.samples.size == 0, "handles empty samples array");

                            // Test 6.2: Single sample
                            playerSingle = ~cSamplePlayer.(name: \single, samples: [testSamples[0]]);
                            assert.(playerSingle.samples.size == 1, "handles single sample");
                            assert.(playerSingle.getNextIndex == 0, "single sample wraps to itself");

                            // Print results
                            "\n=== TEST RESULTS ===\n".postf;
                            testResults.do({ |result| result.postln; });

                            postf("Tests passed: %/%\n\n", passedTests, totalTests);
                            if (passedTests == totalTests) {
                                "✓✓✓ ALL TESTS PASSED!".inform;
                            } {
                                "✗✗✗ Some tests failed. Check implementation.".warn;
                            };
                        }.defer(1.0); // Wait for next buffer to load
                    }.defer(0.5); // Wait for synth creation
                }.defer(0.5); // Wait for start to complete
            }.defer(0.5); // Wait for start to complete
        }.defer(2.0); // Wait for initial buffer to load
    });
};

// Convenience function to run just the basic initial state tests
~runBasicTests = {
    var testSamples = [
        Platform.resourceDir +/+ "sounds/a11wlk01.wav",
        Platform.resourceDir +/+ "sounds/a11wlk01-44_1.aiff"
    ];

    "Running basic initial state tests...".postln;
    s.waitForBoot({
        var player1 = ~cSamplePlayer.(name: \collection1, samples: testSamples);

        {
            "Testing initial state:".postln;
            ("• currentIndex == 0: " ++ (player1.currentIndex == 0)).postln;
            ("• currentlyPlaying is nil: " ++ player1.currentlyPlaying.isNil).postln;
            ("• buffers array size: " ++ player1.buffers.size).postln;
            ("• samples array size: " ++ player1.samples.size).postln;

            {
                ("• first buffer loaded: " ++ player1.isBufferLoaded(0)).postln;
                ("• second buffer loaded: " ++ player1.isBufferLoaded(1)).postln;
                "Basic tests completed.".postln;
            }.defer(1.0);
        }.defer(2.0);
    });
};
)

~runBasicTests.();
~runTests.();
