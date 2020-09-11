//
//  Alert.swift
//  Prune
//
//  Created by Leslie Helou on 12/20/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

import Cocoa

class Alert: NSObject {
    func display(header: String, message: String) {
        DispatchQueue.main.async {
            let dialog: NSAlert = NSAlert()
            dialog.messageText = header
            dialog.informativeText = message
            dialog.alertStyle = NSAlert.Style.warning
            dialog.addButton(withTitle: "OK")
            dialog.runModal()
        }
    }   // func alert_dialog - end
}
