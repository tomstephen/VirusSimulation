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
// grey -> dead

enum infected_state {
    case healthy
    case infected
    case recovered
    case dead
}


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
    var state = infected_state.healthy
    
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
    
    func updateColor() {
        switch self.state {
        case .healthy: self.color = Color.green
        case .infected: self.color = Color.red
        case .dead: self.color = Color.gray
        case .recovered: self.color = Color.blue
        }
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
    var number_of_agents: Int
    var number_infected: Int
    
    init(duration: TimeInterval, number_of_agents: Int, number_infected: Int) {
        self.duration = duration
        self.number_of_agents = number_of_agents
        self.number_infected = number_infected
        self.agents = initialiseAgents(num_agents: self.number_of_agents, num_infected: self.number_infected)
    }
    
    private func initialiseAgents(num_agents: Int, num_infected: Int) -> [Agent] {
        var agents: [Agent] = []
        
        for _ in 1...num_agents {
            let position = CGSize(width: Int.random(in: -500..<500), height: Int.random(in: -500..<500))
            let speed = 200.0
            let angle = Double.random(in: 0.0..<360.0)
            let velocity = CGPoint(x: speed * cos(angle * Double.pi / 180), y: speed * sin(angle * Double.pi / 180))
            agents.append(Agent(position: position, color: Color.green, velocity: velocity))
        }
        
        for index in 1...num_infected {
            agents[index].state = .infected
            agents[index].updateColor()
        }
        
        return agents
    }
    
    private func initialiseTimer() {
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            for agent in self.agents! {
                agent.updatePosition(timeElapsed: 0.02)
                agent.updateColor()
            }
            
            for agent1 in self.agents! {
                for agent2 in self.agents! {
                    if agent1 != agent2 {
                        if agent1.state == .infected || agent2.state == .infected {
                            if isColliding(agent1: agent1, agent2: agent2) {
                                agent1.state = .infected
                                agent2.state = .infected
                            }
                        }
                    }
                }
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
            Text("Virus Spread Simulation")
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 1020, height: 1020)
                
                ForEach(self.simulation.agents!, id: \.self) { agent in
                    createCircle(diameter: agent.diameter, position: agent.position, color: agent.color)
                }
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

func isColliding(agent1: Agent, agent2: Agent) -> Bool {
    let delta_x = agent1.position.width - agent2.position.width
    let delta_y = agent1.position.height - agent2.position.height
    
    let distance = sqrt(pow(delta_x, 2) + pow(delta_y, 2))

    let min_distance = agent1.diameter + agent2.diameter
    
    return distance < min_distance
}
