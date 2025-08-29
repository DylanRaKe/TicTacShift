import SwiftUI

struct VersusView: View {
    @StateObject private var viewModel = VersusViewModel()
    @State private var selectedTab: Tab = .create
    
    enum Tab {
        case create, join
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                switch viewModel.state {
                case .idle:
                    idleView
                case .creating(let code):
                    waitingView(title: "Room Created", subtitle: "Code: \(code)", message: "Waiting for opponent...")
                case .joining(let code):
                    waitingView(title: "Joining Room", subtitle: "Code: \(code)", message: "Connecting...")
                case .searching:
                    waitingView(title: "Searching", subtitle: "", message: "Finding match...")
                case .matched:
                    waitingView(title: "Matched!", subtitle: "", message: "Starting game...")
                case .inGame:
                    gameView
                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationTitle("Versus")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var idleView: some View {
        VStack(spacing: 32) {
            headerView
            tabSelector
            tabContent
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Online Match")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Play against players worldwide")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            Button {
                selectedTab = .create
            } label: {
                Text("Create")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedTab == .create ? .white : .blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == .create ? .blue : Color.clear)
                    )
            }
            
            Button {
                selectedTab = .join
            } label: {
                Text("Join")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedTab == .join ? .white : .blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == .join ? .blue : Color.clear)
                    )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
        )
        .animation(.spring(response: 0.3), value: selectedTab)
    }
    
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .create:
                createRoomView
            case .join:
                joinRoomView
            }
        }
        .frame(minHeight: 200)
    }
    
    private var createRoomView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Create Room")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Generate a code and share it with your friend")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.createRoom()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Room")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue)
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var joinRoomView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "number.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Join Room")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Enter the room code to join a game")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                TextField("Enter room code", text: $viewModel.inputCode)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .textCase(.uppercase)
                    .autocorrectionDisabled()
                
                Button {
                    viewModel.joinWithCode()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                        Text("Join Room")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.green)
                    )
                }
                .disabled(viewModel.inputCode.isEmpty)
                .opacity(viewModel.inputCode.isEmpty ? 0.6 : 1.0)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func waitingView(title: String, subtitle: String, message: String) -> some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            Button("Cancel") {
                viewModel.cancel()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(24)
    }
    
    private var gameView: some View {
        Group {
            if let game = viewModel.game {
                OnlineGameBoardView(game: game, viewModel: viewModel)
            } else {
                Text("Loading game...")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Connection Error")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Try Again") {
                viewModel.state = .idle
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }
}

struct OnlineGameBoardView: View {
    @Bindable var game: TicTacShiftGame
    @ObservedObject var viewModel: VersusViewModel
    @State private var animatingSquares: Set<String> = []
    @State private var victoryManager = VictoryAnimationManager()
    
    private var isPlayerTurn: Bool {
        let localPlayer: Player = viewModel.isLocalPlayerX ? .x : .o
        return game.currentPlayer == localPlayer
    }
    
    var body: some View {
        VStack(spacing: 24) {
            gameStatusHeader
            gameBoard
            gameControls
        }
        .padding()
        .onAppear {
            viewModel.onGameUpdate = {
                // Force UI update
            }
        }
    }
    
    private var gameStatusHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                
                Text("Online Match")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("Turn \(game.moveCounter + 1)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                PlayerIndicator(
                    player: .x,
                    isActive: game.currentPlayer == .x,
                    gameMode: .normal,
                    isLocalPlayer: viewModel.isLocalPlayerX
                )
                
                Text("VS")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                
                PlayerIndicator(
                    player: .o,
                    isActive: game.currentPlayer == .o,
                    gameMode: .normal,
                    isLocalPlayer: !viewModel.isLocalPlayerX
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var gameBoard: some View {
        VStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { column in
                        let squareKey = "\(row)-\(column)"
                        EnhancedGameSquareView(
                            player: game.boardState[row][column],
                            isEnabled: game.canPlaceMove(at: row, column: column) && isPlayerTurn,
                            isAnimating: animatingSquares.contains(squareKey),
                            willFadeNext: game.willPositionFadeNext(row: row, column: column),
                            gameMode: .normal
                        ) {
                            makePlayerMove(row: row, column: column)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var gameControls: some View {
        HStack(spacing: 16) {
            if game.gameResult != .ongoing {
                Button("Rematch") {
                    viewModel.rematch()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Button("Quit") {
                viewModel.quit()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
    
    private func makePlayerMove(row: Int, column: Int) {
        let squareKey = "\(row)-\(column)"
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            animatingSquares.insert(squareKey)
            viewModel.makeMove(at: row, column: column)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            animatingSquares.remove(squareKey)
        }
    }
}

extension PlayerIndicator {
    init(player: Player, isActive: Bool, gameMode: GameMode, isLocalPlayer: Bool) {
        self.init(player: player, isActive: isActive, gameMode: gameMode)
    }
}

#Preview {
    VersusView()
}