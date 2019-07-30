//
//  SPMarkdownPreviewViewController.m
//  Simplenote
//
//  Created by James Frost on 01/10/2015.
//  Copyright © 2015 Automattic. All rights reserved.
//

#import "SPMarkdownPreviewViewController.h"
#import "SPMarkdownParser.h"
#import "UIBarButtonItem+Images.h"
#import "UIDevice+Extensions.h"
#import "Simplenote-Swift.h"

@import WebKit;
@import SafariServices;

@interface SPMarkdownPreviewViewController ()<WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation SPMarkdownPreviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Preview", @"Title of Markdown preview screen");
    
    [self configureWebView];
    [self applyStyle];
    [self displayMarkdown];
}

- (void)configureWebView
{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKPreferences *prefs = [[WKPreferences alloc] init];
    prefs.javaScriptEnabled = NO;
    config.preferences = prefs;
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:config];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:webView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(webView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[webView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    if ([webView respondsToSelector:@selector(allowsLinkPreview)]) {
        webView.allowsLinkPreview = YES;
    }
    
    webView.navigationDelegate = self;
    
    self.webView = webView;
}

- (void)applyStyle
{
    UIColor *backgroundColor = [UIColor colorWithName:UIColorNameBackgroundColor];
    
    self.view.backgroundColor = backgroundColor;
    self.webView.backgroundColor = backgroundColor;
    self.webView.opaque = NO;

    UIBarButtonItem *backButton = [UIBarButtonItem backBarButtonWithTitle:NSLocalizedString(@"Back", @"Title of Back button for Markdown preview")
                                                                    target:self
                                                                    action:@selector(backButtonAction:)];

    if ([UIDevice isPad]) {
        // iPad needs extra padding on the left for the back button to align with previous screens
        self.navigationItem.leftBarButtonItems = @[ [UIBarButtonItem barButtonFixedSpaceWithWidth:4], backButton ];
    } else {
        self.navigationItem.leftBarButtonItem = backButton;
    }
}

- (void)displayMarkdown
{
    NSString *html = [SPMarkdownParser renderHTMLFromMarkdownString:self.markdownText];

    [self.webView loadHTMLString:html
                         baseURL:[[NSBundle mainBundle] bundleURL]];
}

#pragma mark - IBActions

- (IBAction)backButtonAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL* targetURL = navigationAction.request.URL;
    NSURL* bundleURL = NSBundle.mainBundle.bundleURL;
    BOOL isAnchorURL = targetURL != nil && [targetURL.absoluteString containsString:bundleURL.absoluteString];

    /// Detect scenarios such as markdown/#someInternalLink
    ///
    if (navigationAction.navigationType != WKNavigationTypeLinkActivated || isAnchorURL) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    if ([SFSafariViewController class]) {
        SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:targetURL];
        [self presentViewController:sfvc animated:YES completion:nil];
    } else {
        [[UIApplication sharedApplication] openURL:targetURL options:@{} completionHandler:nil];
    }

    decisionHandler(WKNavigationActionPolicyCancel);
}

#pragma mark - Traits

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

#if XCODE11
    if (@available(iOS 13.0, *)) {
        if ([previousTraitCollection hasDifferentColorAppearanceComparedToTraitCollection:self.traitCollection] == false) {
            return;
        }

        [self displayMarkdown];
    }
#endif
}

@end
