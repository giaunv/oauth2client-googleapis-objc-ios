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
static NSString * const kIDMOAuth2AccountType = @"Google API";

//token to look for in Googles response page
static NSString * const kIDMOAuth2SuccessPagePrefix = @"Success";


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *loginWebView;

@end

@implementation ViewController{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - OAuth2 Logic

- (void) setupOAuth2AccountStore{
    [[NXOAuth2AccountStore sharedStore] setClientID:kIDMOAuth2ClientId secret:kIDMOAuth2ClientSecret authorizationURL:kIDMOAuth2AuthorizationURL tokenURL:kIDMOAuth2TokenURL redirectURL:kIDMOAuth2RedirectURL forAccountType:kIDMOAuth2AccountType];
    
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

@end
