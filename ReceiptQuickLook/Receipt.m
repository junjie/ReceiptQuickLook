//
// Receipt QuickLook Plugin.
// Copyright (c) 2013 Laurent Etiemble.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
#import "Receipt.h"

#pragma ----- Private -----

@interface Receipt()

/**
 * @brief Parse the receipt's data.
 * @param data The receipt's data
 */
- (void)parseData:(NSData *)data;

/**
 * @brief Extract a dictionary from an ASN.1 set.
 * @param ptr A pointer to the start of the buffer
 * @param end A pointer to the end of the buffer
 * @return A dictionary containing the parsed attributes
 */
+ (NSMutableDictionary *)dictionaryWithASN1:(const unsigned char *)ptr ofLength:(const unsigned char *)end;

/**
 * @brief Decode a variable-length integer.
 * @param data A pointer to the buffer
 * @param length The length of the buffer
 * @return The integer value
 */
+ (int)decodeInt:(const unsigned char *)data ofLength:(long) length;

@end

#pragma ----- Implementation -----

@implementation Receipt

- (id)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        [self parseData:data];
    }
    return self;
}

- (NSDictionary *)dictionary {
    return self->_dictionary;
}

+ (BOOL)looksLikeAReceiptFile:(NSData *)data {
    BOOL result = NO;
    
    // Create a memory buffer to extract the PKCS#7 container
    BIO *bio_p7 = BIO_new(BIO_s_mem());
    BIO_write(bio_p7, [data bytes], (int) [data length]);
    PKCS7 *pkcs7 = d2i_PKCS7_bio(bio_p7, NULL);
    if (!pkcs7) {
        goto bail;
    }
    
    // Check that the signature is ok
    if (!PKCS7_type_is_signed(pkcs7)) {
        goto bail;
    }
    
    // Check that the container has actual data
    if (!PKCS7_type_is_data(pkcs7->d.sign->contents)) {
        goto bail;
    }

    result = YES;
    
bail:
    if (pkcs7) free(pkcs7);
    if (bio_p7) free(bio_p7);
    
    return result;
}

- (void)parseData:(NSData *)data {
    // Create a memory buffer to extract the PKCS#7 container
    BIO *bio_p7 = BIO_new(BIO_s_mem());
    BIO_write(bio_p7, [data bytes], (int) [data length]);
    PKCS7 *pkcs7 = d2i_PKCS7_bio(bio_p7, NULL);
    if (!pkcs7) {
        goto bail;
    }

    // Check that the signature is ok
    if (!PKCS7_type_is_signed(pkcs7)) {
        goto bail;
    }
    
    // Check that the container has actual data
    if (!PKCS7_type_is_data(pkcs7->d.sign->contents)) {
        goto bail;
    }
    
    // Get a pointer to the data
    ASN1_OCTET_STRING *content = pkcs7->d.sign->contents->d.data;
    const unsigned char *ptr = content->data;
    const unsigned char *end = ptr + content->length;
    
    self->_dictionary = [[self class] dictionaryWithASN1:ptr ofLength:end];
    
bail:
    free(pkcs7);
    free(bio_p7);
}

+ (NSMutableDictionary *)dictionaryWithASN1:(const unsigned char *)ptr ofLength:(const unsigned char *)end {
    int type;
    int xclass;
    long length;
    
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

    // Decode payload from ASN.1
    ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
    if (type != V_ASN1_SET) {
        NSLog(@"Failed to parse set");
        goto bail;
    }
    
    while (ptr < end) {
        // Parse attribute sequence
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_SEQUENCE) {
            NSLog(@"Failed to parse sequence");
            goto bail;
        }
        
        const unsigned char *seq_end = ptr + length;
        int attr_type = 0;
        //int attr_version = 0;
        
        // Parse the attribute type
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_INTEGER) {
            NSLog(@"Failed to parse type");
            goto bail;
        }
        attr_type = [[self class] decodeInt:ptr ofLength:length];
        ptr += length;
        
        // Parse the attribute version
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_INTEGER) {
            NSLog(@"Failed to parse version");
            goto bail;
        }
        //attr_version = [[self class] decodeInt:ptr ofLength:length];
        ptr += length;
        
        // Check the attribute value
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_OCTET_STRING) {
            NSLog(@"Failed to parse value");
            goto bail;
        }
        
        id key = [NSNumber numberWithInteger:attr_type];
        id value = nil;
        
        switch (attr_type) {
                // Attributes encoded as ASN.1 UTF8STRING
            case ReceiptAttributeTypeBundleId:
            case ReceiptAttributeTypeBundleVersion:
            case ReceiptAttributeTypeOriginalApplicationVersion:
            case InAppAttributeTypeProductIdentifer:
            case InAppAttributeTypeTransactionIdentifer:
            case InAppAttributeTypeOriginalTransactionIdentifer:
            {
                int str_type = 0;
                long str_length = 0;
                const unsigned char *str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &xclass, seq_end - str_ptr);
                if (str_type != V_ASN1_UTF8STRING) {
                    goto bail;
                }
                value = [[NSString alloc] initWithBytes:(const void *)str_ptr length:str_length encoding:NSUTF8StringEncoding];
                break;
            }
                
                // Attributes encoded as ASN.1 IA5STRING
            case ReceiptAttributeTypeExpirationDate:
            case InAppAttributeTypeCancellationDate:
            case InAppAttributeTypeOriginalPurchaseDate:
            case InAppAttributeTypePurchaseDate:
            case InAppAttributeTypeSubscriptionExpirationDate:
            {
                int str_type = 0;
                long str_length = 0;
                const unsigned char *str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &xclass, seq_end - str_ptr);
                if (str_type != V_ASN1_IA5STRING) {
                    goto bail;
                }
                value = [[NSString alloc] initWithBytes:(const void *)str_ptr length:str_length encoding:NSASCIIStringEncoding];
                break;
            }
                
                // Attributes encoded as ASN.1 INTEGER
            case InAppAttributeTypeQuantity:
            case InAppAttributeTypeWebOrderLineItemId:
            {
                int num_type = 0;
                long num_length = 0;
                const unsigned char *num_ptr = ptr;
                ASN1_get_object(&num_ptr, &num_length, &num_type, &xclass, seq_end - num_ptr);
                if (num_type != V_ASN1_INTEGER) {
                    goto bail;
                }
                int number = [[self class] decodeInt:num_ptr ofLength:num_length];
                value = [NSNumber numberWithInt:number];
                break;
            }
                
                // Attributes encoded as ASN.1 OCTETSTRING
            case ReceiptAttributeTypeOpaqueValue:
            case ReceiptAttributeTypeHash:
            {
                value = [NSData dataWithBytes:(const char*)ptr length:length];
                break;
            }
                
                // Attributes encoded as ASN.1 SET
            case ReceiptAttributeTypeInAppPurchase:
            {
                NSDictionary *dictionary = [[self class] dictionaryWithASN1:ptr ofLength:(ptr + length)];
                NSMutableArray *array = [result objectForKey:key];
                if (!array) {
                    array = [NSMutableArray array];
                }
                [array addObject:dictionary];
                value = array;
                break;
            }
                
            default:
                break;
        }
        
        if (value) {
            [result setObject:value forKey:key];
        }

        // Move past the attribute
        ptr += length;
    }
    
bail:
    return result;
}

+ (int)decodeInt:(const unsigned char *)data ofLength:(long) length {
    const unsigned char *ptr = data;
    size_t size = length;
    int payload = 0;
    do {
        payload <<= 8;
        payload += (uint8_t) *ptr++;
    } while(--size > 0);
    return payload;
}

@end