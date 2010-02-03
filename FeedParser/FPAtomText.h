//
//  FPAtomText.h
//  FeedParser
//
//  Created by James Abley on 04/02/2010.
//  Copyright 2010 Mobile IQ Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPXMLParser.h"

enum FPAtomTextType {
    FPAtomTextTypeText,
    FPAtomTextTypeHTML,
    FPAtomTextTypeXHTML,
};

@interface FPAtomText : FPXMLParser {
@private
    NSString *text;

}

- (id)initWithBaseNamespaceURI:(NSString *)namespaceURI attributes:(NSDictionary*)attributes;

@property (nonatomic, copy, readonly) NSString *text;

@end
