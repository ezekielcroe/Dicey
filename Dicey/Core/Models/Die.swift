//
//  Die.swift
//  Dicey
//

import Foundation

struct Die: Identifiable, Equatable {
    let id: UUID
    let sides: Int
    var value: Int? = nil
    var isDropped: Bool = false

    init(sides: Int, id: UUID = UUID(), value: Int? = nil, isDropped: Bool = false) {
        self.sides = sides
        self.id = id
        self.value = value
        self.isDropped = isDropped
    }

    /// Creates a clean copy for simulation (no rolled value, not dropped)
    func blank() -> Die {
        Die(sides: sides)
    }

    /// Whether this die exploded (rolled value exceeds its maximum face)
    var hasExploded: Bool {
        guard let value = value else { return false }
        return value > sides
    }

    static func == (lhs: Die, rhs: Die) -> Bool {
        lhs.id == rhs.id && lhs.sides == rhs.sides && lhs.value == rhs.value && lhs.isDropped == rhs.isDropped
    }
}
