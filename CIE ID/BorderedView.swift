//  DropView.swift
//


import Foundation
import SwiftUI

@objc
class BorderedView: NSView {

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        
        self.layoutSubtreeIfNeeded()
        self.wantsLayer = true
        self.needsLayout = true
        self.needsDisplay = true
        self.updateConstraints()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
        
        self.layer?.cornerRadius = 8.0;
        self.layer?.borderColor = NSColor.gray.cgColor
        self.layer?.borderWidth = 2
        
    }

    
}
