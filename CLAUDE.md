# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TicTacShift is a modern iOS tic-tac-toe game with a unique twist - pieces disappear after 3 complete turns, preventing draws and keeping games dynamic. Built with SwiftUI and Swift 5.9+, featuring multiple game modes including local play, AI bot, and online multiplayer via Game Center.

## Build and Development Commands

### Xcode Project
```bash
# Open project in Xcode
open TicTacShift.xcodeproj

# Build from command line
xcodebuild -project TicTacShift.xcodeproj -scheme TicTacShift build

# Run tests (if added)
xcodebuild test -project TicTacShift.xcodeproj -scheme TicTacShift -destination 'platform=iOS Simulator,name=iPhone 15'
```

### iOS Simulator
- Target: iOS 17.0+
- Test devices: iPhone, iPad
- Requires Xcode 15.0+

## Architecture

### Core Game Logic
- **TicTacShiftGame (@Model)**: SwiftData model managing game state, moves, and the core "shift" mechanic where pieces disappear after 6 moves (3 complete turns)
- **GameMove (@Model)**: Individual move tracking with timestamps and player data
- **Player enum**: X/O player representation
- **GameMode enum**: Normal (local), Bot (AI), Versus (online) modes

### UI Architecture (SwiftUI)
- **ContentView**: Main menu with modern gradient design and game mode selection
- **GameBoardView**: Core game interface with enhanced animations and move validation
- **VersusView**: Online multiplayer lobby with create/join room functionality
- **OnlineGameBoardView**: Specialized board for networked games

### Game Features
1. **Random Starting Player**: Each game randomly selects X or O to start first
2. **Player Reveal Animation**: Animated intro screen showing which player starts with cross/circle animations
3. **Shift Mechanic**: Pieces automatically disappear after 6 total moves, preventing infinite games
4. **AI Bot**: Strategic AI with win/block/center/corner priority system
5. **Online Multiplayer**: Game Center integration for matchmaking and real-time play
6. **Victory Animations**: High-performance Canvas-based confetti with accessibility support

### Key Services
- **SoundManager**: Audio feedback system
- **VictoryAnimationManager**: Confetti and celebration effects using Canvas for performance
- **MatchmakingService**: Game Center integration for online play
- **OnlineMatchSession**: Real-time game session management

## Game Center Integration

The app uses Game Center for online multiplayer:
- Entitlements: `com.apple.developer.game-center` enabled
- Authentication handled in `GameCenterAuth.swift`
- Real-time matchmaking via `MatchmakingService`
- Session management through `OnlineMatchSession`

## Development Notes

### SwiftUI Patterns Used
- **@Model** and **@Bindable** for SwiftData integration
- **@Observable** for view model patterns (VictoryAnimationManager)
- **Canvas** API for high-performance confetti animations
- Modern navigation with **NavigationStack**
- Accessibility support with **reduceMotion** environment values

### Performance Optimizations
- Canvas-based animations instead of view-based for confetti
- 60fps animation timers with proper cleanup
- Reduced motion accessibility compliance
- Efficient game state calculations with visible moves filtering

### Code Style
- French UI text (user-facing)
- English code and comments
- SwiftUI declarative patterns
- Comprehensive animation systems with spring physics
- Modern iOS design language with gradients and shadows

### Testing Approach
- No tests currently implemented
- Recommended: XCTest for game logic validation
- UI tests for core gameplay flows
- Game Center integration testing on device

## File Structure

```
TicTacShift/
├── TicTacShiftApp.swift          # App entry point with SwiftData setup
├── ContentView.swift             # Main menu with game mode selection
├── GameModels.swift              # Core game data models (@Model classes)
├── GameFlowView.swift            # Game flow orchestrator with player reveal
├── PlayerRevealView.swift        # Animated player selection screen
├── GameBoardView.swift           # Main game interface
├── VersusView.swift              # Online multiplayer UI
├── OnlineGameFlowView.swift      # Online game flow with reveal screen
├── VictoryAnimation.swift        # Confetti and celebration effects
├── SoundManager.swift            # Audio system
├── GameCenterAuth.swift          # Game Center authentication
├── MatchmakingService.swift      # Online matchmaking logic
├── OnlineMatchSession.swift      # Real-time game sessions
├── VersusViewModel.swift         # Online game state management
└── TicTacShift.entitlements      # Game Center capabilities
```

## Privacy and Compliance

- Privacy policy in `CONFIDENTIALITE.md` (French)
- No personal data collection beyond Game Center services
- GDPR compliant design
- Uses only Apple's secure networking and Game Center APIs