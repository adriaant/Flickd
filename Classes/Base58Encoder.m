#import "Base58Encoder.h"

@implementation Base58Encoder

/**
 * Based on Kellan Elliot-McCrea's PHP code: 
 * http://www.flickr.com/groups/api/discuss/72157616713786392
 */
+ (NSString*)base58EncodedValue:(long long)num {
	NSMutableString *encoded = [NSMutableString stringWithCapacity:10];
	NSString		*alphabet = @"123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ";
	int				baseCount = [alphabet length];
	
	while (num >= baseCount) {
		double		div = num/baseCount;
		long long	mod = (num - (baseCount * (long long)div));
		NSString	*alphabetChar = [alphabet substringWithRange:NSMakeRange(mod, 1)];
		
		[encoded insertString:alphabetChar atIndex:0];
		num = (long long)div;
	}
	
	if (num) {
		[encoded insertString:[alphabet substringWithRange:NSMakeRange(num, 1)] atIndex:0];
	}
	return encoded;
}

@end
