//
//  PdfPreview.swift
//  CIE ID
//

import Foundation

@objc
class PdfPreview : NSObject
{
    var filePath : String
    var signImagePath : String
    var prView : NSView
    var iVPdfPreview : NSImageView
    var signPicture : MovableImageView
    var pageNumber : Int
    var pdfNumPages : Int
    var pdfImageRep : NSPDFImageRep
    
//    let tmpImg = NSImage.init()
//    tmpImg.addRepresentation(pdfImageRep)
    
    /*
    private lazy var tmpImg: NSImage = {
        let img = NSImage.init()
        img.addRepresentation(pdfImageRep)
        return img
    }()
    */
    
    @objc
    init(prImageView : NSView, pdfPath : String, signImagePath : String)
    {
        self.signImagePath = signImagePath
        self.filePath = pdfPath
        self.prView = prImageView
        self.pageNumber = 0
        
        do {
            let pdfData : NSData  = try NSData.init(contentsOfFile: self.filePath)
            self.pdfImageRep = NSPDFImageRep.init(data: pdfData as Data)!
            self.pdfNumPages = self.pdfImageRep.pageCount
        }
        catch{
            self.pdfNumPages = 0
            self.pdfImageRep = NSPDFImageRep.init()
            print("Unexpected error: \(error)")
        }

        let signImage = NSImage.init(contentsOfFile: self.signImagePath)
        
        self.signPicture = MovableImageView.init(image: signImage!)
        self.signPicture.frame = NSMakeRect(0, 0, 80, 25)
        self.signPicture.wantsLayer = true
        self.signPicture.layer?.borderWidth = 1
        self.signPicture.layer?.borderColor = NSColor.gray.cgColor
        
        
        self.iVPdfPreview = NSImageView.init()
        
        self.iVPdfPreview.imageScaling = .scaleAxesIndependently
        
        self.iVPdfPreview.addSubview(signPicture)
        
        super.init()
        setupDimensions()
        self.showPreview()
        
    }
    
    func getWhiteImage(transparentImage : NSImage) -> NSImage
    {
        let newImage = NSImage.init(size: transparentImage.size)
        newImage.lockFocus()
        NSColor.white.set()
        let rc = NSMakeRect(0, 0, newImage.size.width, newImage.size.height)
        rc.fill()
        transparentImage.draw(in : rc)
        newImage.unlockFocus()
        
        return newImage;
    }
    
    
    func setupDimensions() {
        
        let tmpImg = getCurrentImage()

        self.prView.wantsLayer = true
        self.prView.needsLayout = true
        self.prView.needsDisplay = true
        
        
        let width = self.prView.frame.size.width
        let height = self.prView.frame.size.height
        
        var img_height = height
        var img_width = width

        if(tmpImg.size.width > tmpImg.size.height)
        {
            img_height = (width*tmpImg.size.height)/tmpImg.size.width
            
            if img_height > height {
                img_width = (height*tmpImg.size.width)/tmpImg.size.height
                img_height = (img_width*tmpImg.size.height)/tmpImg.size.width
            }
            
        }else
        {
            img_width = (height*tmpImg.size.width)/tmpImg.size.height
            
            if img_width > width {
                img_height = (width*tmpImg.size.height)/tmpImg.size.width
                img_width = (img_height*tmpImg.size.width)/tmpImg.size.height
            }
        }
        
        self.iVPdfPreview.translatesAutoresizingMaskIntoConstraints = false

        self.prView.addSubview(self.iVPdfPreview)
        
        self.prView.addConstraint(NSLayoutConstraint(item: self.prView, attribute: .centerX, relatedBy: .equal, toItem: self.iVPdfPreview, attribute: .centerX, multiplier: 1, constant: 0))
        self.prView.addConstraint(NSLayoutConstraint(item: self.prView, attribute: .centerY, relatedBy: .equal, toItem: self.iVPdfPreview, attribute: .centerY, multiplier: 1, constant: 0))
        self.prView.addConstraint(NSLayoutConstraint(item: self.iVPdfPreview, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: img_height))
        self.prView.addConstraint(NSLayoutConstraint(item: self.iVPdfPreview, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: img_width))
        
        self.prView.updateLayer()
        self.prView.updateConstraints()
    }
    
    
    
    func getCurrentImage() -> NSImage {
        pdfImageRep.currentPage = pageNumber
        
        let img = NSImage.init()
        img.addRepresentation(pdfImageRep)

        return getWhiteImage(transparentImage: img)
    }
    
    
    func showPreview()
    {
        self.iVPdfPreview.image = getCurrentImage()
    }
    
    @objc
    func pageUp()
    {
        if((self.pageNumber - 1) >= 0)
        {
            self.pageNumber -= 1;
        }
        
        self.showPreview()
    }
    
    @objc
    func pageDown()
    {
        if(self.pdfNumPages >= self.pageNumber + 1)
        {
            self.pageNumber += 1;
        }
        
        self.showPreview()
    }
    
    @objc
    func getSignImageInfos() -> [Float]
    {
        var infos = [Float]()
        
        let x = (Float)(signPicture.frame.origin.x / iVPdfPreview.bounds.size.width)
        let y = 1.0 - ((Float)(signPicture.frame.origin.y / iVPdfPreview.bounds.size.height))
        let w = (Float)(signPicture.frame.size.width / iVPdfPreview.bounds.size.width)
        let h = (Float)((signPicture.frame.size.height) / iVPdfPreview.bounds.size.height)
        
        print("x: \(x), y: \(y), w: \(w), h: \(h)")
        
        infos.append(x)
        infos.append(y)
        infos.append(w)
        infos.append(h)
        
        return infos
    }
    
    @objc
    func getSelectedPage() -> Int
    {
        return pageNumber
    }
    
}

/*
 class PdfPreview

 public void showPreview()
 {
     var proc1 = new Process
     {
         StartInfo = new ProcessStartInfo
         {
             FileName = mutoolPath,
             //Arguments = string.Format("{0} {1} {2} {3} {4} {5} {6} {7}", "draw -o", "page%d.png", "-w", 271, "-h", 332, file_name, 1),
             Arguments = string.Format("{0} {1} \"{2}\" {3}", "draw -o", tmpFolderName + "\\page%d.png", filePath, pageNumber),
             UseShellExecute = false,
             RedirectStandardOutput = true,
             CreateNoWindow = true
         }
     };
     
     string img_file_name = string.Format("{0}\\page{1}.png", tmpFolderName, pageNumber);

     if (!File.Exists(img_file_name))
     {
         proc1.Start();
         proc1.WaitForExit();
     }

     Image img = Image.FromFile(img_file_name);
     if(img.Width > img.Height)
     {
         pbPdfPreview.Width = pbPdfPreview.Parent.Width - 10;
         pbPdfPreview.Height = pbPdfPreview.Parent.Height;
         pbPdfPreview.Left = 5;
         pbPdfPreview.Top = 0;
     }
     else
     {
         pbPdfPreview.Width = (pbPdfPreview.Parent.Width)/2;
         pbPdfPreview.Height = pbPdfPreview.Parent.Height;
         pbPdfPreview.Left = (pbPdfPreview.Parent.Width) / 4;
         pbPdfPreview.Top = 0;
     }

     Bitmap croppedImage = new Bitmap(img, pbPdfPreview.Width, pbPdfPreview.Height);
     pbPdfPreview.Image = croppedImage;
     pbPdfPreview.SendToBack();
 }

     public int getPdfPages()
     {
         return this.pdfNumPages;
     }

     public string getSignImagePath()
     {
         return signImagePath;
     }

     public int getPdfPageNumber()
     {
         return this.pageNumber;
     }



     public void pdfPreviewRemoveObjects()
     {
         this.signPicture.Hide();
         this.pbPdfPreview.Controls.Remove(signPicture);
         this.pbPdfPreview.Hide();
         this.prPanel.Controls.Remove(pbPdfPreview);
     }

     public Dictionary<string,float> getSignImageInfos()
     {
         Dictionary<string, float> signImageInfo = new Dictionary<string, float>();

         //X, Y, Width e Height signImage
         //page number

         float x = (float)signPicture.Left / (float)pbPdfPreview.Width;
         float y = (float)(signPicture.Bottom) / (float)pbPdfPreview.Height;
         float w = ((float)signPicture.Width / (float)pbPdfPreview.Width);
         float h = ((float)signPicture.Height / (float)pbPdfPreview.Height);

         signImageInfo["x"] = x;
         signImageInfo["y"] = y;
         signImageInfo["w"] = w;
         signImageInfo["h"] = h;
         signImageInfo["pageNumber"] = pageNumber - 1;

         return signImageInfo;
     }

     public void pageUp()
     {
         if (pageNumber - 1 >= 1)
         {
             pageNumber -= 1;
         }

         showPreview();
     }

     public void pageDown()
     {
         if (this.pdfNumPages >= pageNumber + 1)
         {
             pageNumber += 1;
         }

         showPreview();
     }

     public void freeTempFolder()
     {
         System.GC.Collect();
         System.GC.WaitForPendingFinalizers();

         string[] Files = Directory.GetFiles(tmpFolderName);

         string prefix = ".png";

         foreach (string file in Files)
         {
             if (file.ToLower().Contains(prefix))
             {
                 File.Delete(file);
             }
         }
     }



 }
 */
