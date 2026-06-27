import Foundation
import CoreML

@available(macOS 14.0, *)
final class RandomBatchProvider: MLBatchProvider {
    private let featureName: String
    private let shape: [NSNumber]
    private let batchCount: Int

    init(featureName: String, shape: [NSNumber], batchCount: Int) {
        self.featureName = featureName
        self.shape = shape
        self.batchCount = batchCount
    }

    var count: Int { batchCount }

    func features(at index: Int) -> any MLFeatureProvider {
        let elementCount = shape.reduce(1) { $0 * $1.intValue }
        let values = (0..<elementCount).map { _ in Float.random(in: -1...1) }
        let array = try! MLMultiArray(shape: shape, dataType: .float32)
        for (i, value) in values.enumerated() {
            array[i] = NSNumber(value: value)
        }
        return try! MLDictionaryFeatureProvider(dictionary: [featureName: MLFeatureValue(multiArray: array)])
    }
}

@available(macOS 14.0, *)
func main() throws {
    print("ANE probe starting")
    print("Available compute devices:", MLModel.availableComputeDevices)

    let modelURL = URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/BridgeVersion.bin")
    _ = modelURL

    let shape: [NSNumber] = [1, 3, 224, 224]
    let featureName = "input"

    let input = MLImageConstraint(pixelsWide: 224, pixelsHigh: 224, pixelFormatType: 1111970369)
    let output = MLEmptyShapeConstraint(type: .float32)
    let description = MLModelDescription()
    let inputDescription = MLFeatureDescription(name: featureName, type: .multiArray, optional: false, constraints: MLMultiArrayConstraint(shape: shape, dataType: .float32))
    let outputDescription = MLFeatureDescription(name: "output", type: .multiArray, optional: false, constraints: MLMultiArrayConstraint(shape: [1, 1000], dataType: .float32))
    description.inputDescriptionsByName = [featureName: inputDescription]
    description.outputDescriptionsByName = ["output": outputDescription]

    let program = try MLProgram {
        let x = Input(name: featureName, shape: [1, 3, 224, 224], dataType: .float)
        let w1 = Parameter(randomUniform: [128, 3, 3, 3], dataType: .float)
        let conv1 = Conv(x, w1, strides: [1, 1], pads: .same)
        let relu1 = Relu(conv1)
        let w2 = Parameter(randomUniform: [128, 128, 3, 3], dataType: .float)
        let conv2 = Conv(relu1, w2, strides: [1, 1], pads: .same)
        let relu2 = Relu(conv2)
        let pooled = ReduceMean(relu2, axes: [2, 3], keepDims: false)
        let w3 = Parameter(randomUniform: [128, 1000], dataType: .float)
        let out = MatMul(pooled, w3)
        Output(out, name: "output")
    }

    let compiledURL = try program.writeCompiledModel(to: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ANEProbe.mlmodelc"))
    let config = MLModelConfiguration()
    config.computeUnits = .cpuAndNeuralEngine
    let model = try MLModel(contentsOf: compiledURL, configuration: config)

    let batch = RandomBatchProvider(featureName: featureName, shape: shape, batchCount: 8)

    var iteration = 0
    while true {
        let start = CFAbsoluteTimeGetCurrent()
        _ = try model.predictions(fromBatch: batch)
        let duration = (CFAbsoluteTimeGetCurrent() - start) * 1000
        iteration += 1
        print("iteration \(iteration)  batch=8  duration_ms=\(String(format: "%.1f", duration))")
    }
}

if #available(macOS 14.0, *) {
    do {
        try main()
    } catch {
        fputs("ANE probe failed: \(error)\n", stderr)
        exit(1)
    }
} else {
    fputs("ANE probe requires macOS 14+\n", stderr)
    exit(1)
}
