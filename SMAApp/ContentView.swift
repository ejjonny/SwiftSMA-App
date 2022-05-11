//
//  ContentView.swift
//  SMAApp
//
//  Created by Ethan John on 5/9/22.
//

import SwiftUI
import SMA
import Combine

extension Double: SMACoordinate {
    public init(_ value: Double) {
        self = value
    }
}
extension Cell: Identifiable where Coordinate == Double {}

func newSMA(
    populationSize: Int,
    space: Double,
    maxIterations: Int
) -> SMA<Double> {
    SMA<Double>(
        populationSize: populationSize,
        space: 0...space,
        maxIterations: maxIterations,
        fitnessEvaluation: {
            let x = $0 / 1000000000
            return (x * sin(3 * x))
//            (0.00002 * pow(($0 -(space / 2) + 1000), 2)) + (10000 * sin($0))
//            (space - abs(target - $0))
        }
    )
}
struct ContentView: View {
    @State var sma: SMA<Double>?
    @State var popSize = UserDefaults.standard.population
    @State var range = UserDefaults.standard.range
    @State var maxIterations = UserDefaults.standard.max
    
    @State var updating = false
    @State var i = 1
    var timer = Timer.TimerPublisher(interval: 0.1, runLoop: .main, mode: .default)

    var body: some View {
        VStack {
            VStack {
                if let sma = sma {
                    Spacer()
                    Text("Evaluations: \(sma.evaluations)")
                        .font(.system(.title, design: .monospaced))
                    Text("Iteration: \(i) / \(sma.maxIterations)")
                        .font(.system(.title, design: .monospaced))
                    Text(String(format: "Best location: %.2f", sma.globalBest?.position ?? -1))
                        .font(.system(.title, design: .monospaced))
                    Text(String(format: "Best fitness: %.2f", sma.globalBest?.fitness ?? -1))
                        .font(.system(.title, design: .monospaced))
                    GeometryReader { geo in
                        ZStack {
                            Rectangle()
                                .frame(width: geo.size.width, height: 5)
                                .foregroundColor(.gray)
                                .opacity(0.5)
                            if let best = sma.globalBest {
                                Circle()
                                    .stroke(Color.green, lineWidth: 5)
                                    .frame(width: 30, height: 30)
                                    .position(x: geo.size.width * (best.position / sma.space.upperBound), y: geo.size.height / 2)
                                    .opacity(0.3)
                            }
                            ForEach(sma.population) { cell in
                                Circle()
                                    .stroke(Color.red, lineWidth: 1)
                                    .frame(width: 30, height: 30)
                                    .position(x: geo.size.width * (cell.position / sma.space.upperBound), y: geo.size.height / 2)
                                if cell.weight.sign == .plus {
                                    Rectangle()
                                        .frame(width: 4, height: cell.weight * 20)
                                        .position(x: geo.size.width * (cell.position / sma.space.upperBound), y: geo.size.height / 2)
                                        .offset(y: 50)
                                }
                                if cell.fitness.sign == .plus {
                                    Rectangle()
                                        .frame(width: 4, height: cell.fitness / 1000)
                                        .position(x: geo.size.width * (cell.position / sma.space.upperBound), y: geo.size.height / 2)
                                        .offset(y: -200)
                                        .opacity(0.4)
                                }
                            }
                        }
                    }
                    .frame(width: 1000, height: 100)
                }
            }
            .frame(minHeight: 500)
            HStack {
                VStack(alignment: .leading) {
                    Text("population size:")
                    TextField("population size", text: $popSize)
                    Text("range size:")
                    TextField("range size", text: $range)
                    Text("max iterations:")
                    TextField("max iterations", text: $maxIterations)
                }
                .frame(width: 200)
                VStack {
                    Button {
                        guard let popSize = Int(popSize),
                              let space = Double(range),
                              let maxIterations = Int(maxIterations) else {
                                  return
                              }
                        UserDefaults.standard.population = self.popSize
                        UserDefaults.standard.range = self.range
                        UserDefaults.standard.max = self.maxIterations
                        i = 1
                        sma = newSMA(
                            populationSize: popSize,
                            space: space,
                            maxIterations: maxIterations
                        )
                    } label: {
                        Text("Reset")
                    }
                    Button {
                        updating = false
                    } label: {
                        Text("Stop")
                    }
                    Button {
                        sma?.iteration(&i)
                    } label: {
                        Text("Iterate")
                    }
                    Button {
                        updating = true
                    } label: {
                        Text("Solve")
                    }
                }
            }
            .padding(50)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            let _ = timer.connect()
        }
        .onReceive(timer) { _ in
            if updating {
                let iterationsLeft = sma?.iteration(&i)
                if iterationsLeft == false {
                    updating = false
                }
            }
        }
    }
}

extension UserDefaults {
    public enum Keys {
        static let population = "population"
        static let range = "range"
        static let max = "max"
        static let target = "target"
    }

    var population: String {
        set {
            set(newValue, forKey: Keys.population)
        }
        get {
            return string(forKey: Keys.population) ?? ""
        }
    }
    var range: String {
        set {
            set(newValue, forKey: Keys.range)
        }
        get {
            return string(forKey: Keys.range) ?? ""
        }
    }
    var max: String {
        set {
            set(newValue, forKey: Keys.max)
        }
        get {
            return string(forKey: Keys.max) ?? ""
        }
    }
    var target: String {
        set {
            set(newValue, forKey: Keys.target)
        }
        get {
            return string(forKey: Keys.target) ?? ""
        }
    }
}
