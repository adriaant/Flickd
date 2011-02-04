/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <Foundation/Foundation.h>
#import <CFNetwork/CFHTTPMessage.h>
#import <CFNetwork/CFHTTPStream.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import "Flickr.h"
#import "APIKeys.h"
#import "LFHTTPRequest.h"

#include "Utilities.h"

@interface Flickr (Private)
- (void)requestPermission;
- (void)checkToken:(NSString*)token;
- (void)processToken:(NSData*)data;
- (void)obtainFrob;
- (void)processFrob:(NSData*)data;
- (void)buildData:(NSDictionary*)data;
- (void)submitData;
- (NSString*)parseUploadResponse:(NSString*)str error:(NSString**)errStr;
- (void)uploadError:(NSString*)str;
- (void)cleanUpTempFile;
- (NSString*)scanError:(NSScanner*)scanner;
@end

@implementation Flickr

@synthesize delegate;

/**
 * Allocate a Flickr instance with the given delegate.
 */
- (id)initWithDelegate:(id<FlickrDelegate>)del {
	if ((self = [super init])) {
		self.delegate = del;
		boundary = nil;
		formDataFileName = nil;
	}
	return self;
}

/**
 * Dispose of allocated resources.
 */
- (void)dealloc {
	[boundary release];
	[httpRequest release];
	[formDataFileName release];
	[super dealloc];
}

/**
 * Set the selector that will be used as callback on the delegate.
 */
- (void)setSelector:(SEL)sel {
	_selector = sel;
}

#pragma mark -
#pragma mark Authorization

/**
 * Verify if the user has authorized Flickr usage or whether previously
 * authorized tokens are still valid.
 */
- (void)verifyToken {
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	if ([settings stringForKey:@"frob"] == nil && [settings stringForKey:@"token"] == nil) {
		[self requestPermission];
	} else if ([settings stringForKey:@"frob"] != nil) {
		[self obtainToken];
	} else if ([settings stringForKey:@"token"] != nil) {
		[self checkToken:[settings stringForKey:@"token"]];
	}
}

/**
 * Pop up a dialog so the user can tell Flickr it's cool for us to upload pictures to their account.
 */
- (void)requestPermission {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission required" message:@"Flickd needs your authorization to upload pictures to Flickr. Authorization has to be obtained from Flickr via a web page." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Visit Flickr", nil];
	[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"sentToGetToken"];
	[alertView show];
	[alertView release];
}

/**
 * User dismissed an alert that we popped up when something 
 * during the communication with Flickr went wrong.
 */
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case 1:
			[self obtainFrob];
			break;
		default:
			exit(-1);  // Fail
			break;
	}
}

/**
 * Obtain the frob we need to get an authorized token.
 */
- (void)obtainFrob {
	NSString	*sigStr = [NSString stringWithFormat:@"%@api_key%@method%@", kFlickrSecret, kFlickrKey, @"flickr.auth.getFrob"];
	NSString	*sig = [sigStr md5HexHash];
	NSString	*urlStr = [NSString stringWithFormat:
		@"http://api.flickr.com/services/rest/?method=flickr.auth.getFrob&api_key=%@&api_sig=%@", 
		kFlickrKey, sig];
	NSError		*error = nil;
	NSData		*responseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlStr] options:NSUncachedRead error:&error];
	
	if (error != nil) {
		showErrorAlert(nil, @"Error", [NSString stringWithFormat:@"%@ %@",
                         [error localizedDescription],
                         [error localizedFailureReason]]);
	} else if (responseData == nil) {
		showErrorAlert(nil, @"Error", @"Did not get a response from Flickr!");
	} else {
		[self processFrob:responseData];
	}
}

/**
 * Scans Flickr XML response for an error. 
 */
- (NSString*)scanError:(NSScanner*)scanner {
	[scanner setScanLocation:0];
	if ([scanner scanUpToString:@"<err" intoString:nil] && ![scanner isAtEnd]) {
		if ([scanner scanUpToString:@"msg=\"" intoString:nil] && ![scanner isAtEnd]) {
			NSString *errStr = nil;
			[scanner scanString:@"msg=\"" intoString:nil];
			[scanner scanUpToString:@"\"" intoString:&errStr];
			if ( errStr != nil ) {
				return errStr;
			}
		}
	}
	return nil;
}

/**
 * Process the returned XML and extract the frob we need to get an authorized token.
 */
- (void)processFrob:(NSData*)data {
	NSString  *resp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSString  *frob = nil;
	NSScanner *scanner = [NSScanner scannerWithString:resp];
	
	// first check if it's not an error
	NSString *errStr = [self scanError:scanner];
	if (errStr == nil) {
		[scanner setScanLocation:0];
		// Find id attr
		[scanner scanUpToString:@"<frob" intoString:nil];
		if (![scanner isAtEnd]) {
			// Find end of id
			[scanner scanUpToString:@">" intoString:nil]; // move past
			[scanner scanString:@">" intoString:nil]; // move past
			[scanner scanUpToString:@"<" intoString:&frob];
		}
	}
	
	if ( frob == nil ) {
		// TODO
	} else {
		// Now that we have the frob we need the user to visit Flickr and explicitly authorize access.
		NSUserDefaults	*settings = [NSUserDefaults standardUserDefaults];
		NSString		*sigStr = [NSString stringWithFormat:@"%@api_key%@frob%@permswrite", kFlickrSecret, kFlickrKey, frob];
		NSString		*sig = [sigStr md5HexHash];
		NSString		*urlStr = [NSString stringWithFormat:@"http://flickr.com/services/auth/?api_key=%@&perms=write&frob=%@&api_sig=%@", kFlickrKey, frob, sig];

		[settings setObject:frob forKey:@"frob"];
		[self.delegate performSelector:@selector(loadUrlInWebView:) withObject:[NSURL URLWithString:urlStr]];
	}
	
	[resp release];
}

/**
 * The user apparently has authorized access on the Flickr web page,
 * so let's get our token!
 */
- (void)obtainToken {
	NSUserDefaults	*settings = [NSUserDefaults standardUserDefaults];
	NSString		*frob = [settings stringForKey:@"frob"];
	NSString		*sigStr = [NSString stringWithFormat:@"%@api_key%@frob%@method%@",
						kFlickrSecret, kFlickrKey, frob, @"flickr.auth.getToken"];
	NSString		*sig = [sigStr md5HexHash];
	NSString		*urlStr = [NSString stringWithFormat:
		@"http://api.flickr.com/services/rest/?method=flickr.auth.getToken&api_key=%@&frob=%@&api_sig=%@", 
						kFlickrKey, frob, sig];
	NSError			*error = nil;
	NSData			*responseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlStr] 
						options:NSUncachedRead error:&error];
	
	if (error != nil) {
		showErrorAlert(nil, @"Error", [NSString stringWithFormat:@"%@ %@",
                         [error localizedDescription],
                         [error localizedFailureReason]]);
	} else if (responseData == nil) {
		showErrorAlert(nil, @"Error", @"Did not get a response from Flickr!");
	} else {
		[self processToken:responseData];
	}
}

/**
 * Parse the XML returned from Flickr and extract the token.
 */
- (void)processToken:(NSData*)data {
	NSUserDefaults	*settings = [NSUserDefaults standardUserDefaults];
	NSString		*resp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSScanner		*scanner = [NSScanner scannerWithString:resp];
	NSString		*token = nil;
	NSString		*nsid = nil;
	
	// first check if it's not an error
	NSString *errStr = [self scanError:scanner];
	if (errStr == nil) {
		// Find token attr
		[scanner setScanLocation:0];
		[scanner scanUpToString:@"<token" intoString:nil];
		if (![scanner isAtEnd]) {
			// Find end of token
			[scanner scanUpToString:@">" intoString:nil]; // move past
			[scanner scanString:@">" intoString:nil]; // move past
			[scanner scanUpToString:@"<" intoString:&token];
		}
		[scanner setScanLocation:0];
		// Find nsid attr
		[scanner scanUpToString:@"nsid=\"" intoString:nil];
		if (![scanner isAtEnd]) {
			// Find end of token
			[scanner scanString:@"nsid=\"" intoString:nil]; // move past
			[scanner scanUpToString:@"\"" intoString:&nsid];
		}
	}

	[settings removeObjectForKey:@"frob"];
	if (token == nil || nsid == nil) {
		[settings removeObjectForKey:@"token"];
		[self requestPermission];
	} else {
		[settings setObject:token forKey:@"token"];
		[settings setObject:nsid forKey:@"nsid"];
		if (_selector && self.delegate && [self.delegate respondsToSelector:_selector])
			[self.delegate performSelector:_selector];
	}
	
	[resp release];
}

/**
 * Check if the token stored in the user defaults is still valid.
 */
- (void)checkToken:(NSString*)token {
	NSString *sigStr = [NSString stringWithFormat:@"%@api_key%@auth_token%@methodflickr.auth.checkToken", 
						kFlickrSecret, kFlickrKey, token];
	NSString *urlStr = [NSString stringWithFormat:
		@"http://api.flickr.com/services/rest/?method=flickr.auth.checkToken&api_key=%@&auth_token=%@&api_sig=%@", 
						kFlickrKey, token, [sigStr md5HexHash]];
	NSError  *error = nil;
	NSData	 *responseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlStr] 
						options:NSUncachedRead error:&error];
	
	if (error != nil) {
		showErrorAlert(nil, @"Error", [NSString stringWithFormat:@"%@ %@", [error localizedDescription], [error localizedFailureReason]]);
	} else if (responseData == nil) {
		showErrorAlert(nil, @"Error", @"Did not get a response from Flickr!");
	} else {
		[self processToken:responseData];
	}
}

#pragma mark -
#pragma mark Upload

/** Upload is requested. 
 * @param data
 *        Dictionary with values for Title, Description, Tags and Asset.
 */
- (void)initiateUpload:(NSDictionary*)data {

	if (data == nil || ![data isKindOfClass:[NSDictionary class]]) {
		[self uploadError:nil];
	}
	
	boundary = [[NSString alloc] initWithFormat:@"kd9dkfjd%u", [[NSDate date] timeIntervalSince1970]];
	formDataFileName = [[NSTemporaryDirectory() stringByAppendingString:@"flickd_temp"] retain];
	
	[self buildData:data];
}

/**
 * Build a multipart form for the provided meta data and asset. 
 * We save it straight to disk so we don't tax memory.
 * @param data
 *        Dictionary with values for Title, Description, Tags and Asset.
 */
- (void)buildData:(NSDictionary*)data {
	NSUserDefaults	*settings = [NSUserDefaults standardUserDefaults];
	NSString		*token = [settings stringForKey:@"token"];
	NSMutableString *sigStr = [NSMutableString stringWithFormat:@"%@api_key%@auth_token%@", kFlickrSecret, kFlickrKey, token];
	NSMutableData	*postData = [[NSMutableData alloc] init];
	NSArray			*tags = [data objectForKey:@"Tags"];
	NSMutableString *tagStr = nil;
	NSString		*desc = [data objectForKey:@"Description"];

/* PREP SIGNATURE STRING FIRST */
// description
	if ( desc == nil || [desc length] == 0 ) desc = @"";
	if ( [desc length] > 0 ) {
		[sigStr appendString:@"description"];
		[sigStr appendString:desc];
	}
// privacy
	NSString *family = nil;
	NSString *friends = nil;
	int privacy = 0;
	int access = 0;
	if ([data objectForKey:@"Privacy"] != nil)
		privacy = [[data objectForKey:@"Privacy"] intValue];
	switch (privacy) {
		case 0:
			[sigStr appendString:@"is_family0is_friend0is_public0"];
			family = @"0";
			friends = @"0";
			break;
		case 1:
			[sigStr appendString:@"is_family1is_friend0is_public0"];
			family = @"1";
			friends = @"0";
			break;
		case 2:
			[sigStr appendString:@"is_family0is_friend1is_public0"];
			family = @"0";
			friends = @"1";
			break;
		case 3:
			[sigStr appendString:@"is_family1is_friend1is_public0"];
			family = @"1";
			friends = @"1";
			break;
		default:
			[sigStr appendString:@"is_public1"];
			access = 1;
	}
// tags
	if (tags != nil) {
		tagStr = [NSMutableString string];	
		for (NSString *tag in tags) {
			NSRange rr = [tag rangeOfString:@" "];
			if ( rr.length > 0 ) {
				[tagStr appendString:@"\""];
				[tagStr appendString:tag];
				[tagStr appendString:@"\""];
			} else {
				[tagStr appendString:tag];
			}
			[tagStr appendString:@" "];
		}
		if ( [tagStr length] > 0 ) [tagStr deleteCharactersInRange:NSMakeRange([tagStr length]-1,1)];
	}
	if ( [tagStr length] > 0 )
	{
		[sigStr appendString:@"tags"];
		[sigStr appendString:tagStr];
	}
// title	
	[sigStr appendString:@"title"];
	[sigStr appendString:[data objectForKey:@"Title"]];

/* Start writing the data */

// api key
	[postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithString:@"Content-Disposition:form-data; name=\"api_key\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[kFlickrKey dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
// auth_token
	[postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithString:@"Content-Disposition:form-data; name=\"auth_token\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[token dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
// api sig
	[postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithString:@"Content-Disposition:form-data; name=\"api_sig\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[sigStr md5HexHash] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];

// title	
	[postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithString:@"Content-Disposition:form-data; name=\"title\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[data objectForKey:@"Title"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];

// description
	if ( [desc length] > 0 ) {
		[postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[[NSString stringWithString:@"Content-Disposition:form-data; name=\"description\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[desc dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	}

// privacy
	[postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithString:@"Content-Disposition:form-data; name=\"is_public\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	NSString *str = [NSString stringWithFormat:@"%d", access];
	[postData appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	if ( access == 0 )
	{
	// family
		[postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[[NSString stringWithString:@"Content-Disposition:form-data; name=\"is_family\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[family dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	// friends
		[postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[[NSString stringWithString:@"Content-Disposition:form-data; name=\"is_friend\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[friends dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	}

// tags
	if ( [tagStr length] > 0 )
	{
		[postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[[NSString stringWithString:@"Content-Disposition:form-data; name=\"tags\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[tagStr dataUsingEncoding:NSUTF8StringEncoding]];
		[postData appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
// image data
	[postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	NSString *disposition = [NSString stringWithFormat:@"Content-Disposition:form-data; name=\"photo\"; filename=\"%@\"\r\n", createUUID()];
	[postData appendData:[disposition dataUsingEncoding:NSUTF8StringEncoding]];
	[postData appendData:[[NSString stringWithString:@"Content-Type:image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];

// write what we have so far to the temp file
	NSOutputStream *formDataStream = [NSOutputStream outputStreamToFileAtPath:formDataFileName append:NO];
	[formDataStream open];

    NSInteger writeLength = [postData length];
	NSInteger actualWrittenLength = [formDataStream write:[postData bytes] maxLength:writeLength];
	[formDataStream close];
	[postData release];
	if (actualWrittenLength != writeLength) {
		[self.delegate uploadFailed:@"Couldn't prepare data for upload!"];
		return;
	}
	
	NSURL *assetURL = [data objectForKey:@"Asset"];
	
	// get the image data using the Assets Library
	ALAssetsLibraryAssetForURLResultBlock resultBlock = 
		^(ALAsset *asset) {
			ALAssetRepresentation *representation = [asset defaultRepresentation];
			NSOutputStream *mediaStream = [NSOutputStream outputStreamToFileAtPath:formDataFileName append:YES];
			[mediaStream open];

			NSUInteger bufferSize = 8192;
			NSUInteger read = 0, offset = 0, written = 0;
			uint8_t	   *buff = (uint8_t *)malloc(sizeof(uint8_t)*bufferSize);
			NSError	   *err = nil;
			
			do {
				read = [representation getBytes:buff fromOffset:offset length:bufferSize error:&err];
				written = [mediaStream write:buff maxLength:read];
				offset += read;
				if (err != nil) {
					[self.delegate uploadFailed:[err localizedDescription]];
					[mediaStream close];
					free(buff);
					return;
				}
				if (read != written) {
					[self.delegate uploadFailed:@"Couldn't prepare data for upload!"];
					[mediaStream close];
					free(buff);
					return;
				}
			} while (read != 0);
			free(buff);
			[mediaStream close];
			
			// finish up the formdata
			NSOutputStream *endStream = [NSOutputStream outputStreamToFileAtPath:formDataFileName append:YES];
			[endStream open];

			NSData    *closingData = [[NSString stringWithFormat:@"\r\n--%@--\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
			NSInteger writeLength = [closingData length];
			NSInteger actualWrittenLength = [endStream write:[closingData bytes] maxLength:writeLength];
			
			[endStream close];
			if (actualWrittenLength == -1 || actualWrittenLength != writeLength) {
				[self.delegate uploadFailed:@"Couldn't prepare data for upload!"];
				return;
			}
			
			// we're still here, so all data is safely written to disk. Let's offroad!
			[self submitData];
		};

	ALAssetsLibrary *assetLib = [[[ALAssetsLibrary alloc] init] autorelease];
	[assetLib assetForURL:assetURL resultBlock:resultBlock failureBlock:^(NSError *error) {
		[self.delegate uploadFailed:[error localizedDescription]];
	}];
}

/**
 * Send the form data to Flickr. We use an NSInputStream
 * to stream the data from disk. 
 */
- (void)submitData {
	NSDictionary  *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:formDataFileName error:nil];
	NSNumber	  *fileSizeNumber = [fileInfo objectForKey:NSFileSize];
	NSUInteger    fileSize = 0;
	NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:formDataFileName];
	NSString	  *contentType = [NSString stringWithFormat: @"multipart/form-data; boundary=%@", boundary];
	NSURL		  *url = [NSURL URLWithString:@"http://api.flickr.com/services/upload/"];

	if ([fileSizeNumber respondsToSelector:@selector(integerValue)]) {
		fileSize = [fileSizeNumber integerValue];                    
	} else {
		fileSize = [fileSizeNumber intValue];                    
	}                
	
	httpRequest = [[LFHTTPRequest alloc] init];
	[httpRequest setDelegate:self];
	[httpRequest setContentType:contentType];
	[httpRequest setUserAgent:@"Flickd (http://infinite-sushi.com/software/, iPhone)"];
	[httpRequest setRequestHeader:[NSDictionary dictionaryWithObjectsAndKeys:[url host], @"Host", @"text/xml", @"Accept", nil]];
	[httpRequest performMethod:LFHTTPRequestPOSTMethod onURL:url withInputStream:inputStream knownContentSize:fileSize];
}

/**
 * Callback from the LFHTTPRequest. Update the progress HUD with the new value.
 */
- (void)httpRequest:(LFHTTPRequest*)request sentBytes:(NSUInteger)bytesSent total:(NSUInteger)total {
	float val = (float)bytesSent/(float)total;
	if (self.delegate) {
		[self.delegate setProgress:val];
	}
}

/**
 * Callback from the LFHTTPRequest. Parse the response and finish up.
 */
- (void)httpRequestDidComplete:(LFHTTPRequest*)request {
	NSData *data = [request receivedData];
	NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSString *errStr;
	NSString *photoId = [self parseUploadResponse:responseString error:&errStr];
	[responseString release];
	[httpRequest release]; httpRequest = nil;
	[self cleanUpTempFile];
	if (photoId != nil) {
		[self.delegate uploadFinished:[NSString stringWithString:photoId]];
	} else {
		[self.delegate uploadFailed:errStr];
	}
}

/**
 * Callback from the LFHTTPRequest. Notify user that the upload failed.
 */
- (void)httpRequest:(LFHTTPRequest*)request didFailWithError:(NSString*)error {
	[httpRequest release]; httpRequest = nil;
	[self cleanUpTempFile];
	[self uploadError:error];
}

/**
 * Delete the temporary file created for the upload.
 */
- (void)cleanUpTempFile {
    if (formDataFileName) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:formDataFileName]) {
			BOOL __unused removeResult = NO;
			NSError *error = nil;
			removeResult = [fileManager removeItemAtPath:formDataFileName error:&error];
        }        
        [formDataFileName release];
        formDataFileName = nil;
    }
}

/**
 * Parse the XML response from Flickr and extract the photo's ID.
 */
- (NSString*)parseUploadResponse:(NSString*)str error:(NSString**)errStr {
	NSString  *idStr = nil;
	NSScanner *scanner = [NSScanner scannerWithString:str];

	// first check if it's not an error
	*errStr = [self scanError:scanner];
	if (*errStr == nil) {
		// get photo id
		[scanner setScanLocation:0];
		if ([scanner scanUpToString:@"<photoid>" intoString:nil]) {
			[scanner scanString:@"<photoid>" intoString:nil];
			[scanner scanUpToString:@"</photoid>" intoString:&idStr];
		} else {
			*errStr = @"Did not get a confirmation from Flickr.";
		}
	}
	return idStr;
}

/**
 * Called when something went wrong and we need to return
 * control to the delegate.
 */
- (void)uploadError:(NSString*)str {
	if (str == nil)
		str = @"Something is not right!";
	[self.delegate uploadFailed:str];
}

@end
