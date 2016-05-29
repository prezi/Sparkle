//
//  SUAppcastItem.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/12/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUAppcastItem.h"
#import "SUVersionComparisonProtocol.h"
#import "SULog.h"
#import "SUConstants.h"

#ifdef _APPKITDEFINES_H
#error This is a "core" class and should NOT import AppKit
#endif

@implementation SUAppcastItem
@synthesize dateString = _dateString;
@synthesize deltaUpdates = _deltaUpdates;
@synthesize displayVersionString = _displayVersionString;
@synthesize DSASignature = _DSASignature;
@synthesize fileURL = _fileURL;
@synthesize contentLength = _contentLength;
@synthesize infoURL = _infoURL;
@synthesize itemDescription = _itemDescription;
@synthesize maximumSystemVersion = _maximumSystemVersion;
@synthesize minimumSystemVersion = _minimumSystemVersion;
@synthesize releaseNotesURL = _releaseNotesURL;
@synthesize title = _title;
@synthesize versionString = _versionString;
@synthesize propertiesDictionary = _propertiesDictionary;

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    
    if (self != nil) {
        _deltaUpdates = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary class], [SUAppcastItem class]]] forKey:@"deltaUpdates"];
        _displayVersionString = [[decoder decodeObjectOfClass:[NSString class] forKey:@"displayVersionString"] copy];
        _DSASignature = [[decoder decodeObjectOfClass:[NSString class] forKey:@"DSASignature"] copy];
        _fileURL = [decoder decodeObjectOfClass:[NSURL class] forKey:@"fileURL"];
        _infoURL = [decoder decodeObjectOfClass:[NSURL class] forKey:@"infoURL"];
        
        _contentLength = (NSUInteger)[decoder decodeIntegerForKey:@"contentLength"];
        if (_contentLength == 0) {
            return nil;
        }
        
        _itemDescription = [[decoder decodeObjectOfClass:[NSString class] forKey:@"itemDescription"] copy];
        _maximumSystemVersion = [[decoder decodeObjectOfClass:[NSString class] forKey:@"maximumSystemVersion"] copy];
        _minimumSystemVersion = [[decoder decodeObjectOfClass:[NSString class] forKey:@"minimumSystemVersion"] copy];
        _releaseNotesURL = [decoder decodeObjectOfClass:[NSURL class] forKey:@"releaseNotesURL"];
        _title = [[decoder decodeObjectOfClass:[NSString class] forKey:@"title"] copy];
        _versionString = [[decoder decodeObjectOfClass:[NSString class] forKey:@"versionString"] copy];
        _propertiesDictionary = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary class], [NSString class], [NSDate class], [NSArray class]]] forKey:@"propertiesDictionary"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    if (self.deltaUpdates != nil) {
        [encoder encodeObject:self.deltaUpdates forKey:@"deltaUpdates"];
    }
    
    if (self.displayVersionString != nil) {
        [encoder encodeObject:self.displayVersionString forKey:@"displayVersionString"];
    }
    
    if (self.DSASignature != nil) {
        [encoder encodeObject:self.DSASignature forKey:@"DSASignature"];
    }
    
    if (self.fileURL != nil) {
        [encoder encodeObject:self.fileURL forKey:@"fileURL"];
    }
    
    if (self.infoURL != nil) {
        [encoder encodeObject:self.infoURL forKey:@"infoURL"];
    }
    
    [encoder encodeInteger:(NSInteger)self.contentLength forKey:@"contentLength"];
    
    if (self.itemDescription != nil) {
        [encoder encodeObject:self.itemDescription forKey:@"itemDescription"];
    }
    
    if (self.maximumSystemVersion != nil) {
        [encoder encodeObject:self.maximumSystemVersion forKey:@"maximumSystemVersion"];
    }
    
    if (self.minimumSystemVersion != nil) {
        [encoder encodeObject:self.minimumSystemVersion forKey:@"minimumSystemVersion"];
    }
    
    if (self.releaseNotesURL != nil) {
        [encoder encodeObject:self.releaseNotesURL forKey:@"releaseNotesURL"];
    }
    
    if (self.title != nil) {
        [encoder encodeObject:self.title forKey:@"title"];
    }
    
    if (self.versionString != nil) {
        [encoder encodeObject:self.versionString forKey:@"versionString"];
    }
    
    if (self.propertiesDictionary != nil) {
        [encoder encodeObject:self.propertiesDictionary forKey:@"propertiesDictionary"];
    }
}

- (BOOL)isDeltaUpdate
{
    NSDictionary *rssElementEnclosure = [self.propertiesDictionary objectForKey:SURSSElementEnclosure];
    return [rssElementEnclosure objectForKey:SUAppcastAttributeDeltaFrom] != nil;
}

- (BOOL)isCriticalUpdate
{
    return [[self.propertiesDictionary objectForKey:SUAppcastElementTags] containsObject:SUAppcastElementCriticalUpdate];
}

- (BOOL)isInformationOnlyUpdate
{
    return self.infoURL && !self.fileURL;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    return [self initWithDictionary:dict failureReason:nil];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict failureReason:(NSString *__autoreleasing *)error
{
    self = [super init];
    if (self) {
        NSDictionary *enclosure = [dict objectForKey:SURSSElementEnclosure];

        // Try to find a version string.
        // Finding the new version number from the RSS feed is a little bit hacky. There are two ways:
        // 1. A "sparkle:version" attribute on the enclosure tag, an extension from the RSS spec.
        // 2. If there isn't a version attribute, Sparkle will parse the path in the enclosure, expecting
        //    that it will look like this: http://something.com/YourApp_0.5.zip. It'll read whatever's between the last
        //    underscore and the last period as the version number. So name your packages like this: APPNAME_VERSION.extension.
        //    The big caveat with this is that you can't have underscores in your version strings, as that'll confuse Sparkle.
        //    Feel free to change the separator string to a hyphen or something more suited to your needs if you like.
        NSString *newVersion = [enclosure objectForKey:SUAppcastAttributeVersion];
        if (newVersion == nil) {
            newVersion = [dict objectForKey:SUAppcastAttributeVersion]; // Get version from the item, in case it's a download-less item (i.e. paid upgrade).
        }
        if (newVersion == nil) // no sparkle:version attribute anywhere?
        {
            SULog(@"warning: <%@> for URL '%@' is missing %@ attribute. Version comparison may be unreliable. Please always specify %@", SURSSElementEnclosure, [enclosure objectForKey:SURSSAttributeURL], SUAppcastAttributeVersion, SUAppcastAttributeVersion);

            // Separate the url by underscores and take the last component, as that'll be closest to the end,
            // then we remove the extension. Hopefully, this will be the version.
            NSArray *fileComponents = [[enclosure objectForKey:SURSSAttributeURL] componentsSeparatedByString:@"_"];
            if ([fileComponents count] > 1) {
                newVersion = [[fileComponents lastObject] stringByDeletingPathExtension];
            }
        }

        if (!newVersion) {
            if (error) {
                *error = [NSString stringWithFormat:@"Feed item lacks %@ attribute, and version couldn't be deduced from file name (would have used last component of a file name like AppName_1.3.4.zip)", SUAppcastAttributeVersion];
            }
            return nil;
        }

        _propertiesDictionary = [[NSDictionary alloc] initWithDictionary:dict];
        _title = [[dict objectForKey:SURSSElementTitle] copy];
        _dateString = [[dict objectForKey:SURSSElementPubDate] copy];
        _itemDescription = [[dict objectForKey:SURSSElementDescription] copy];

        NSString *theInfoURL = [dict objectForKey:SURSSElementLink];
        if (theInfoURL) {
            if (![theInfoURL isKindOfClass:[NSString class]]) {
                SULog(@"%@ -%@ Info URL is not of valid type.", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            } else {
                _infoURL = [NSURL URLWithString:theInfoURL];
            }
        }

        // Need an info URL or an enclosure URL. Former to show "More Info"
        //	page, latter to download & install:
        if (!enclosure && !theInfoURL) {
            if (error) {
                *error = @"No enclosure in feed item";
            }
            return nil;
        }

        NSString *enclosureURLString = [enclosure objectForKey:SURSSAttributeURL];
        if (!enclosureURLString && !theInfoURL) {
            if (error) {
                *error = @"Feed item's enclosure lacks URL";
            }
            return nil;
        }
        
        NSString *enclosureLengthString = [enclosure objectForKey:SURSSAttributeLength];
        NSInteger contentLength = 0;
        if (enclosureLengthString != nil) {
            contentLength = [enclosureLengthString integerValue];
        }
        if (contentLength > 0) {
            _contentLength = (NSUInteger)contentLength;
        } else {
            // content length is important enough to require
            // developers copying the sample appcast should be using it already,
            // and we can get away with assuming the content length provided is valid
            if (error != NULL) {
                *error = @"Feed item's enclosure lacks length";
            }
            return nil;
        }

        if (enclosureURLString) {
            // Sparkle used to always URL-encode, so for backwards compatibility spaces in URLs must be forgiven.
            NSString *fileURLString = [enclosureURLString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
            _fileURL = [NSURL URLWithString:fileURLString];
        }
        if (enclosure) {
            _DSASignature = [[enclosure objectForKey:SUAppcastAttributeDSASignature] copy];
        }

        _versionString = [newVersion copy];
        _minimumSystemVersion = [[dict objectForKey:SUAppcastElementMinimumSystemVersion] copy];
        _maximumSystemVersion = [[dict objectForKey:SUAppcastElementMaximumSystemVersion] copy];

        NSString *shortVersionString = [enclosure objectForKey:SUAppcastAttributeShortVersionString];
        if (nil == shortVersionString) {
            shortVersionString = [dict objectForKey:SUAppcastAttributeShortVersionString]; // fall back on the <item>
        }

        if (shortVersionString) {
            _displayVersionString = [shortVersionString copy];
        } else {
            _displayVersionString = [_versionString copy];
        }

        // Find the appropriate release notes URL.
        NSString *releaseNotesString = [dict objectForKey:SUAppcastElementReleaseNotesLink];
        if (releaseNotesString) {
            NSURL *url = [NSURL URLWithString:releaseNotesString];
            if ([url isFileURL]) {
                SULog(@"Release notes with file:// URLs are not supported");
            } else {
                _releaseNotesURL = url;
            }
        } else if ([self.itemDescription hasPrefix:@"http://"] || [self.itemDescription hasPrefix:@"https://"]) { // if the description starts with http:// or https:// use that.
            _releaseNotesURL = [NSURL URLWithString:self.itemDescription];
        } else {
            _releaseNotesURL = nil;
        }

        NSArray *deltaDictionaries = [dict objectForKey:SUAppcastElementDeltas];
        if (deltaDictionaries) {
            NSMutableDictionary *deltas = [NSMutableDictionary dictionary];
            for (NSDictionary *deltaDictionary in deltaDictionaries) {
                NSString *deltaFrom = [deltaDictionary objectForKey:SUAppcastAttributeDeltaFrom];
                if (!deltaFrom) continue;

                NSMutableDictionary *fakeAppCastDict = [dict mutableCopy];
                [fakeAppCastDict removeObjectForKey:SUAppcastElementDeltas];
                [fakeAppCastDict setObject:deltaDictionary forKey:SURSSElementEnclosure];
                SUAppcastItem *deltaItem = [[SUAppcastItem alloc] initWithDictionary:fakeAppCastDict];

                [deltas setObject:deltaItem forKey:deltaFrom];
            }
            _deltaUpdates = deltas;
        }
    }
    return self;
}

@end
