//
//  FPAtomText.m
//  FeedParser
//
//  Created by James Abley on 04/02/2010.
//  Copyright 2010 Mobile IQ Ltd. All rights reserved.
//

#import "FPAtomText.h"

@interface FPAtomText()

@property (nonatomic, copy, readwrite) NSString *text;

@end

@implementation FPAtomText

@synthesize text;

- (id)initWithBaseNamespaceURI:(NSString *)namespaceURI attributes:(NSDictionary*)attributes {

    if (self = [super initWithBaseNamespaceURI:namespaceURI]) {
        NSString* type = [attributes valueForKey:@"type"];

        if (!type) {
            type = @"text";
        }

        if ([@"text" isEqualToString:type]) {
            // Set the title from the characters

        } else if ([@"html" isEqualToString:type]) {
            NSLog(@"title is html - not currently handled");
        } else { // xhtml
            NSLog(@"title is xhtml - not currently handled");
        }

    }

    return self;
}

@end
