//
//  Inference.swift
//  GFy
//

import Foundation
import Combine

/// Represents an inference session with Ollama
class Inference {
    // MARK: - Properties
    private let ollamaAPI = OllamaAPI()
    private let model: String
    private let systemPrompt: String?
    private let options: OllamaOptions
    
    private var isInitialized = false
    private var initializationError: Error?
    
    // MARK: - Initialization
    
    /// Creates a new inference session
    /// - Parameters:
    ///   - model: The model to use (defaults to gemma3:4b)
    ///   - systemPrompt: Optional system prompt to use for all requests
    ///   - options: Generation options
    ///   - completion: Called when initialization is complete
    init(
        model: String = "gemma3:4b",
        systemPrompt: String? = nil,
        options: OllamaOptions = OllamaOptions(),
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        self.model = model
        self.systemPrompt = systemPrompt
        self.options = options
        
        // Check if Ollama is reachable
        ollamaAPI.isOllamaReachable { [weak self] isReachable in
            guard let self = self else { return }
            
            if !isReachable {
                let error = NSError(
                    domain: "Inference",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Ollama server is not reachable"]
                )
                self.initializationError = error
                completion(.failure(error))
                return
            }
            
            // Check if the model exists
            self.ollamaAPI.doesModelExist(model: self.model) { [weak self] exists in
                guard let self = self else { return }
                
                if !exists {
                    let error = NSError(
                        domain: "Inference",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Model '\(self.model)' does not exist on Ollama server"]
                    )
                    self.initializationError = error
                    completion(.failure(error))
                    return
                }
                
                // Initialization successful
                self.isInitialized = true
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Checks if the inference session is ready to use
    /// - Returns: True if initialized successfully, false otherwise
    func isReady() -> Bool {
        return isInitialized
    }
    
    /// Gets the initialization error if any
    /// - Returns: Error that occurred during initialization, or nil if successful
    func getInitializationError() -> Error? {
        return initializationError
    }
    
    /// Cancels any ongoing streaming request
    func cancelStream() {
        ollamaAPI.cancelStream()
    }
    
    /// Streams a response from Ollama
    /// - Parameters:
    ///   - prompt: The user's prompt
    ///   - onToken: Callback for each token received
    ///   - onComplete: Callback when streaming is complete
    ///   - onError: Callback for errors
    func streamResponse(
        prompt: String,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard isInitialized else {
            let error = initializationError ?? NSError(
                domain: "Inference",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Inference session is not initialized"]
            )
            onError(error)
            return
        }
        
        // Clear context before each response
        ollamaAPI.resetChat()
        
        // Stream the response
        ollamaAPI.streamResponse(
            prompt: prompt,
            systemPrompt: systemPrompt,
            model: model,
            options: options,
            onToken: onToken,
            onComplete: onComplete,
            onError: onError
        )
    }
    
    /// Generates a non-streaming response from Ollama
    /// - Parameters:
    ///   - prompt: The user's prompt
    ///   - completion: Callback with result
    func generateResponse(
        prompt: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard isInitialized else {
            let error = initializationError ?? NSError(
                domain: "Inference",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Inference session is not initialized"]
            )
            completion(.failure(error))
            return
        }
        
        // Clear context before each response
        ollamaAPI.resetChat()
        
        // Generate the response
        ollamaAPI.generateResponse(
            prompt: prompt,
            systemPrompt: systemPrompt,
            model: model,
            options: options,
            completion: completion
        )
    }
}

// MARK: - Usage Example
/*
// Example usage:
let inference = Inference(
    model: "gemma3:4b",
    systemPrompt: "You are a helpful assistant",
    options: OllamaOptions(temperature: 0.8, topP: 0.95)
) { result in
    switch result {
    case .success:
        print("Inference session initialized successfully")
        
        // Stream a response
        inference.streamResponse(
            prompt: "Tell me a short story",
            onToken: { token in
                print(token, terminator: "")
            },
            onComplete: { fullResponse in
                print("\nComplete response received")
            },
            onError: { error in
                print("Error: \(error.localizedDescription)")
            }
        )
        
    case .failure(let error):
        print("Failed to initialize inference session: \(error.localizedDescription)")
    }
}
*/
