//
//  ViewController.m
//  googleoauth2demo
//
//  Created by giaunv on 4/7/15.
//  Copyright (c) 2015 366. All rights reserved.
//

#import "ViewController.h"
#import "NXOAuth2.h"

//the following items were obtained when registering this app in the Google APIs Console
//these are all specific to the client application - e.g. this iOS app
static NSString * const kIDMOAuth2ClientId = @"157740772866-viioslkeann2edsg7bsdhml2gl285jd0.apps.googleusercontent.com";
static NSString * const kIDMOAuth2ClientSecret = @"wEiNgY9YBOtszDBM6lZ9BZxj";
//should be in the format of urn:xxx:yyy:zzz, not http://localhost
static NSString * const kIDMOAuth2RedirectURL = @"urn:ietf:wg:oauth:2.0:oob";

//these items were obtained from the Google API documentation
//https://developers.google.com/accounts/docs/OAuth2InstalledApp#overview
static NSString * const kIDMOAuth2AuthorizationURL = @"https://accounts.google.com/o/oauth2/auth";
static NSString * const kIDMOAuth2TokenURL = @"https://accounts.google.com/o/oauth2/token";

//these items were obtained from the Google API documentation
//https://developers.google.com/+/api/oauth
static NSString * const kIDMOAuth2Scope = @"https://www.googleapis.com/auth/userinfo.profile";

//this is just a unique name for the service we are accessing
static NSString * const kIDMOAuth2AccountType = @"Google+ API";

//token to look for in Googles response page
static NSString * const kIDMOAuth2SuccessPagePrefix = @"Success";


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *loginWebView;

@end

@implementation ViewController{
    
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // [self.loginWebView initWithFrame:self.view.frame];
    // self.loginWebView.scalesPageToFit = true;
    
    // Setup self as as delegate so we know when the UIWebView has loaded pages
    self.loginWebView.delegate = self;
    
    [self setupOAuth2AccountStore];
    [self requestOAuth2Access];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - OAuth2 Logic

- (void) setupOAuth2AccountStore{
    //these steps are docmented in the NXOAuth2Client readme.md
    //https://github.com/nxtbgthng/OAuth2Client
    //the values used are documented above along with their origin
    //[[NXOAuth2AccountStore sharedStore] setClientID:kIDMOAuth2ClientId secret:kIDMOAuth2ClientSecret scope:[NSSet setWithObject:kIDMOAuth2Scope] authorizationURL:[NSURL URLWithString:kIDMOAuth2AuthorizationURL] tokenURL:[NSURL URLWithString:kIDMOAuth2TokenURL] redirectURL:[NSURL URLWithString:kIDMOAuth2RedirectURL] forAccountType:kIDMOAuth2AccountType];
    
    NSDictionary *googleConfigDict = @{
                                       kNXOAuth2AccountStoreConfigurationClientID: kIDMOAuth2ClientId,
                                       kNXOAuth2AccountStoreConfigurationSecret: kIDMOAuth2ClientSecret,
                                       kNXOAuth2AccountStoreConfigurationScope: [NSSet setWithObjects:kIDMOAuth2Scope, nil],
                                       kNXOAuth2AccountStoreConfigurationAuthorizeURL: [NSURL URLWithString:kIDMOAuth2AuthorizationURL],
                                       kNXOAuth2AccountStoreConfigurationTokenURL: [NSURL URLWithString:kIDMOAuth2TokenURL],
                                       kNXOAuth2AccountStoreConfigurationRedirectURL: [NSURL URLWithString:kIDMOAuth2RedirectURL],
                                       kNXOAuth2AccountStoreConfigurationTokenType:kIDMOAuth2AccountType
                                       };
    [[NXOAuth2AccountStore sharedStore] setConfiguration:googleConfigDict forAccountType:kIDMOAuth2AccountType];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *aNotification){
        if (aNotification.userInfo) {
            // account added, we have access
            // we can now request protected data
            NSLog(@"Success!! We have an access token.");
        } else {
            // account removed, we lost access
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *aNotification){
            NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
            NSLog(@"Error!! %@", error.localizedDescription);
    }];
}

- (void) requestOAuth2Access {
    // in order to login to Google APIs using OAuth2 we must show an embedded browser (UI WebView)
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:kIDMOAuth2AccountType withPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
        // navigate to the URL returned by NXOAuth2Client
        [self.loginWebView loadRequest:[NSURLRequest requestWithURL:preparedURL]];
    }];
}

#pragma mark - UIWebViewDelegate methods

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    // If the UIWebView is showing our authorization URL, show the UIWebView control
    if ([webView.request.URL.absoluteString rangeOfString:kIDMOAuth2AuthorizationURL options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.loginWebView.hidden = NO;
    } else {
        // Otherwise hide the UIWebView, we've left the authorization flow
        self.loginWebView.hidden = YES;
        
        // Read the page title from the UIWebView, this is how Google APIs is returning the authorization code and relation information. This is controlled by the redirect URL we choose to use from Google APIs
        NSString *pageTile = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        
        // Continue the OAuth2 flow using the info from the page title
        [self handleOAuth2AccessResult:pageTile];
    }
}

- (void)handleOAuth2AccessResult:(NSString *)accessResult{
    // Parse the page title for success or failure
    BOOL success = [accessResult rangeOfString:kIDMOAuth2SuccessPagePrefix options:NSCaseInsensitiveSearch].location != NSNotFound;
    // If success, complete the OAuth2 flow by handling the redirect URL  and obtaining a token
    if (success) {
        // Authentication code and details are passed back in the form of a query string in the page title
        // Parse those arguments out
        NSString *arguments = accessResult;
        if ([arguments hasPrefix:kIDMOAuth2SuccessPagePrefix]) {
            arguments = [arguments substringFromIndex:kIDMOAuth2SuccessPagePrefix.length + 1];
        }
        
        // Append the arguments found in the page title to the redirect URL assigned by Google APIs
        NSString *redirectURL = [NSString stringWithFormat:@"%@?%@", kIDMOAuth2RedirectURL, arguments];
        
        // Finally, complete the flow by calling handleRedirectURL
        [[NXOAuth2AccountStore sharedStore] handleRedirectURL:[NSURL URLWithString:redirectURL]];
    } else {
        // Start over
        [self requestOAuth2Access];
    }
}

@end
