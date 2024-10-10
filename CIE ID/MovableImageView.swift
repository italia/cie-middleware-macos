//
//  MovableImageView.swift
//  PdfPreview
//
//

import Foundation
import SwiftUI

@objc
class MovableImageView: NSImageView {

    var firstMouseDownPoint: NSPoint = NSZeroPoint

        
    @objc
    init(image : NSImage) {
        super.init(frame: NSZeroRect)
        self.wantsLayer = true
        //self.layer?.backgroundColor = NSColor.red.cgColor
        self.image = image
    }
        
    @objc
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

    }

    @objc
    override func mouseDown(with event: NSEvent) {
        firstMouseDownPoint = (self.window?.contentView?.convert(event.locationInWindow, to: self))!
    }
        
    @objc
    override func mouseDragged(with event: NSEvent) {
        let newPoint = (self.window?.contentView?.convert(event.locationInWindow, to: self))!

        let offset = NSPoint(x: newPoint.x - firstMouseDownPoint.x, y: newPoint.y - firstMouseDownPoint.y)
        
        let origin = self.frame.origin
        let size = self.frame.size
        
        
        //Swift.print("x: %d, y: %d", origin.x + offset.x, origin.y + offset.y);
        var x = origin.x + offset.x;
        var y = origin.y + offset.y;
        
        if(x < 0)
        {
            x = 0;
        }
        if(y < 0)
        {
            y = 0;
        }
        
        if(x > ((self.superview?.bounds.width)! - self.frame.width) )
        {
            x = (self.superview?.bounds.width)! - self.frame.width;
        }
        
        if(y > ((self.superview?.bounds.height)! - self.frame.height) )
        {
            y = (self.superview?.bounds.height)! - self.frame.height;
        }
        
        self.frame = NSRect(x: x, y: y, width: size.width, height: size.height)
        
    }
        
}
