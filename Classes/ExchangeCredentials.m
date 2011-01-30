/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import "ExchangeCredentials.h"
#import "OAMutableURLRequest.h"
#import "OARequestParameter.h"
#import "OADataFetcher.h"
#import "OAConsumer.h"
#import "APIKeys.h"

@interface ExchangeCredentials (Private)
- (void)requestTokenThread:(id)obj;
- (void)serviceTicket:(OAServiceTicket*)ticket didFailWithError:(NSError*)error;
- (void)serviceTicket:(OAServiceTicket*)ticket finishedWithData:(NSData*)data;
@end

@implementation ExchangeCredentials

@synthesize consumer, username, password, delegate, token, error;

- (id)initWithDelegate:(id<ExchangeCredentialsDelegate>)del username:(NSString*)u password:(NSString*)p {
	if ((self = [super init])) {
		self.delegate = del;
		self.username = u;
		self.password = p;
		consumer = [[OAConsumer alloc] initWithKey:kTwitterKey secret:kTwitterSecret];
	}
	return self;
}

- (void)requestToken {
	[NSThread detachNewThreadSelector:@selector(requestTokenThread:) toTarget:self withObject:nil];
}

- (void)requestTokenThread:(id)obj {

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
		consumer:consumer
		token:nil					// we don't have a token yet
		realm:nil					// our service provider doesn't specify a realm
		signatureProvider:nil] ;	// use the default method, HMAC-SHA1
	
	NSString *esc_pass = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self.password, NULL, (CFStringRef)@":/?&@=+$~#", kCFStringEncodingUTF8);
	
	NSString *encodedPars = [NSString stringWithFormat:@"x_auth_mode=client_auth&x_auth_username=%@&x_auth_password=%@", self.username, esc_pass];
	NSData *postData = [encodedPars dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
	[esc_pass release];
	
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:postData];
	[request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setTimeoutInterval:20.0];
	
	OADataFetcher *dataFetcher = [[OADataFetcher alloc] init];
	[dataFetcher fetchDataWithRequest:request delegate:self didFinishSelector:@selector(serviceTicket:finishedWithData:) didFailSelector:@selector(serviceTicket:didFailWithError:)];
	[dataFetcher release];
	[request release];
	
	[pool release];
}

- (void)serviceTicket:(OAServiceTicket*)ticket didFailWithError:(NSError*)err {
	if (err == nil) {
		self.error = [NSError errorWithDomain:@"Unknown error" code:0 userInfo:nil];
	} else {
		self.error = err;
	}
	if (self.delegate) {
		[self.delegate performSelectorOnMainThread:@selector(credentialFailed:) withObject:self waitUntilDone:NO];
	}
}

- (void)serviceTicket:(OAServiceTicket*)ticket finishedWithData:(NSData*)data {

	if (ticket.didSucceed && data != nil) {
		NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (dataString) {
			self.token = [NSString stringWithString:dataString];
			if (self.delegate) {
				[self.delegate performSelectorOnMainThread:@selector(credentialSucceeded:) withObject:self waitUntilDone:NO];
			}
			[dataString release];
			return;
		}
	}
	[self serviceTicket:ticket didFailWithError:nil];
}

- (void)dealloc {
	[consumer release];
	[username release];
	[password release];
	[token release];
	[error release];
	[super dealloc];
}

@end
