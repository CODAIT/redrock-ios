import UIKit

class LoadingView: UIView {
    var view: UIView!
    
    @IBOutlet weak var blockingView: UIView!
    @IBOutlet weak var holderView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        
        // Set alpha to 0 so we can fade in
        view.alpha = 0;
        addSubview(view)
        activityIndicator!.startAnimating()
        
        // Fade in
        UIView.animateWithDuration(0.2, animations: {
            self.view.alpha = 1
        })
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "LoadingView", bundle: bundle)
        
        // Assumes UIView is top level and only object in LoadingView.xib file
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
    func viewTapped() {
        self.removeFromSuperview()
    }
    
    override func removeFromSuperview() {
        // Fade out
        UIView.animateWithDuration(0.2, animations: {
            self.view.alpha = 0;
        }, completion: { finished in
            self.activityIndicator!.stopAnimating()
            // Can't call super directly from the closure
            self.superRemoveFromSuperview()
        })
    }
    
    func superRemoveFromSuperview() {
        super.removeFromSuperview()
    }
}
