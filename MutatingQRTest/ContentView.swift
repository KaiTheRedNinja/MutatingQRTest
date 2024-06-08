//
//  ContentView.swift
//  MutatingQRTest
//
//  Created by Kai Quan Tay on 7/6/24.
//

import SwiftUI

#if os(iOS)
typealias OSImage = UIImage
#else
typealias OSImage = NSImage
#endif

let refreshRate: Double = 0.2

struct ContentView: View {
    @State var counter: Int = 0
    @State var qr: QR = .init(string: "hello!")!
    @State var qrViewSize: CGSize = .zero

    @Namespace var namespace

    let timer = Timer.publish(every: refreshRate, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            QROffsetRenderer(qr: qr)
            QRPositionRenderer(qr: qr)
        }
        .padding()
        .frame(width: 300, height: 600)
        .onReceive(timer) { _ in
            counter += 1
            withAnimation(.easeInOut(duration: refreshRate)) {
                qr = .init(string: "hello! \(counter)")!
            }
        }
    }
}

struct QROffsetRenderer: View {
    var qr: QR
    @State var qrViewSize: CGSize = .zero
    @Namespace var namespace

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geom -> Color in
                { () -> Color in
                    DispatchQueue.main.async {
                        qrViewSize = geom.size
                        print("Size: \(qrViewSize)")
                    }
                    return Color.clear
                }()
            }

            let cellSize = qrViewSize.width/CGFloat(qr.size)

            ForEach(qr.zoneIds, id: \.self) { zoneId in
                ForEach(0..<(zoneSize*zoneSize), id: \.self) { cellNum in
                    if let position = qr.pointFor(animationData: zoneId.with(blackPixelCount: cellNum)) {
                        Color.black
                            .frame(
                                width: cellSize,
                                height: cellSize
                            )
                            .offset(
                                x: cellSize*CGFloat(position.x),
                                y: cellSize*CGFloat(position.y)
                            )
                    }
                }
            }
        }
    }
}

struct QRPositionRenderer: View {
    var qr: QR
    @Namespace var namespace

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<qr.size, id: \.self) { rowNum in
                HStack(spacing: 0) {
                    ForEach(0..<qr.size, id: \.self) { colNum in
                        let position = IntPoint(x: colNum, y: rowNum)
                        if qr.isWhiteAt(position) {
                            Color.clear
                        } else {
                            Color.black
                                .matchedGeometryEffect(id: qr.animationData(for: position)!, in: namespace)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
