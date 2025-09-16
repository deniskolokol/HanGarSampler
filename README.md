# HanGar Sampler

(HanGar = Hanging + Garden)

A SuperCollider-based interactive sampler that allows you to arrange and control audio samples in a grid-like interface. Sample players are represented as circles that can be positioned freely or snapped to grid intersections, creating a "hanging garden" of sound.

## Features

- Visual grid-based interface for sample arrangement
- Drag-and-drop sample player positioning with grid snapping
- Double-click to play/stop samples
- Support for multiple audio file formats (WAV, AIFF, AIF)
- Automatic sample loading and management
- Fullscreen mode support

## Getting Started

### Prerequisites

- SuperCollider (3.x or later)
- Audio files in WAV, AIFF, or AIF format

### Running the Sampler

1. Open `main.scd` in SuperCollider
2. Execute the entire file (`Cmd+Return` or `Ctrl+Return`)
3. The graphical interface will appear with a grid layout

### Loading Samples

1. Press `Cmd+O` (or `Ctrl+O`) to open the directory selection dialog
2. Navigate to a folder containing your audio samples
3. Click "Open" to load all audio files from the selected directory
4. Sample players will appear as circles in the grid

### Controls

- **Drag:** Click and drag circles to move sample players freely
- **Grid Snapping:** Hold `Option` (`Alt`) key while dragging to snap players to grid intersections
- **Play/Stop:** Double-click a circle to play or stop its sample
- **Fullscreen:** Press `Cmd+F` (or `Ctrl+F`) to toggle fullscreen mode
- **Exit Fullscreen:** Press `ESC`

## Testing

The project includes a comprehensive test suite in `tests.scd`. First, execute the main section of the file to load functions for testing (press `Cmd+O` or `Ctrl+O`). You can run tests in two ways:

### Basic Tests
To run just the basic initial state tests:
```supercollider
~runBasicTests.();
```
This will verify the fundamental functionality of the sample player.

### Full Test Suite
To run the complete test suite:
```supercollider
~runTests.();
```
This runs all tests including:
- Initial state tests
- Index management
- Sample playback
- Buffer loading
- Cleanup functionality
- Edge cases

The test results will be displayed in the SuperCollider post window, showing passed/failed status for each test case.

If you encounter any issues, check the SuperCollider post window for detailed error messages.

## TODO

Future features and improvements planned for _HanGar Sampler_:

### Sound Processing
- Granular synthesis capabilities for sample manipulation
- Spatial sound support for immersive audio experiences
- Support for additional audio formats:
  - MP3
  - OGG
  - FLAC
  - AAC

### Interaction & Control
- Gesture recognition for intuitive sample player control
  - Motion tracking
  - Pattern recognition
  - Custom gesture mapping

### Visual Interface
- Advanced visualization features:
  - Waveform display
  - Spectrum analysis
  - Real-time visual feedback
  - Interactive animations