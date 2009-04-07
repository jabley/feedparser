//
//  FPXMLParser.m
//  FeedParser
//
//  Created by Kevin Ballard on 4/6/09.
//  Copyright 2009 Kevin Ballard. All rights reserved.
//

#import "FPXMLParser.h"
#import "FPXMLPair.h"
#import <objc/message.h>

NSString * const kFPXMLParserAtomNamespaceURI = @"http://www.w3.org/2005/Atom";
NSString * const kFPXMLParserDublinCoreNamespaceURI = @"http://purl.org/dc/elements/1.1/";
NSString * const kFPXMLParserContentNamespaceURI = @"http://web.resource.org/rss/1.0/modules/content/";

static NSMutableDictionary *kHandlerMap;

void (*handleTextValue)(id, SEL, NSString*, NSDictionary*, NSXMLParser*) = (void(*)(id, SEL, NSString*, NSDictionary*, NSXMLParser*))objc_msgSend;
void (*handleStreamElement)(id, SEL, NSDictionary*, NSXMLParser*) = (void(*)(id, SEL, NSDictionary*, NSXMLParser*))objc_msgSend;

@implementation FPXMLParser
+ (void)initialize {
	if (self == [FPXMLParser class]) {
		kHandlerMap = (NSMutableDictionary *)CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
	}
}

// if selector is NULL then just ignore this element rather than raising an error
+ (void)registerHandler:(SEL)selector forElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI type:(FPXMLParserElementType)type {
	NSMutableDictionary *handlers = [kHandlerMap objectForKey:self];
	if (handlers == nil) {
		handlers = [NSMutableDictionary dictionary];
		CFDictionarySetValue((CFMutableDictionaryRef)kHandlerMap, self, handlers);
	}
	FPXMLPair *keyPair = [FPXMLPair pairWithFirst:elementName second:namespaceURI];
	FPXMLPair *valuePair = [FPXMLPair pairWithFirst:NSStringFromSelector(selector) second:[NSNumber numberWithInt:type]];
	[handlers setObject:valuePair forKey:keyPair];
}

- (id)initWithParent:(FPXMLParser *)parent {
	if (self = [self init]) {
		parentParser = parent;
	}
	return self;
}

- (id)init {
	if (self = [super init]) {
		handlers = [kHandlerMap objectForKey:[self class]];
		currentElementType = FPXMLParserStreamElementType;
	}
	return self;
}

- (void)abortParsing:(NSXMLParser *)parser {
	if (parentParser != nil) {
		[parentParser abortParsing:parser];
		parentParser = nil;
	} else {
		[parser abortParsing];
	}
}

- (void)abdicateParsing:(NSXMLParser *)parser {
	[parser setDelegate:parentParser];
	parentParser = nil;
}

- (void)dealloc {
	[handlers release];
	[currentTextValue release];
	[currentAttributeDict release];
	[super dealloc];
}

#pragma mark XML Parser methods

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (currentElementType == FPXMLParserTextElementType) {
		[currentTextValue appendString:string];
	} else if ([string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]].location != NSNotFound) {
		[self abortParsing:parser];
	}
}

// this method never seems to be called
- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString {
	if (currentElementType == FPXMLParserTextElementType) {
		[currentTextValue appendString:whitespaceString];
	}
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
	if (currentElementType == FPXMLParserTextElementType) {
		NSString *str = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
		if (str == nil) {
			// the data isn't valid UTF-8
			// try as ISO-Latin-1. Probably not correct, but at least it will never fail
			str = [[NSString alloc] initWithData:CDATABlock encoding:NSISOLatin1StringEncoding];
		}
		[currentTextValue appendString:str];
		[str release];
	} else {
		[self abortParsing:parser];
	}
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	switch (currentElementType) {
		case FPXMLParserTextElementType:
			[self abortParsing:parser];
			break;
		case FPXMLParserStreamElementType: {
			FPXMLPair *keyPair = [FPXMLPair pairWithFirst:elementName second:namespaceURI];
			FPXMLPair *handler = [handlers objectForKey:keyPair];
			if (handler != nil) {
				SEL selector = NSSelectorFromString((NSString *)handler.first);
				FPXMLParserElementType type = (FPXMLParserElementType)[(NSNumber *)handler.second intValue];
				currentElementType = type;
				switch (type) {
					case FPXMLParserStreamElementType:
						if (selector != NULL) {
							handleStreamElement(self, selector, attributeDict, parser);
						}
						break;
					case FPXMLParserTextElementType:
						[currentTextValue release];
						currentTextValue = [[NSMutableString alloc] init];
						currentAttributeDict = [attributeDict copy];
						currentHandlerSelector = selector;
						break;
				}
			} else if ([namespaceURI isEqualToString:@""] || [namespaceURI isEqualToString:kFPXMLParserAtomNamespaceURI]) {
				[self abortParsing:parser];
			}
			break;
		}
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	switch (currentElementType) {
		case FPXMLParserTextElementType: {
			NSString *text = [currentTextValue copy];
			if (currentHandlerSelector != NULL) {
				handleTextValue(self, currentHandlerSelector, text, currentAttributeDict, parser);
			}
			[text release];
			[currentTextValue release];
			currentTextValue = nil;
			[currentAttributeDict release];
			currentAttributeDict = nil;
			currentElementType = FPXMLParserStreamElementType;
			break;
		}
		case FPXMLParserStreamElementType:
			break;
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	[self abortParsing:parser];
}
@end