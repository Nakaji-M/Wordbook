//
//  ExampleSentenceGeneration.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/11.
//

import MLXLLM
import MLX
import MLXRandom
import Metal

class ExampleSentenceGeneration {
    var prompt = "Generate a sentence with 'happiness'. You must use 'happiness' without changing parts of speech"
    var llm = LLMEvaluator()
//    private var deviceStat = DeviceStat()
    
    init() async {
        // pre-load the weights on launch to speed up the first generation
//        self.prompt = llm.modelConfiguration.defaultPrompt
        _ = try? await llm.load()
        print("Loaded")
    }

    func generateExampleSentence(word: String) async -> String {
        /*
        switch llm.modelConfiguration{
        case .openelm270m4bit:
            prompt = "Generate a sentence with '\(word)'."
        case .qwen205b4bit:
            prompt = "Generate a sentence with '\(word)'. You must use '\(word)' without changing parts of speech"
        default:
            prompt = "Generate a sentence with '\(word)'. You must use '\(word)' without changing parts of speech"
        }
        */
        prompt = "Generate a sentence with '\(word)'. You must use '\(word)' without changing parts of speech"
        await llm.generate(prompt: prompt)
        print("Generated: \(llm.output)")
        return llm.output
    }
}

class LLMEvaluator {

    var running = false

    var output = ""
    var modelInfo = ""
    var stat = ""

    /// this controls which model loads -- phi4bit is one of the smaller ones so this will fit on
    /// more devices
    let modelConfiguration = ModelConfiguration.llama3_2_1B_4bit

    /// parameters controlling the output
    let generateParameters = GenerateParameters(temperature: 0.6)
    let maxTokens = 40 //ここを変更すると高速化できる

    /// update the display every N tokens -- 4 looks like it updates continuously
    /// and is low overhead.  observed ~15% reduction in tokens/s when updating
    /// on every token
    let displayEveryNTokens = 4

    enum LoadState {
        case idle
        case loaded(ModelContainer)
    }

    var loadState = LoadState.idle

    /// load and return the model -- can be called multiple times, subsequent calls will
    /// just return the loaded model
    func load() async throws -> ModelContainer {
        switch loadState {
        case .idle:
            // limit the buffer cache
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

            let modelContainer = try await MLXLLM.loadModelContainer(configuration: modelConfiguration)
            {
                [modelConfiguration] progress in
                Task { @MainActor in
                    self.modelInfo =
                        "Downloading \(modelConfiguration.name): \(Int(progress.fractionCompleted * 100))%"
                }
            }
            self.modelInfo =
                "Loaded \(modelConfiguration.id).  Weights: \(MLX.GPU.activeMemory / 1024 / 1024)M"
            loadState = .loaded(modelContainer)
            return modelContainer

        case .loaded(let modelContainer):
            return modelContainer
        }
    }

    func generate(prompt: String) async {
        guard !running else { return }

        running = true
        self.output = ""

        do {
            let modelContainer = try await load()

            let messages = [["role": "user", "content": prompt]]
            let promptTokens = try await modelContainer.perform { _, tokenizer in
                try tokenizer.applyChatTemplate(messages: messages)
            }

            // each time you generate you will get something new
            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

            let result = await modelContainer.perform { model, tokenizer in
                MLXLLM.generate(
                    promptTokens: promptTokens, parameters: generateParameters, model: model,
                    tokenizer: tokenizer, extraEOSTokens: modelConfiguration.extraEOSTokens
                ) { tokens in
                    // update the output -- this will make the view show the text as it generates
                    if tokens.count % displayEveryNTokens == 0 {
                        let text = tokenizer.decode(tokens: tokens)
                        Task { @MainActor in
                            self.output = text
                        }
                    }

                    if tokens.count >= maxTokens {
                        return .stop
                    } else {
                        return .more
                    }
                }
            }

            // update the text if needed, e.g. we haven't displayed because of displayEveryNTokens
            if result.output != self.output {
                self.output = result.output
            }
            self.stat = " Tokens/second: \(String(format: "%.3f", result.tokensPerSecond))"

        } catch {
            output = "Failed: \(error)"
        }

        running = false
    }
}

