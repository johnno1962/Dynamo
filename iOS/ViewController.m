//
//  ViewController.m
//  DynamoIOS
//
//  Created by John Holdsworth on 20/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

#import "ViewController.h"
#import "Dynamo-Swift.h"

@interface ViewController ()
@property IBOutlet UIWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    id logger = ^ ( NSString *trace ) {
        NSLog( @"%@", trace );
    };

    NSArray *swiftlets = @[
        [[DynamoExampleAppSwiftlet alloc] initWithPathPrefix:@"/example"],
        [[DynamoSessionSwiftlet alloc] initWithPathPrefix:@"/ticktacktoe"
                                                 appClass:[TickTackToeSwiftlet class] cookieName: @"TTT"],
        [[DynamoSessionSwiftlet alloc] initWithPathPrefix:@"/NumberGuesser.ssp"
                                                 appClass:[NumberGuesserSwiftlet class] cookieName: @"NUM"],
        [[DynamoSSLProxySwiftlet alloc] initWithLogger:logger],
        [[DynamoProxySwiftlet alloc] initWithLogger:logger],
        [[DynamoDocumentSwiftlet alloc] init]
     ];

    (void)[[DynamoWebServer alloc] initWithPortNumber:8080 swiftlets:swiftlets localhostOnly:YES];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8080"]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
