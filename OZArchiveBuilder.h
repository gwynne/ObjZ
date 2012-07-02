//
//  OZArchiveBuilder.h
//  IPADropper
//
//  Created by Gwynne Raskind on 7/2/12.
//  Copyright (c) 2012 Abby's LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OZArchiveReader.h"
#import "zip.h"

@interface OZArchiveBuilder : NSObject

+ (OZArchiveBuilder *)archiveBuilderWithURL:(NSURL *)url;
+ (OZArchiveBuilder *)archiveBuilderWithPath:(NSString *)path;
+ (OZArchiveBuilder *)archiveBuilderAppendingToData:(NSMutableData *)data;
+ (OZArchiveBuilder *)archiveBuilderInMemory;

- (id)initWithURL:(NSURL *)url;
- (id)initWithPath:(NSString *)path;
- (id)initAppendingToData:(NSMutableData *)data;
- (id)init;

// The base URL against which addContentsOfURL/Path determine how much of the
//	original file path to save. If nil, only the last path component is used.
@property(nonatomic,strong)	NSURL		*baseURL;

- (BOOL)addContentsOfDirectory:(NSURL *)directory andReturnError:(NSError **)error; // replicates directory structure as much as possible

- (BOOL)addContentsOfURL:(NSURL *)url andReturnError:(NSError **)error; // URL must not be a directory
- (BOOL)addContentsOfPath:(NSString *)path andReturnError:(NSError **)error; // path must not refer to a directory
- (BOOL)addData:(NSData *)data withFilePath:(NSString *)path andReturnError:(NSError **)error;

// This is the most primitive routine for adding data to the archive. Most of
//	these parameters aren't useful, and will be filled in automatically when
//	using the convenience routines above.
- (BOOL)addData:(NSData *)data
		withFilePath:(NSString *)path
		withModificationDate:(NSDate *)date
		withInternalAttributes:(uint16_t)internalFA
		withExternalAttributes:(uint32_t)externalFA
		withComment:(NSString *)comment
		withExtraField:(NSData *)extraField
		withMethod:(OZCompressionMethod)method
		withLevel:(int)level
		withStrategy:(int)strategy
		withPassword:(NSString *)password
		withFlags:(uint16_t)flags;
		andReturnError:(NSError **)error;

@end
