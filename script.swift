#!/usr/bin/env xcrun swift -O

import Foundation

// A DNA is just an array of values

typealias DNA = [UInt8]

extension Sequence where Iterator.Element == UInt8 {

    // Handy method to print a DNA
    var dnaString: String {
        return map { (value: UInt8) in
            switch value {
            case 0..<10: return String(value)
            case 11: return "+"
            case 12: return "-"
            case 13: return "*"
            case 14: return "/"
            default: return "nan"
            }
        }.joined(separator: " ")
    }
}

// Evaluation of a DNA

typealias Operation = (Double, Double) -> Double

struct PartialExpression {
    private var first: Double?
    private var second: Double?
    private var operation: Operation?

    var isComplete: Bool {
        return first != nil
            && second != nil
            && operation != nil
    }

    mutating func setOperand(_ operand: Double) {
        if first == nil {
            first = operand
            return
        }
        if operation != nil && second == nil {
            second = operand
        }
    }

    mutating func setOperation(_ operation: @escaping Operation) {
        guard first != nil && self.operation == nil else {
            return
        }
        self.operation = operation
    }

    var result: Double {
        guard let operation = operation,
            let first = first,
            let second = second else {
            return self.first ?? 0
        }
        let value = operation(first, second)
        guard !value.isNaN && !value.isInfinite else {
            return 0
        }
        return value
    }
}

func eval(dna: DNA) -> Double {
    var expression = PartialExpression()
    for item in dna {
        if expression.isComplete {
            let eval = expression.result
            expression = PartialExpression()
            expression.setOperand(eval)
        }
        switch item {
        case 0..<10:
            expression.setOperand(Double(item))
        case 11:
            expression.setOperation(+)
        case 12:
            expression.setOperation(-)
        case 13:
            expression.setOperation(*)
        case 14:
            expression.setOperation(/)
        default:
            break
        }
    }
    return expression.result
}

// Some tests about DNA evaluation

let plus: UInt8 = 11
let minus: UInt8 = 12
let times: UInt8 = 13
let divides: UInt8 = 14
let nan: UInt8 = 15

func testEval(dna: DNA, value: Double) {
    let result = eval(dna: dna)
    assert(result == value, "\(dna.dnaString) == \(result) != \(value)")
}

testEval(dna: [1, plus, 2, minus, 5, times, 2], value: -4)
testEval(dna: [1, 2, 3, plus, plus, 2, 4], value: 3)
testEval(dna: [1, 2, times, times, 3, plus, plus, 2, 4], value: 5)
testEval(dna: [divides, 3, minus, divides, 0, nan, plus, 2, divides, 5], value: 1)
testEval(dna: [3, divides, 0, minus, 2], value: -2)

// Core algorithm

// Wrapper around arc4random_uniform
func random(_ upperBound: Int) -> Int {
    return Int(arc4random_uniform(UInt32(upperBound)))
}

func randomValue() -> UInt8 {
    return UInt8(random(0xF))
}

func randomPopulation(populationSize: Int, dnaSize: Int) -> [DNA] {
    return (0..<populationSize).map { _ in
        return (0..<dnaSize).map { _ in
            randomValue()
        }
    }
}

func calculateFitness(dna: DNA, optimal: Double) -> Double {
    return abs(eval(dna: dna) - optimal)
}

// Probability of 1 / mutationChance to mutate the DNA
func mutate(dna: DNA, mutationChance: Int) -> DNA {
    return dna.map {
        let rand = random(mutationChance)
        if rand == 1 {
            return randomValue() // mutation
        } else {
            return $0 // old value
        }
    }
}

// Create an offspring
func crossover(dna1: DNA, dna2: DNA) -> (dna1: DNA, dna2: DNA) {
    precondition(dna1.count == dna2.count, "DNA \(dna1.dnaString) and \(dna2.dnaString) have not the same size")
    let pos = random(dna1.count)
    let dna1Index1 = dna1.index(dna1.startIndex, offsetBy: pos)
    let dna2Index1 = dna2.index(dna2.startIndex, offsetBy: pos)
    let result1: DNA = Array(dna1.prefix(upTo: dna1Index1) + dna2.suffix(from: dna2Index1))
    let result2: DNA = Array(dna2.prefix(upTo: dna2Index1) + dna1.suffix(from: dna1Index1))
    return (result1, result2)
}

struct WeightedDNA {
    let dna: DNA
    let weight: Double
}

func weightedChoice(items: [WeightedDNA]) -> WeightedDNA {
    let totalWeight = items.reduce(0) { $0 + $1.weight }
    let divider = 1000000.0
    var randomWeight = Double(random(Int(totalWeight * divider))) / divider
    for item in items {
        if randomWeight < item.weight {
            return item
        }
        randomWeight -= item.weight
    }
    return items[0]
}

func compute(optimal: Double, dnaSize: Int, populationSize: Int, generations: Int, mutationChance: Int) {
    var population: [DNA] = randomPopulation(populationSize: populationSize, dnaSize: dnaSize)
    var fittest: DNA = []

    for generation in 0...generations {
        print("Generation \(generation) with random sample: \(population[0].dnaString)")
        var weightedPopulation: [WeightedDNA] = []
        for individual in population {
            let fitnessValue = calculateFitness(dna: individual, optimal: optimal)
            let weightedDNA = WeightedDNA(
                dna: individual,
                weight: fitnessValue == 0 ? 1.0 : 1.0 / Double(fitnessValue)
            )
            weightedPopulation.append(weightedDNA)
        }

        population = []

        for _ in 0...(populationSize / 2) {
            let individual1 = weightedChoice(items: weightedPopulation)
            let individual2 = weightedChoice(items: weightedPopulation)

            let offspring = crossover(dna1: individual1.dna, dna2: individual2.dna)

            population.append(mutate(dna: offspring.dna1, mutationChance: mutationChance))
            population.append(mutate(dna: offspring.dna2, mutationChance: mutationChance))
        }

        fittest = population[0]
        var minFitness = calculateFitness(dna: fittest, optimal: optimal)

        for individual in population {
            let fitness = calculateFitness(dna: individual, optimal: optimal)
            if fitness < minFitness {
                fittest = individual
                minFitness = fitness
            }
        }
        if minFitness == 0 {
            break
        }
    }
    print("fittest string: \(fittest.dnaString), \(eval(dna: fittest))")
}

func main() {
    compute(
        optimal: 23,
        dnaSize: 10,
        populationSize: 50,
        generations: 5000,
        mutationChance: 50
    )
}

main()
