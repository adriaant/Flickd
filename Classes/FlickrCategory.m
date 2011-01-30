/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import "FlickrCategory.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (Flickr)
- (NSString*)md5HexHash {
	unsigned char digest[16];
	char finalDigest[32];

	CC_MD5([self bytes], [self length], digest);
	for (unsigned short int i = 0; i < 16; i++)
		sprintf(finalDigest + (i * 2), "%02x", digest[i]);

	return [NSString stringWithCString:finalDigest encoding:NSUTF8StringEncoding];
}
@end

@implementation NSString (Flickr)
- (NSString*)md5HexHash {
	return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] md5HexHash];
}
@end

@implementation NSDictionary (Flickr)
- (NSArray*)pairsJoinedByString: (NSString*)j {
	NSArray *sortedKeys = [[self allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
	NSMutableArray *allKeysAndObjects = [NSMutableArray array];

	for (unsigned int i = 0; i < [sortedKeys count]; i++) {
		NSString *key = [sortedKeys objectAtIndex: i];
		NSString *val = [self objectForKey: key];
		[allKeysAndObjects addObject: [NSString stringWithFormat: @"%@%@%@", key, j, val]];
	}

	return [NSArray arrayWithArray: allKeysAndObjects];
}
@end

