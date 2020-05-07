//  SwiftyCMSDecoder.swift
//
//  MIT License
//
//  Copyright (c) 2018 James Sherlock https://twitter.com/JamesSherlouk/
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

/// Source: https://github.com/Sherlouk/SwiftProvisioningProfile
/// Swift wrapper around Apple's Security `CMSDecoder` class
final class SwiftyCMSDecoder {

    var decoder: CMSDecoder

    /// Initialises a new `SwiftyCMSDecoder` which in turn creates a new `CMSDecoder`
    init?() {
        var newDecoder: CMSDecoder?
        CMSDecoderCreate(&newDecoder)

        guard let decoder = newDecoder else {
            return nil
        }

        self.decoder = decoder
    }

    /// Feed raw bytes of the message to be decoded into the decoder. Can be called multiple times.
    ///
    /// - Parameter data: The raw data you want to have decoded
    /// - Returns: Success - `false` upon detection of improperly formatted CMS message.
    @discardableResult
    func updateMessage(data: NSData) -> Bool {
        return CMSDecoderUpdateMessage(decoder, data.bytes, data.length) != errSecUnknownFormat
    }

    /// Indicate that no more `updateMessage()` calls are coming; finish decoding the message.
    ///
    /// - Returns: Success - `false` upon detection of improperly formatted CMS message.
    @discardableResult
    func finaliseMessage() -> Bool {
        return CMSDecoderFinalizeMessage(decoder) != errSecUnknownFormat
    }

    /// Obtain the actual message content (payload), if any. If the message was signed with
    /// detached content then this will return `nil`.
    ///
    /// - Warning: This cannot be called until after `finaliseMessage()` is called!
    var data: Data? {
        var newData: CFData?
        CMSDecoderCopyContent(decoder, &newData)
        return newData as Data?
    }
}
