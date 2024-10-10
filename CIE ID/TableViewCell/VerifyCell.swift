//
//  VerifyCell.swift
//  CIE ID
//
//  Copyright © 2021 IPZS. All rights reserved.
//

import Foundation

@objc
class VerifyCell : NSTableCellView
{
    
    @IBOutlet weak var imageIcon: NSImageView!
    @IBOutlet weak var lblText: NSTextField!
    
    @objc
    func configure(with item : VerifyItem)
    {
        self.imageIcon.image = item.img
        self.lblText.stringValue = item.value
    
    }
}
