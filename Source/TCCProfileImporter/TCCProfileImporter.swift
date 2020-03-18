//
//  TCCProfileImporter.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2019 Jamf Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

typealias TCCProfileImportResult = Result<TCCProfile, TCCProfileImportError>
typealias TCCProfileImportCompletion = ((TCCProfileImportResult) -> Void)

/// Load tcc profiles
public class TCCProfileImporter {

    // MARK: Load TCCProfile

    /// Mapping & Decoding tcc profile
    ///
    /// - Parameter fileUrl: path with a file to load, completion: TCCProfileImportCompletion - success with TCCProfile or failure with TCCProfileImport Error
    func decodeTCCProfile(fileUrl: URL, _ completion: @escaping TCCProfileImportCompletion) {
        let data: Data
        do {
            data = try Data(contentsOf: fileUrl)
        } catch {
            return completion(.failure(.unableToOpenFile))
        }

        do {
            // Note that parse will ignore the signing portion of the data
            let tccProfile = try TCCProfile.parse(from: data)
			return completion(.success(tccProfile))
        } catch TCCProfile.ParseError.failedToCreateData {
			return completion(.failure(.decodeProfileError))
        } catch TCCProfile.ParseError.failedToCreateDecoder {
			return completion(.failure(.decodeProfileError))
        }
        catch let DecodingError.keyNotFound(codingKey, _) {
            return completion(TCCProfileImportResult.failure(.invalidProfileFile(description: codingKey.stringValue)))
        } catch let DecodingError.typeMismatch(type, context) {
            let errorDescription = "Type \(type) mismatch: \(context.debugDescription) codingPath: \(context.codingPath)"
            return completion(.failure(.invalidProfileFile(description: errorDescription)))
        } catch let error as NSError {
            let errorDescription = error.userInfo["NSDebugDescription"] as? String
            return completion(.failure(.invalidProfileFile(description: errorDescription ?? error.localizedDescription)))
        }
    }
}
