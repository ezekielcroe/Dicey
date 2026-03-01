//
//  Shapes.swift
//  Dicey
//
//  Created by Zhi Zheng Yeo on 22/2/26.
//

import SwiftUI

// MARK: - Custom Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct RegularPolygon: Shape {
    var sides: Int
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.0
        let angle = (Double.pi * 2.0) / Double(sides)
        
        for i in 0..<sides {
            let currentAngle = angle * Double(i) - Double.pi / 2.0
            let point = CGPoint(
                x: center.x + radius * Foundation.cos(currentAngle),
                y: center.y + radius * Foundation.sin(currentAngle)
            )
            if i == 0 { path.move(to: point) }
            else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Shape Abstraction

enum AnyShape: Shape {
    case roundedRectangle(cornerRadius: CGFloat)
    case regularPolygon(sides: Int)
    case diamond
    case circle
    case triangle
    
    func path(in rect: CGRect) -> Path {
        switch self {
        case .roundedRectangle(let cornerRadius):
            return RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
        case .regularPolygon(let sides):
            return RegularPolygon(sides: sides).path(in: rect)
        case .diamond:
            return Diamond().path(in: rect)
        case .circle:
            return Circle().path(in: rect)
        case .triangle:
            return Triangle().path(in: rect)
        }
    }
}

// MARK: - Die Shape Mapping

/// Maps a die's side count to its visual shape
func dieShape(sides: Int) -> AnyShape {
    switch sides {
    case 4: return .triangle
    case 6: return .roundedRectangle(cornerRadius: 6)
    case 8: return .diamond
    case 10: return .regularPolygon(sides: 5)
    case 12: return .regularPolygon(sides: 6)
    case 20: return .regularPolygon(sides: 8)
    case 100: return .circle
    default: return .roundedRectangle(cornerRadius: 6)
    }
}
