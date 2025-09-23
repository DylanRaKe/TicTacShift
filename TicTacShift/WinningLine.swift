import Foundation

struct WinningLine: Equatable {
    enum LineType: Equatable {
        case horizontal
        case vertical
        case diagonal
    }
    
    let type: LineType
    let index: Int
    let positions: [(Int, Int)]
    
    static func == (lhs: WinningLine, rhs: WinningLine) -> Bool {
        guard lhs.type == rhs.type, lhs.index == rhs.index, lhs.positions.count == rhs.positions.count else { return false }
        return zip(lhs.positions, rhs.positions).allSatisfy { $0.0 == $1.0 && $0.1 == $1.1 }
    }
}
