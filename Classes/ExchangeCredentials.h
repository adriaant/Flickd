/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import "ExchangeCredentials.h"

@class OAConsumer;

@protocol ExchangeCredentialsDelegate;

@interface ExchangeCredentials : NSObject {
	NSString	*username;
	NSString	*password;
	NSString	*token;
	NSError		*error;
	OAConsumer	*consumer;

	id<ExchangeCredentialsDelegate>	delegate;
}

@property(nonatomic,retain) NSString *username, *password, *token;
@property(nonatomic,retain) NSError *error;
@property(nonatomic,retain) OAConsumer *consumer;
@property(nonatomic,assign) id delegate;

- (id)initWithDelegate:(id<ExchangeCredentialsDelegate>)del username:(NSString*)u password:(NSString*)p;
- (void)requestToken;

@end

@protocol ExchangeCredentialsDelegate 

@required
- (void)credentialFailed:(ExchangeCredentials*)credential;
- (void)credentialSucceeded:(ExchangeCredentials*)credential;
@end
