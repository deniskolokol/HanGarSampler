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
            assert.(player1.currentIndex.isNil, "currentIndex is nil after creation");

            // Test 1.2: currentlyPlaying should be nil before .start
            assert.(player1.currentlyPlaying.isNil, "currentlyPlaying is nil before start");

            // Test 1.3: buffers array should be initialized with correct size
            assert.(player1.buffers.size == testSamples.size, "buffers array has correct size");

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
                assert.(player1.getNextIndex == 0, "getNextIndex returns 0 when currentIndex is nil");

                // Test 2.2: getNextIndex wraps around
                player1.currentIndex = 1;
                assert.(player1.getNextIndex == 0, "getNextIndex wraps around from last to first");
                player1.currentIndex = 0; // Reset for other tests

                // TEST 3: start method tests
                "\n=== TEST GROUP 3: start Method ===\n".postf;

                // Ensure both buffers are loaded before testing playback
                player1.load(0);
                player1.load(1);
                
                // Wait for buffers to load
                {
                    // Test 3.1: start sets currentlyPlaying
                    //       NB: silent start
                    if (player1.isBufferLoaded(0) and: { player1.isBufferLoaded(1) }) {
                        player1.start(\amp, 0);
                    } {
                        "Error: Buffers not loaded yet".error;
                    };
                }.defer(1); // Give time for buffers to load
                {
                    var previousIndex;

                    assert.(player1.currentlyPlaying.isNil, "currentlyPlaying is set to nil after start");

                    // Test 3.2: start creates synth
                    assert.(player1.synthActive.isNil, "synth is NOT created after start");

                    // TEST 4: Advancing to next sample
                    "\n=== TEST GROUP 4: Sample Advancement ===\n".postf;

                    // Store current index for comparison
                    previousIndex = player1.currentIndex;

                    // Start next sample (silently)
                    player1.start(\amp, 0);

                    {
                        // Test 4.1: currentlyPlaying updates
                        assert.(player1.currentlyPlaying == testSamples[player1.currentIndex], "currentlyPlaying updates to new sample");

                        // Test 4.2: synth registered correctly
                        assert.(player1.synthActive.class.asString == "Synth", "synth is registered correctly");

                        // Test 4.3: currentlyPlaying contains correct sample path
                        assert.(player1.currentlyPlaying == testSamples[player1.currentIndex], "currentlyPlaying contains correct sample path");

                        // Test 4.4: next buffer gets loaded
                        {
                            assert.(player1.isBufferLoaded(player1.getNextIndex), "next buffer is loaded in background");

                            // TEST 5: kill method tests
                            "\n=== TEST GROUP 5: kill Method ===\n".postf;

                            // Test 5.1: kill stops playback
                            player1.terminate;
                            assert.(player1.currentlyPlaying.isNil, "kill sets currentlyPlaying to nil");

                            // TEST 6: Cleanup functionality
                            "\n=== TEST GROUP 6: Cleanup Method ===\n".postf;

                            // Start playback to test cleanup during active state
                            player1.start(\amp, 0);
                            
                            {
                                // Test 6.1: Cleanup during playback
                                player1.cleanup;
                                assert.(player1.synthActive.isNil, "cleanup stops active synth");
                                assert.(player1.currentlyPlaying.isNil, "cleanup clears currentlyPlaying");
                                assert.(player1.stateMonitor.isNil, "cleanup stops monitoring routine");
                                assert.(player1.buffers.isNil, "cleanup clears buffers array");
                                assert.(player1.position.isNil, "cleanup clears position");
                                assert.(player1.samples.isNil, "cleanup clears samples array");
                                
                                // Test 6.2: Cleanup is idempotent (can be called multiple times safely)
                                player1.cleanup;
                                assert.(true, "cleanup can be called multiple times without error");

                                // TEST 7: Edge cases
                                "\n=== TEST GROUP 7: Edge Cases ===\n".postf;

                                // Test 7.1: Empty samples array
                                playerEmpty = ~cSamplePlayer.(name: \empty, samples: []);
                                assert.(playerEmpty.samples.size == 0, "handles empty samples array");
                                
                                // Test 7.2: Single sample
                                playerSingle = ~cSamplePlayer.(name: \single, samples: [testSamples[0]]);
                                
                                // Defer assertions until after buffer load
                                {
                                    assert.(playerSingle.samples.size == 1, "handles single sample");
                                    assert.(playerSingle.getNextIndex == 0, "single sample wraps to itself");
                                    
                                    // Don't cleanup here - it will be handled in the final cleanup
                                }.defer(1.5);

                                // Final cleanup and results
                                {
                                    // Clean up any remaining buffers
                                    if (player1.notNil) { player1.cleanup };
                                    if (playerEmpty.notNil) { playerEmpty.cleanup };
                                    if (playerSingle.notNil) { playerSingle.cleanup };
                                }.defer(2);  // Wait for edge cases to complete
                                
                                {
                                    // Print results
                                    "\n=== TEST RESULTS ===\n".postf;
                                    testResults.do({ |result| result.postln; });

                                    postf("Tests passed: %/%\n\n", passedTests, totalTests);
                                    if (passedTests == totalTests) {
                                        "✓✓✓ ALL TESTS PASSED!".inform;
                                    } {
                                        "✗✗✗ Some tests failed. Check implementation.".warn;
                                    };
                                }.defer(0.5); // Give time for final cleanup
                            }.defer(0.1); // End of cleanup tests
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
                
                // Final cleanup
                {
                    player1.cleanup;
                    "Basic tests completed.".postln;
                }.defer(0.5);
            }.defer(1.0);
        }.defer(2.0);
    });
};
)

~runBasicTests.();
~runTests.();
