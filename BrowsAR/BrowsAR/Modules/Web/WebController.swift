//
//  WebController.swift
//  BrowsAR
//
//  Created by mbarosevic on 26.08.2021..
//

import WebKit

class WebView: UIView, UITextFieldDelegate, WKNavigationDelegate{
  
    static let webView = WKWebView()
    let webViewNode: WebViewNode
  
    init(node: WebViewNode) {
        webViewNode = node

        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 360, height: 480)))

        setupViews()
        setupHierarchy()
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    private func setupViews() {
        WebView.webView.load(URLRequest(url: URL(string: "https://www.google.com")!))
        WebView.webView.allowsBackForwardNavigationGestures = true
    }
  
    private func setupHierarchy() {
        addSubview(WebView.webView)
    }
  
    private func setupLayout() {
        WebView.webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            WebView.webView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            WebView.webView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            WebView.webView.topAnchor.constraint(equalTo: self.topAnchor, constant: 50),
            WebView.webView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}

extension WebView {
    func didTapCLose() {
        removeFromSuperview()
        webViewNode.removeFromParentNode()
    }

    func didTapBack() {
        print("tapped BACK button")
        if WebView.webView.canGoBack {
            WebView.webView.goBack()
        }
    }

    func didTapReturn(with urlRequest: URLRequest) {
        WebView.webView.load(urlRequest)
    }
}



