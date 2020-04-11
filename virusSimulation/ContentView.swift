//
//  ContentView.swift
//  virusSimulation
//
//  Created by Tom Stephen on 11/4/20.
//  Copyright © 2020 Tom Stephen. All rights reserved.
//

import SwiftUI
//import PlaygroundSupport

// green -> uninfected
// red -> infected
// blue -> recovered
// brown -> dead




//
// from https://stackoverflow.com/questions/34705786/swift-how-to-implement-hashable-protocol-based-on-object-reference
//

open class HashableClass {
    public init() {}
}

// MARK: - <Hashable>

extension HashableClass: Hashable {

    public func hash(into hasher: inout Hasher) {
         hasher.combine(ObjectIdentifier(self).hashValue)
    }

    // `hashValue` is deprecated starting Swift 4.2, but if you use
    // earlier versions, then just override `hashValue`.
    //
    // public var hashValue: Int {
    //    return ObjectIdentifier(self).hashValue
    // }
}

// MARK: - <Equatable>

extension HashableClass: Equatable {

    public static func ==(lhs: HashableClass, rhs: HashableClass) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
// end
//

class Agent: HashableClass {
    var position = CGSize.zero
    var color = Color.green
    var velocity = CGPoint.zero
    
    let diameter: CGFloat = 10.0
    
    init(position: CGSize, color: Color, velocity: CGPoint) {
        self.position = position
        self.color = color
        self.velocity = velocity
    }
    
    func updatePosition(timeElapsed: TimeInterval) {
        let elapsed = CGFloat(timeElapsed)
        position.width += velocity.x * elapsed
        position.height += velocity.y * elapsed
        
        checkWallCollisions()
    }
    
    func checkWallCollisions() {
        if position.width < -500 || position.width > 500 {
            velocity.x *= -1
        }
        if position.height < -500 || position.height > 500 {
            velocity.y *= -1
        }
    }
}

class Simulation: ObservableObject {
    var timer: Timer?
    var agents: [Agent]?
    @Published var iteration = 0
    var startTime = Date()
    var duration: TimeInterval
    
    init(duration: TimeInterval) {
        self.duration = duration
        self.agents = initialiseAgents(number: 100)
    }
    
    private func initialiseAgents(number: Int) -> [Agent] {
        var agents: [Agent] = []
        
        for _ in 1...number {
            let position = CGSize(width: Int.random(in: -500..<500), height: Int.random(in: -500..<500))
            let speed = 200.0
            let angle = Double.random(in: 0.0..<360.0)
            let velocity = CGPoint(x: speed * cos(angle * Double.pi / 180), y: speed * sin(angle * Double.pi / 180))
            agents.append(Agent(position: position, color: Color.green, velocity: velocity))
        }
        
        return agents
    }
    
    private func initialiseTimer() {
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            for agent in self.agents! {
                agent.updatePosition(timeElapsed: 0.02)
            }
            
            self.iteration += 1
            
            let runTime = Date().timeIntervalSince(self.startTime)
            if runTime > self.duration {
                timer.invalidate()
            }
        }
    }
    
    func start() {
        initialiseTimer()
    }
    
    func stop() {
        self.timer?.invalidate()
    }
}

struct ContentView: View {
    @ObservedObject var simulation: Simulation
    init(simulation: Simulation) {
        self.simulation = simulation
    }
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 1020, height: 1020)
                
                ForEach(self.simulation.agents!, id: \.self) { agent in
                    createCircle(diameter: agent.diameter, position: agent.position, color: agent.color)
                }
                
//                createCircle(diameter: self.simulation.agents!.diameter, position: self.simulation.agents!.position, color: self.simulation.agents!.color)
            }
            HStack {
                Button(action: {
                    self.simulation.start()
                } ) {
                    Text("Start!")
                        .foregroundColor(Color.green)
                }
                Button(action: {
                    self.simulation.stop()
                }) {
                    Text("Stop!")
                        .foregroundColor(Color.red)
                }
            }
            
        }
    }
}

func createCircle(diameter: CGFloat, position: CGSize, color: Color) -> some View {
    return Circle()
        .fill(color)
        .frame(width: diameter)
        .offset(position)
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
