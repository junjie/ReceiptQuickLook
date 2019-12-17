//
// Receipt QuickLook Plugin.
// Copyright (c) 2013-2018 Laurent Etiemble.
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
#import <openssl/asn1.h>
#import <openssl/bio.h>
#import <openssl/objects.h>
#import <openssl/pkcs7.h>
#import <openssl/x509.h>
#import <Foundation/Foundation.h>

/**
 * @brief Keys for each receipt attribute
 */
typedef enum _ReceiptAttributeType {
	/** @brief Undocumented: Receipt Type. The type of receipt generated. The value corresponds to the environment in which the app or VPP purchase was made.
	 
	Possible values: Production, ProductionVPP, ProductionSandbox, ProductionVPPSandbox */
	ReceiptAttribute_UNDOCUMENTED_TypeReceiptType = 0,
	/** @brief Undocumented: Generated by App Store Connect and used by the App Store to uniquely identify the app purchased. Apps are assigned this identifier only in production. Treat this value as a 64-bit long integer.
	 
	 Apps are assigned an identifier only in the production environment, so this key is not present for receipts created in the test environment. This field is not present for Mac apps */
	ReceiptAttribute_UNDOCUMENTED_TypeAppItemId = 1,
    /** @brief Bundle identifier */
    ReceiptAttributeTypeBundleId = 2,
    /** @brief Application version */
    ReceiptAttributeTypeBundleVersion = 3,
    /** @brief Opaque value */
    ReceiptAttributeTypeOpaqueValue = 4,
    /** @brief Hash value */
    ReceiptAttributeTypeHash = 5,
	/** @brief Unknown: integer type 9 */
	ReceiptAttribute_UNKNOWN_Type9 = 9,
	/** @brief Unknown: integer type 11 */
	ReceiptAttribute_UNKNOWN_Type11 = 11,
    /** @brief Creation date */
    ReceiptAttributeTypeCreationDate = 12,
	/** @brief Unknown: integer type 13 */
	ReceiptAttribute_UNKNOWN_Type13 = 13,
	/** @brief Unknown: integer type 14 */
	ReceiptAttribute_UNKNOWN_Type14 = 14,
	/** @brief Undocumented: A unique identifier for the app download transaction. */
	ReceiptAttribute_UNDOCUMENTED_TypeDownloadId = 15,
	/** @brief Undocumented: External Version Identifier, An arbitrary number that identifies a revision of your app. In the sandbox, this key's value is “0”. */
	ReceiptAttribute_UNDOCUMENTED_TypeExternalVersionIdentifier = 16,
    /** @brief In-app purchase receipt */
    ReceiptAttributeTypeInAppPurchase = 17,
    /** @brief Undocumented: The time of the original app purchase, in a date-time format similar to ISO 8601. */
    ReceiptAttribute_UNDOCUMENTED_TypeOriginalPurchaseDate = 18,
    /** @brief Original Application Version */
    ReceiptAttributeTypeOriginalApplicationVersion = 19,
    /** @brief Receipt Expiration Date */
    ReceiptAttributeTypeExpirationDate = 21,
	/** @brief Unknown: integer type 25 */
	ReceiptAttribute_UNKNOWN_Type25 = 25,
    /** @brief Quantity */
    InAppAttributeTypeQuantity = 1701,
    /** @brief Product identifier */
    InAppAttributeTypeProductIdentifer = 1702,
    /** @brief Transaction identifier */
    InAppAttributeTypeTransactionIdentifer = 1703,
    /** @brief Purchase date */
    InAppAttributeTypePurchaseDate = 1704,
    /** @brief Original transaction identifier */
    InAppAttributeTypeOriginalTransactionIdentifer = 1705,
    /** @brief Original purchase date */
    InAppAttributeTypeOriginalPurchaseDate = 1706,
	/** @brief Unknown: integer type 1707 */
    InAppAttributeType_UNKNOWN_Type1707 = 1707,
    /** @brief Subscription Expiration Date */
    InAppAttributeTypeSubscriptionExpirationDate = 1708,
	/** @brief Unknown: integer type 1710 */
    InAppAttributeType_UNKNOWN_Type1710 = 1710,
    /** @brief Web Order Line Item ID */
    InAppAttributeTypeWebOrderLineItemId = 1711,
    /** @brief Cancellation Date */
    InAppAttributeTypeCancellationDate = 1712,
	/** @brief Unknown: integer type 1713 */
    InAppAttributeType_UNKNOWN_Type1713 = 1713,
    /** @brief Subscription Introductory Price Period */
    InAppAttributeTypeSubscriptionIntroductoryPricePeriod = 1719,
} ReceiptAttributeType;

/**
 * @brief Wrapper class around a cryptographic receipt generated by the App Stores.
 */
@interface Receipt : NSObject {
    NSArray *_certificates;
    NSArray *_signers;
    NSDictionary *_dictionary;
}

/**
 * @brief Initialize this instance with the receipt's data.
 * @param data The receipt's data
 * @return A wrapper instance
 */
- (id)initWithData:(NSData *)data;

/**
 * @brief Return an array of dictionaries that contains all the parsed certificates of the receipt.
 * @return An array of dictionaries.
 */
- (NSArray *)certificates;

/**
 * @brief Return an array of dictionaries that contains all the parsed signers certificates of the receipt.
 * @return An array of dictionaries.
 */
- (NSArray *)signers;

/**
 * @brief Return a dictionary that contains all the parsed attributes of the receipt.
 * @return A dictionary containing the attributes.
 */
- (NSDictionary *)dictionary;

/**
 * @brief Performs a preliminary parsing to check if the data may be a cryptographic receipt.
 * @param data The receipt's data
 * @return YES if the data may be a valid cryptographic receipt; NO otherwise.
 */
+ (BOOL)looksLikeAReceiptFile:(NSData *)data;

@end
