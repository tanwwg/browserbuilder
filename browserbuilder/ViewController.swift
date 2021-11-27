//
//  ViewController.swift
//  unitefree
//
//  Created by Tan Thor Jen on 11/27/21.
//

import Cocoa
import WebKit

class ViewController: NSViewController, WKNavigationDelegate {
    
    @IBOutlet var webView: WKWebView!
    
    private var progressKvo: NSKeyValueObservation?
    private var titleKvo: NSKeyValueObservation?
    
    let progressToolbarItemId = NSToolbarItem.Identifier(rawValue: "progress")
    
    func setProgressDisplay(indicator: NSProgressIndicator, value: Double) {
        indicator.doubleValue = value
        indicator.isHidden = value >= 1.0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progressKvo = webView.observe(\WKWebView.estimatedProgress, options: .new) { _, change in
            if let v = change.newValue,
               let tb = self.view.window?.toolbar,
               let itv = tb.items.first(where: { it in it.itemIdentifier == self.progressToolbarItemId}),
               let pv  = itv.view as? NSProgressIndicator {
                self.setProgressDisplay(indicator: pv, value: v)
            }
        }
        
        self.titleKvo = webView.observe(\WKWebView.title, options: .new) { _, change in
            if let v = change.newValue, let vv = v, let w = self.view.window {
                w.title = vv
            }
        }
        
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_0_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15"
        
        webView.navigationDelegate = self
        
        if let u = self.representedObject as? URL {
            webView.load(URLRequest(url: u))
        } else {
            self.goHome(self)
        }

    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void)
    {

        if navigationAction.shouldPerformDownload {
            decisionHandler(.download, preferences)
            return
        }
                
        if navigationAction.navigationType == .linkActivated && NSEvent.modifierFlags.contains(.command),
            let u = navigationAction.request.url
        {
            decisionHandler(.cancel, preferences)
            self.openNewTab(url: u)
            return
        }
        
        decisionHandler(.allow, preferences)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }
    
    @IBAction func goHome(_ sender: Any?) {
        if let plistUrl = Bundle.main.url(forResource: "defaults", withExtension: "plist"),
           let plist = NSDictionary(contentsOf: plistUrl),
           let url = plist["defaultUrl"] as? String,
           let u = URL(string: url) {
            webView.load(URLRequest(url: u))
        } else {
            let html = Bundle.main.url(forResource: "index", withExtension: "html")!
            webView.loadFileURL(html, allowingReadAccessTo: Bundle.main.bundleURL)
        }
    }
    
    func openNewTab(url: URL?) {
        guard let vc = self.storyboard?.instantiateInitialController() as? NSWindowController else { return }
        
        if let w = self.view.window, let neww = vc.window, let vc = neww.contentViewController {
            vc.representedObject = url
            w.addTabbedWindow(neww, ordered: .above)
            
            if url == nil {
                neww.makeKeyAndOrderFront(self)
            }
        }
    }
    
    @IBAction func newTab(_ sender: Any?) {
        self.openNewTab(url: nil)
    }

    @IBAction override func newWindowForTab(_ sender: Any?) {
        self.newTab(sender)
    }
    
    override var representedObject: Any? {
        didSet {
            if let u = representedObject as? URL {
                webView.load(URLRequest(url: u))
            }
        }
    }


}

