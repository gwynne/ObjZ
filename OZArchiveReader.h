//
//  OZArchiveReader.h
//  IPADropper
//
//  Created by Gwynne Raskind on 6/30/12.
//  Copyright (c) 2012 Abby's LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
	OZCompressionDeflate = 0,
	OZCompressionBzip2 = 1,
} OZCompressionMethod;

@interface OZArchiveFile : NSObject

@property(nonatomic,weak,readonly)		OZArchive				*archive;
@property(nonatomic,assign,readonly)	uint16_t				compressorVersion, minDecompressorVersion;
@property(nonatomic,assign,readonly)	uint16_t				flags;
@property(nonatomic,assign,readonly)	OZCompressionMethod		method;
@property(nonatomic,assign,readonly)	NSDate					*lastModificationDate;
@property(nonatomic,assign,readonly)	uint32_t				CRC;
@property(nonatomic,assign,readonly)	uint64_t				compressedSize, expandedSize;
@property(nonatomic,copy,readonly)		NSString				*path;
@property(nonatomic,strong,readonly)	NSData					*extraField;
@property(nonatomic,copy,readonly)		NSString				*comment;
@property(nonatomic,assign,readonly)	uint16_t				diskNumberStart;
@property(nonatomic,assign,readonly)	uint16_t				internalAttributes;
@property(nonatomic,assign,readonly)	uint32_t				externalAttributes;

@end

@interface OZArchiveReader : NSObject

+ (OZArchiveReader *)readerWithURL:(NSURL *)url;
+ (OZArchiveReader *)readerWithPath:(NSString *)path;
+ (OZArchiveReader *)readerWithData:(NSData *)data;

- (id)initWithURL:(NSURL *)url;
- (id)initWithPath:(NSURL *)url;
- (id)initWithData:(NSData *)data;

@property(nonatomic,assign,readonly)	uint64_t		entryCount;
@property(nonatomic,copy,readonly)		NSString		*globalComment;

- (void)enumerateArchiveContentsWithBlock:(BOOL (^)(OZArchiveFile *file, NSError *error));
- (OZArchiveFile *)fileWithPath:(NSString *)pathInArchive caseSensitive:(BOOL)cs;

@end