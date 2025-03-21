//
//  AI.swift
//  GFy
//

import Foundation
import Combine

// MARK: - OllamaOptions
struct OllamaOptions {
    var minP: Double? = 0.0
    var mirostat: Int? = 0
    var mirostatEta: Double? = 0.1
    var mirostatTau: Double? = 5.0
    var numCtx: Int? = 2048
    var numPredict: Int? = 128
    var repeatLastN: Int? = 64
    var repeatPenalty: Double? = 1.1
    var seed: Int? = 0
    var stop: String? = nil
    var temperature: Double? = 0.7
    var tfsZ: Double? = 1.0
    var topK: Int? = 40
    var topP: Double? = 0.9
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        if let minP = minP { dict["min_p"] = minP }
        if let mirostat = mirostat { dict["mirostat"] = mirostat }
        if let mirostatEta = mirostatEta { dict["mirostat_eta"] = mirostatEta }
        if let mirostatTau = mirostatTau { dict["mirostat_tau"] = mirostatTau }
        if let numCtx = numCtx { dict["num_ctx"] = numCtx }
        if let numPredict = numPredict { dict["num_predict"] = numPredict }
        if let repeatLastN = repeatLastN { dict["repeat_last_n"] = repeatLastN }
        if let repeatPenalty = repeatPenalty { dict["repeat_penalty"] = repeatPenalty }
        if let seed = seed { dict["seed"] = seed }
        if let stop = stop { dict["stop"] = stop }
        if let temperature = temperature { dict["temperature"] = temperature }
        if let tfsZ = tfsZ { dict["tfs_z"] = tfsZ }
        if let topK = topK { dict["top_k"] = topK }
        if let topP = topP { dict["top_p"] = topP }
        
        return dict
    }
}

// MARK: - OllamaMessage
struct OllamaMessage: Codable {
    let role: String
    let content: String
}

// MARK: - OllamaStreamResponse
struct OllamaStreamResponse: Codable {
    let model: String
    let created_at: String?
    let message: OllamaMessage?
    let done: Bool
    let total_duration: Int?
    let load_duration: Int?
    let prompt_eval_count: Int?
    let prompt_eval_duration: Int?
    let eval_count: Int?
    let eval_duration: Int?
}

// MARK: - OllamaAPI
class OllamaAPI {
    private let baseURL = "http://localhost:11434/api"
    private let defaultModel = "gemma3:4b"
    private var currentTask: URLSessionDataTask?
    private var isStreaming = false
    
    private var messages: [OllamaMessage] = []
    
    // MARK: - Public Methods
    
    /// Checks if Ollama server is reachable
    /// - Parameter completion: Callback with boolean result
    func isOllamaReachable(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/tags") else {
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }
        task.resume()
    }
    
    /// Checks if a specific model exists on the Ollama server
    /// - Parameters:
    ///   - model: Model name to check
    ///   - completion: Callback with boolean result
    func doesModelExist(model: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/tags") else {
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(false)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let models = json["models"] as? [[String: Any]] {
                    let modelExists = models.contains { modelInfo in
                        if let name = modelInfo["name"] as? String {
                            return name == model
                        }
                        return false
                    }
                    completion(modelExists)
                } else {
                    completion(false)
                }
            } catch {
                completion(false)
            }
        }
        task.resume()
    }
    
    /// Checks if Ollama is currently streaming a response
    /// - Returns: Boolean indicating if streaming is in progress
    func isCurrentlyStreaming() -> Bool {
        return isStreaming
    }
    
    /// Resets the chat history
    func resetChat() {
        messages = []
    }
    
    /// Cancels any ongoing streaming request
    func cancelStream() {
        currentTask?.cancel()
        isStreaming = false
    }
    
    /// Streams a response from Ollama
    /// - Parameters:
    ///   - prompt: The user's prompt
    ///   - systemPrompt: Optional system prompt
    ///   - model: Model to use (defaults to gemma3:4b)
    ///   - options: Generation options
    ///   - onToken: Callback for each token received
    ///   - onComplete: Callback when streaming is complete
    ///   - onError: Callback for errors
    func streamResponse(
        prompt: String,
        systemPrompt: String? = nil,
        model: String? = nil,
        options: OllamaOptions = OllamaOptions(),
        onToken: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // Don't start a new stream if one is already in progress
        guard !isStreaming else {
            onError(NSError(domain: "OllamaAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "A streaming request is already in progress"]))
            return
        }
        
        isStreaming = true
        
        // Add user message to history
        let userMessage = OllamaMessage(role: "user", content: prompt)
        messages.append(userMessage)
        
        guard let url = URL(string: "\(baseURL)/chat") else {
            isStreaming = false
            onError(NSError(domain: "OllamaAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var requestBody: [String: Any] = [
            "model": model ?? defaultModel,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "stream": true
        ]
        
        // Add system prompt if provided
        if let systemPrompt = systemPrompt {
            requestBody["system"] = systemPrompt
        }
        
        // Add options
        let optionsDict = options.toDictionary()
        for (key, value) in optionsDict {
            requestBody[key] = value
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            isStreaming = false
            onError(error)
            return
        }
        
        var fullResponse = ""
        
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isStreaming = false
                    onError(error)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isStreaming = false
                    onError(NSError(domain: "OllamaAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                }
                return
            }
            
            // Process the streamed data
            let responseString = String(decoding: data, as: UTF8.self)
            let lines = responseString.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            for line in lines {
                do {
                    if let jsonData = line.data(using: .utf8),
                       let response = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let done = response["done"] as? Bool {
                        
                        if let messageDict = response["message"] as? [String: Any],
                           let content = messageDict["content"] as? String {
                            
                            DispatchQueue.main.async {
                                onToken(content)
                                fullResponse += content
                            }
                        }
                        
                        if done {
                            // Add assistant message to history
                            if !fullResponse.isEmpty {
                                self.messages.append(OllamaMessage(role: "assistant", content: fullResponse))
                            }
                            
                            DispatchQueue.main.async {
                                self.isStreaming = false
                                onComplete(fullResponse)
                            }
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isStreaming = false
                        onError(error)
                    }
                }
            }
        }
        
        currentTask?.resume()
    }
    
    /// Sends a non-streaming request to Ollama
    /// - Parameters:
    ///   - prompt: The user's prompt
    ///   - systemPrompt: Optional system prompt
    ///   - model: Model to use (defaults to gemma3:4b)
    ///   - options: Generation options
    ///   - completion: Callback with result
    func generateResponse(
        prompt: String,
        systemPrompt: String? = nil,
        model: String? = nil,
        options: OllamaOptions = OllamaOptions(),
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard !isStreaming else {
            completion(.failure(NSError(domain: "OllamaAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "A streaming request is already in progress"])))
            return
        }
        
        // Add user message to history
        let userMessage = OllamaMessage(role: "user", content: prompt)
        messages.append(userMessage)
        
        guard let url = URL(string: "\(baseURL)/chat") else {
            completion(.failure(NSError(domain: "OllamaAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var requestBody: [String: Any] = [
            "model": model ?? defaultModel,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "stream": false
        ]
        
        // Add system prompt if provided
        if let systemPrompt = systemPrompt {
            requestBody["system"] = systemPrompt
        }
        
        // Add options
        let optionsDict = options.toDictionary()
        for (key, value) in optionsDict {
            requestBody[key] = value
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "OllamaAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let messageDict = json["message"] as? [String: Any],
                   let content = messageDict["content"] as? String {
                    
                    // Add assistant message to history
                    self.messages.append(OllamaMessage(role: "assistant", content: content))
                    
                    DispatchQueue.main.async {
                        completion(.success(content))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "OllamaAPI", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

// MARK: - Usage Example
/*
 // Example usage:
 let ollama = OllamaAPI()
 
 // Check if Ollama is reachable
 ollama.isOllamaReachable { isReachable in
     if isReachable {
         print("Ollama server is reachable")
         
         // Check if model exists
         ollama.doesModelExist(model: "gemma3:4b") { exists in
             if exists {
                 print("Model exists")
                 
                 // Stream a response
                 let options = OllamaOptions(temperature: 0.8, topP: 0.95)
                 ollama.streamResponse(
                     prompt: "Tell me a short story",
                     systemPrompt: "You are a helpful assistant",
                     options: options,
                     onToken: { token in
                         print("Token: \(token)", terminator: "")
                     },
                     onComplete: { fullResponse in
                         print("\nComplete response: \(fullResponse)")
                     },
                     onError: { error in
                         print("Error: \(error.localizedDescription)")
                     }
                 )
             } else {
                 print("Model does not exist")
             }
         }
     } else {
         print("Ollama server is not reachable")
     }
 }
 */
