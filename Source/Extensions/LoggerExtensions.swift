//
//  LoggerExtensions.swift
//  PPPC Utility
//
//  Created by Skyler Godfrey on 10/21/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

// This extension simplifies the logger instance creation by calling the bundle Id
// and pre-declaring categories. Currently the predefined categories match the
// class name. 

import OSLog

extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier!
    static let TCCProfileViewController = Logger(subsystem: subsystem, category: "TCCProfileViewController")
    static let PPPCServicesManager = Logger(subsystem: subsystem, category: "PPPCServicesManager")
    static let Model = Logger(subsystem: subsystem, category: "Model")
    static let SaveViewController = Logger(subsystem: subsystem, category: "SaveViewController")
    static let UploadInfoView = Logger(subsystem: subsystem, category: "UploadInfoView")
    static let UploadManager = Logger(subsystem: subsystem, category: "UploadManager")
}
