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

    NSMutableArray *processors = [NSMutableArray new];
    [processors addObject:[[DynamoExampleAppProcessor alloc] initWithPathPrefix:@"/example"]];
    [processors addObject:[[DynamoSessionProcessor alloc] initWithPathPrefix:@"/ticktacktoe"
                                                                    appClass:[TickTackToeProcessor class] cookieName: @"TTT"]];
    [processors addObject:[[DynamoSessionProcessor alloc] initWithPathPrefix:@"/NumberGuesser.ssp"
                                                                    appClass:[NumberGuesserProcessor class] cookieName: @"NUM"]];
    [processors addObject:[[DynamoSSLProxyProcessor alloc] initWithLogger:logger]];
    [processors addObject:[[DynamoProxyProcessor alloc] initWithLogger:logger]];
    [processors addObject:[[DynamoDocumentProcessor alloc] init]];

    (void)[[DynamoWebServer alloc] initWithPortNumber:8080 processors:processors localhostOnly:YES];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8080"]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
