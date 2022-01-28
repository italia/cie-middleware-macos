//  DropView.swift
//


import Foundation
import SwiftUI


class DropView: NSView {

    var filePath: String?

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        
    
        self.wantsLayer = true
        self.needsLayout = true
        self.needsDisplay = true
        self.updateConstraints()

        registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
        
        // dash customization parameters
        let dashHeight: CGFloat = 3
        let dashLength: CGFloat = 10
        let dashColor: NSColor = .gray
        
        // setup the context
        let currentContext = NSGraphicsContext.current!.cgContext
        currentContext.setLineWidth(dashHeight)
        currentContext.setLineDash(phase: 0, lengths: [dashLength])
        currentContext.setStrokeColor(dashColor.cgColor)

        // draw the dashed path
        currentContext.addRect(bounds.insetBy(dx: dashHeight, dy: dashHeight))
        currentContext.strokePath()
        
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        
        self.layer?.backgroundColor = NSColor.lightGray.cgColor
        return .copy
        
    }

    
    fileprivate func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        guard let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = board[0] as? String
        else { return false }

        var suffix = URL(fileURLWithPath: path).pathExtension
        
        
        return true;
        
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.backgroundColor = NSColor.white.cgColor
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.layer?.backgroundColor = NSColor.white.cgColor
        //ChangeView.getInstance().showSubView(viewIndex.SELECT_OP_PAGE)

    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = pasteboard[0] as? String
        else { return false }

        self.filePath = path
        
        self.goToSelectOpPage(path: path)
        return true
    }
    
    func goToSelectOpPage(path:String)
    {
        let cV = ChangeView.getInstance().getView(viewIndex.SELECT_OP_PAGE) as NSView
        
        let text = cV.viewWithTag(1) as! NSTextField
        text.stringValue = path
        
        ChangeView.getInstance().showSubView(viewIndex.SELECT_OP_PAGE)
    }
}
