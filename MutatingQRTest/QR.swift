//
//  QR.swift
//  MutatingQRTest
//
//  Created by Kai Quan Tay on 8/6/24.
//

import Foundation
import CoreGraphics
import CoreImage

let zoneSize = 3

struct QR {
    internal var rawData: [[Bool]]

    /// Size `s` is defined by `s = 17 + 4n` where `n` is the "version" of the QR code
    var size: Int {
        rawData.count
    }

    /// A set of all zone IDs for the QR code's size. The `blackPixelCount` is always set to zero here.
    var zoneIds: [QRAnimatableData] {
        let zoneWidth = Int((CGFloat(size)/CGFloat(zoneSize)).rounded(.awayFromZero))

        return (0..<zoneWidth)
            .flatMap { row in
                (0..<zoneWidth).map { col in
                    .init(zone: .init(x: col, y: row), blackPixelCount: 0)
                }
            }
    }

    init?(string: String) {
        guard let qrImage = CGImage.qrImage(from: string) else { return nil }

        // sample the whole grid
        let sample = qrImage.samplePixelBrightness()
        let mapped = sample.map { $0.map { $0 > 0 } }
        self.rawData = mapped
    }

    func isWhiteAt(_ point: IntPoint) -> Bool {
        rawData[point.y][point.x]
    }

    /// We create "zones" of zoneSize by zoneSize pixels (except for the items at the very edge). The animation data is just the
    /// number of black pixels before this pixel, combined with the unique ID of the zone.
    func animationData(for point: IntPoint) -> QRAnimatableData? {
        // if this pixel is white, it has no animation data
        guard !isWhiteAt(point) else { return nil }

        let zone = IntPoint(
            x: point.x/zoneSize,
            y: point.y/zoneSize
        )

        // count each black pixel inside the zone until we reach the `point`
        var blackPixelCount = 0
        for yOffset in 0..<zoneSize where zone.y*zoneSize + yOffset < size { // ensure that we stay within bounds
            for xOffset in 0..<zoneSize where zone.x*zoneSize + xOffset < size {
                let position = IntPoint(x: zone.x*zoneSize + xOffset, y: zone.y*zoneSize + yOffset)

                guard !isWhiteAt(position) else { continue }

                if position == point {
                    return .init(zone: zone, blackPixelCount: blackPixelCount)
                } else {
                    blackPixelCount += 1
                }
            }
        }

        fatalError("Internal Inconsistency")
    }

    /// Decodes an animationData into a position. Note that if the animation data does not exist,
    /// it will just return the first black pixel within the zone. If the animation data is invalid, it returns nil.
    func pointFor(animationData: QRAnimatableData) -> IntPoint? {
        let zone = animationData.zone
        let blackPixelCount = animationData.blackPixelCount

        // returned if blackPixelCount >= number of black pixels in the zone
        var firstBlackPixel: IntPoint?

        var currentBlackPixelCount = 0
        for yOffset in 0..<zoneSize where zone.y*zoneSize + yOffset < size { // ensure that we stay within bounds
            for xOffset in 0..<zoneSize where zone.x*zoneSize + xOffset < size {
                let position = IntPoint(x: zone.x*zoneSize + xOffset, y: zone.y*zoneSize + yOffset)

                guard !isWhiteAt(position) else { continue }

                firstBlackPixel = firstBlackPixel ?? position

                if currentBlackPixelCount == blackPixelCount {
                    return position
                } else {
                    currentBlackPixelCount += 1
                }
            }
        }

        return firstBlackPixel
    }
}

struct IntPoint: Equatable, Hashable {
    var x: Int
    var y: Int
}

struct QRAnimatableData: Equatable, Hashable {
    var zone: IntPoint
    var blackPixelCount: Int

    func with(blackPixelCount: Int) -> QRAnimatableData {
        var mutableSelf = self
        mutableSelf.blackPixelCount = blackPixelCount
        return mutableSelf
    }
}

extension CGImage {
    func samplePixelBrightness() -> [[UInt8]] {
        guard let imageData = self.dataProvider?.data else {
            return []
        }

        let imgData: UnsafePointer<UInt8> = CFDataGetBytePtr(imageData)

        let imageWidth = self.width * 4

        var points: [[UInt8]] = .init(repeating: [], count: self.height)

        for row in 0..<self.height {
            var rowData: [UInt8] = .init(repeating: 0, count: self.width)
            for col in 0..<self.width {
                let index = (row * imageWidth) + col*4
                rowData[col] = imgData[index]
            }
            points[row] = rowData
        }

        return points
    }

    static func qrImage(from string: String) -> CGImage? {
        let data = string.data(using: String.Encoding.ascii)

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")

        let context = CIContext()

        guard let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) 
        else { return nil }

        return cgImage
    }
}
