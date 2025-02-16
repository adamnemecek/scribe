
import Foundation
import Vision
import AppKit

func err(_ msg: String) -> Never {
    FileHandle.standardError.write(msg.data(using: .utf8)!)
    exit(1)
}


// Function to perform text recognition
// convert to async
func extractText(from image: CGImage, completion: @escaping ([String]) -> Void) {
    let textRequest = VNRecognizeTextRequest { request, error in
        guard error == nil,
              let observations = request.results as? [VNRecognizedTextObservation] else {
            err("Error performing text recognition: \(error?.localizedDescription ?? "Unknown error")")
        }
        
        let recognizedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        
        completion(recognizedText)
    }
    
    // Configure the request
    textRequest.recognitionLevel = .accurate
    textRequest.usesLanguageCorrection = true
    
    // Create request handler
    let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
    
    do {
        try requestHandler.perform([textRequest])
    } catch {
        err(error.localizedDescription)
    }
}

func main() {
    
    // Command line argument handling
    guard CommandLine.arguments.count == 1 else {
        err("Usage: textextract <image_path>")
    }

    let imagePath = CommandLine.arguments[1]

    // Load and process the image
    guard let image = NSImage(contentsOfFile: imagePath),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        err("Error: Unable to load image at path: \(imagePath)")
    }

    // Create a dispatch group to wait for async operation
    let group = DispatchGroup()
    group.enter()

    // Process the image and extract text
    extractText(from: cgImage) { recognizedText in
        if recognizedText.isEmpty {
            err("No text was recognized in the image.")
        }
        recognizedText.forEach { text in
            print(text)
        }
    
        group.leave()
    }

    // Wait for text recognition to complete
    group.wait()
}



main()
