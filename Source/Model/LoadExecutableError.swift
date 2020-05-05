//
//  LoadExecutableError.swift
//  PPPC Utility
//
//  Created by Andrew Pirkl on 5/4/20.
//  Copyright © 2020 Jamf. All rights reserved.
//

import Foundation
public enum LoadExecutableError: Error {
    case identifierNotFound
    case resourceURLNotFound
    case codeRequirementError(description: String)
    case executableNotFound
    case executableAlreadyExists
}

extension LoadExecutableError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .identifierNotFound:
            return "Bundle identifier could not load."
        case .resourceURLNotFound:
            return "Resource URL could not be loaded from bundle."
        case .codeRequirementError(let description):
            return "Failed to get designated requirement with error: \(description)"
        case .executableNotFound:
            return "Could not find executable from url path"
        case .executableAlreadyExists:
            return "The executable is already loaded."
        }
    }
}
