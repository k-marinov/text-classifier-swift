import Foundation

let positiveSamples: [String] = ["1", "2", "3", "4", "5"]
let negativeSamples: [String] = ["6", "7", "8", "9", "10"]

extension String {

    var tokenized: [String] {
        return self.components(separatedBy: " ")
    }

}


class TextClassifier {

    private var positiveWords: [String: Double] = [:]
    private var negativeWords: [String: Double] = [:]
    private var positiveSamplesCount: Double = 0.0
    private var negativeSamplesCount: Double = 0.0

    private var wordLogProbabilityRatio: [String: Double] = [:]
    private var baseRatio: Double = 0


    init(positiveSamples: [String], negativeSamples: [String]) {
        trainModel(positiveSamples: positiveSamples, negativeSamples: negativeSamples)
    }

    func isPositiveComment(input: String) -> Bool {
        var ratio = baseRatio

        for input in input.tokenized {
             ratio += wordLogProbabilityRatio[input] ?? 0
        }
        print("ratio=", ratio)
        return ratio > 0
    }

    private func trainModel(positiveSamples: [String], negativeSamples: [String]) {
        positiveWords = positiveSamples
            .flatMap { $0.tokenized }
            .reduce([String: Double](), { (dictionary, word) -> [String: Double] in
                var newDictionary = dictionary
                let count = newDictionary[word] ?? 1.0
                newDictionary[word] = count + 1.0
                return newDictionary
            })
        positiveSamplesCount = Double(positiveSamples.map { $0.tokenized.count }.reduce(0, +))


        negativeWords = negativeSamples
            .flatMap { $0.tokenized }
            .reduce([String: Double](), { (dictionary, word) -> [String: Double] in
                var newDictionary = dictionary
                let count = newDictionary[word] ?? 1.0
                newDictionary[word] = count + 1.0
                return newDictionary
            })
        negativeSamplesCount = Double(negativeSamples.map { $0.tokenized.count }.reduce(0, +))


        baseRatio = log(positiveSamplesCount / negativeSamplesCount)

        let array = positiveWords.keys.compactMap { $0 } + negativeWords.keys.compactMap { $0 }
        let allWords: Set<String> = Set<String>(array)

        // smallAlpha with 1.16395 returns 1.0 per each word
        // smallAlpha with 0.0000000041223008 returns 20.0 per each word.
        let smallAlpha: Double = 1.16395
        allWords.forEach { word in
            let existingPositiveWordPoint: Double = positiveWords[word] ?? 0
            let existingNegativeWordPoint: Double = negativeWords[word] ?? 0
            let ratio = (existingPositiveWordPoint + smallAlpha) / (existingNegativeWordPoint + smallAlpha);
            print("ratio=", ratio, "word=", word," log=", log(ratio))
            wordLogProbabilityRatio[word] = log(ratio)
        }
    }

}

/// Negative sentiment returns negative value
/// Positive sentiment returns positive value
/// Example giving a negative sample 6 will return -1.0 considering there are 5 negative and 5 positive samples
/// Having positive sample 1 and negative sample 6 will return 0 because they cancel each other


let classifier = TextClassifier(positiveSamples: positiveSamples, negativeSamples: negativeSamples)
classifier.isPositiveComment(input: "6 1") // returns 0.0 since they cancel each other
classifier.isPositiveComment(input: "6 1 2") // returns 1 since there is more positive
classifier.isPositiveComment(input: "6 7 8") // returns -3 since all are negative words
classifier.isPositiveComment(input: "6 7 8 1") // returns -2 since there is more negative words
