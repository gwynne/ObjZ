//
//  OZMemoryIO.m
//  IPADropper
//
//  Created by Gwynne Raskind on 7/3/12.
//  Copyright (c) 2012 Abby's LLC. All rights reserved.
//

#import "OZMemoryIO.h"
#import <objc/runtime.h>

#define getOffset(data)		([objc_getAssociatedObject((data), "OZ_NSData_data_offset") longLongValue])
#define getOffsetv(data)	([objc_getAssociatedObject((__bridge NSData *)(data), "OZ_NSData_data_offset") longLongValue])
#define setOffset(data, o)	(objc_setAssociatedObject((data), "OZ_NSData_data_offset", [NSNumber numberWithLongLong:(o)], OBJC_ASSOCIATION_RETAIN))

static ZPOS64_T	OZ_NSData_tell64(voidpf opaque, voidpf stream)
{
	return getOffsetv(stream);
}

static long		OZ_NSData_seek64(voidpf opaque, voidpf stream, ZPOS64_T offset, int origin)
{
	NSData		*data = (__bridge NSData *)stream;
	int64_t		realOffset = (int64_t)offset;
	
	if (getOffset(data) < 0)
		return 1;
	
	if (origin == ZLIB_FILEFUNC_SEEK_CUR)
		realOffset += getOffset(data);
	else if (origin == ZLIB_FILEFUNC_SEEK_END)
		realOffset += data.length;
	else if (origin != ZLIB_FILEFUNC_SEEK_SET)
		return 1;

	if (realOffset < 0 || realOffset >= (NSInteger)data.length)
		return 1;
	setOffset(data, offset);
	return 0;
}

static voidpf		OZ_NSData_open64(voidpf opaque, const void *filename, int mode) // opaque is the data offset, filename is the NSData* object
{
	if ((mode & ZLIB_FILEFUNC_MODE_READWRITEFILTER) != ZLIB_FILEFUNC_MODE_READ)
		return NULL;
	setOffset((__bridge NSData *)filename, 0);
	return (void *)filename; // Yes, I really mean to cast away constness
}

static uLong		OZ_NSData_read64(voidpf opaque, voidpf stream, void *buf, uLong size)
{
	NSData		*data = (__bridge NSData *)stream;
	int64_t		offset = getOffset(data);
	
	if (offset < 0)
		return 0;
	
	uLong		bytesToRead = MIN(size, (uint64_t)data.length - (uint64_t)offset);
	
	if (bytesToRead)
	{
		[data getBytes:buf range:(NSRange){ offset, bytesToRead }];
		setOffset(data, offset + bytesToRead);
	}
	return bytesToRead;
}

static uLong		OZ_NSData_write64(voidpf opaque, voidpf stream, const void *buf, uLong size)
{
	NSMutableData	*data = (__bridge NSMutableData *)stream;
	int64_t			offset = getOffset(data);
	
	if (offset < 0)
		return 0;
	
	uLong			maxOffset = offset + size;
	
	if (maxOffset > data.length)
		[data increaseLengthBy:maxOffset - data.length];
	memcpy(data.mutableBytes, buf, size);
	setOffset(data, offset + size);
	return size;
}

static int			OZ_NSData_close64(voidpf opaque, voidpf stream)
{
	setOffset((__bridge NSData *)stream, -1);
	return 0;
}

static int			OZ_NSData_testerror64(voidpf opaque, voidpf stream)
{
	return getOffsetv(stream) < 0 ? 1 : 0;
}

zlib_filefunc64_def		OZ_NSData_rw_functions = {
	.zopen64_file = OZ_NSData_open64,
	.zread_file = OZ_NSData_read64,
	.zwrite_file = OZ_NSData_write64,
	.ztell64_file = OZ_NSData_tell64,
	.zseek64_file = OZ_NSData_seek64,
	.zclose_file = OZ_NSData_close64,
	.zerror_file = OZ_NSData_testerror64,
	.opaque = NULL,
};
