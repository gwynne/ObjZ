//
//  OZArchiveBuilder.h
//  IPADropper
//
//  Created by Gwynne Raskind on 7/2/12.
//  Copyright (c) 2012 Abby's LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OZArchiveReader.h"

@interface OZArchiveBuilder : NSObject

+ (OZArchiveBuilder *)archiveBuilderWithURL:(NSURL *)url overwrite:(BOOL)overwrite;
+ (OZArchiveBuilder *)archiveBuilderWithPath:(NSString *)path overwrite:(BOOL)overwrite;
+ (OZArchiveBuilder *)archiveBuilderAppendingToData:(NSMutableData *)data overwrite:(BOOL)overwrite;
+ (OZArchiveBuilder *)archiveBuilderInMemory;

- (id)initWithURL:(NSURL *)url overwrite:(BOOL)overwrite;
- (id)initWithPath:(NSString *)path overwrite:(BOOL)overwrite;
- (id)initAppendingToData:(NSMutableData *)data overwrite:(BOOL)overwrite;
- (id)init;

// The base URL against which addContentsOfURL/Path determine how much of the
//	original file path to save. If nil, only the last path component is used.
//	Also forms the base URL for the top level in addContentsOfDirectory.
@property(nonatomic,strong)				NSURL			*baseURL;

// If the builder was created with -initAppendingToData, this is the same
//	object that was passed. If the builder was created with -init, this is the
//	actual mutable data which is being updated. In all other cases, this is nil.
@property(nonatomic,strong,readonly)	NSMutableData	*data;

// Close the archive. An archive can not be considered valid until this method
//	is called. If NO is returned, the archive is NOT valid, any files created on
//	disk will be removed, and the builder can not be reused. After returning
//	from this method, regardless of success, further attempts to manipulate the
//	archive will throw an exception.
// NOTE: This method is called automatically when the builder is deallocated,
//	but as -dealloc has no opportunity to return errors, it is STRONGLY
//	recommended that clients of this API call -closeAndReturnError: explicitly.
- (BOOL)closeAndReturnError:(NSError **)error;

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
		withFlags:(uint16_t)flags
		andReturnError:(NSError **)error;

@end
