import Foundation

//@main
struct Testing {
    static var model: Inference?  // ✅ Store `model` as a static property

    static func runInference() {
        guard let model = model else {
            print("❌ Model is not initialized yet")
            return
        }
        
//        model.streamResponse(prompt: "Wassup cute", onToken: { token in
//            print("TOKEN: \(token)")
//            fflush(stdout)
//        }, onComplete: { response in
//            print("FULL RESPONSE: \(response)")
//            CFRunLoopStop(CFRunLoopGetCurrent())  // Stop the RunLoop when complete
//        }, onError: { err in
//            print("❌ Received Error: \(err)")
//            CFRunLoopStop(CFRunLoopGetCurrent())
//        })
        
        model.generateResponse(prompt: "Wassup Cutie") { result in
            switch result {
            case .success(let responseText):
                print("RESPONSE TEXT: \(responseText)")
            case .failure(let error):
                print("❌ Error generating response: \(error.localizedDescription)")
            }
        }
    }
    
    static func main() {
        model = Inference(completion: { result in
            print("✅ SETUP COMPLETE")
            print(result)
            
            runInference()  // ✅ Now this can access `model`
        })
        
        // Prevent the program from exiting immediately
        CFRunLoopRun()
    }
}
