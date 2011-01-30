/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <Foundation/Foundation.h>
#import "FlickrCategory.h"

@class LFHTTPRequest;

@protocol FlickrDelegate;

@interface Flickr :NSObject {
@public
	id<FlickrDelegate>	delegate;
@private
	SEL					_selector;
	LFHTTPRequest		*httpRequest;
    NSString			*formDataFileName;
	NSString			*boundary;
}

@property(nonatomic,assign) id<FlickrDelegate> delegate;

- (id)initWithDelegate:(id<FlickrDelegate>)del;
- (void)verifyToken;
- (void)setSelector:(SEL)sel;
- (void)obtainToken;
- (void)initiateUpload:(NSDictionary*)data;

@end

@protocol FlickrDelegate <NSObject>
@required
- (void)loadUrlInWebView:(NSURL*)url;
- (void)uploadFinished:(NSString*)photoId;
- (void)uploadFailed:(NSString*)err;
- (void)setProgress:(float)val;
@end
