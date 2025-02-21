/******************************************************************************
 *
 * Project:  ASI CEOS Translator
 * Purpose:  CEOS field layout recipes.
 * Author:   Paul Lahaie, pjlahaie@atlsci.com
 *
 ******************************************************************************
 * Copyright (c) 2000, Atlantis Scientific Inc
 *
 * SPDX-License-Identifier: MIT
 ****************************************************************************/

#include "ceos.h"

/* Array of Datatypes and their names/values */

typedef struct
{
    const char *String;
    int Type;
} CeosStringType_t;

typedef struct
{
    int (*function)(CeosSARVolume_t *volume, const void *token);
    const void *token;
    const char *name;
} RecipeFunctionData_t;

static const CeosStringType_t CeosDataType[] = {
    {"IU1", CEOS_TYP_UCHAR},
    {"IU2", CEOS_TYP_USHORT},
    {"UI1", CEOS_TYP_UCHAR},
    {"UI2", CEOS_TYP_USHORT},
    {"CI*2", CEOS_TYP_COMPLEX_CHAR},
    {"CI*4", CEOS_TYP_COMPLEX_SHORT},
    {"CIS4", CEOS_TYP_COMPLEX_SHORT},
    {"CI*8", CEOS_TYP_COMPLEX_LONG},
    {"C*8", CEOS_TYP_COMPLEX_FLOAT},
    {"R*4", CEOS_TYP_FLOAT},
    {NULL, 0}};

static const CeosStringType_t CeosInterleaveType[] = {{"BSQ", CEOS_IL_BAND},
                                                      {" BSQ", CEOS_IL_BAND},
                                                      {"BIL", CEOS_IL_LINE},
                                                      {" BIL", CEOS_IL_LINE},
                                                      {NULL, 0}};

#define IMAGE_OPT                                                              \
    {                                                                          \
        63, 192, 18, 18                                                        \
    }
#define IMAGE_JERS_OPT                                                         \
    {                                                                          \
        50, 192, 18, 18                                                        \
    } /* Some JERS data uses this instead of IMAGE_OPT */
#define PROC_DATA_REC                                                          \
    {                                                                          \
        50, 11, 18, 20                                                         \
    }
#define PROC_DATA_REC_ALT                                                      \
    {                                                                          \
        50, 11, 31, 20                                                         \
    }
#define PROC_DATA_REC_ALT2                                                     \
    {                                                                          \
        50, 11, 31, 50                                                         \
    } /* Some cases of ERS 1, 2 */
#define DATA_SET_SUMMARY                                                       \
    {                                                                          \
        18, 10, 18, 20                                                         \
    }

/* NOTE: This seems to be the generic recipe used for most things */
static const CeosRecipeType_t RadarSatRecipe[] = {
    {CEOS_REC_NUMCHANS, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 233, 4,
     CEOS_REC_TYP_I}, /* Number of channels */
    {CEOS_REC_INTERLEAVE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 269, 4,
     CEOS_REC_TYP_A}, /* Interleaving type */
    {CEOS_REC_DATATYPE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 429, 4,
     CEOS_REC_TYP_A}, /* Data type */
    {CEOS_REC_BPR, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 0, 0,
     CEOS_REC_TYP_A}, /* For Defeault CEOS, this is done using other vals */
    {CEOS_REC_LINES, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 237, 8,
     CEOS_REC_TYP_I}, /* How many lines */
    {CEOS_REC_TBP, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 261, 4, CEOS_REC_TYP_I},
    {CEOS_REC_BBP, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 265, 4,
     CEOS_REC_TYP_I}, /* Bottom border pixels */
    {CEOS_REC_PPL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 249, 8,
     CEOS_REC_TYP_I}, /* Pixels per line */
    {CEOS_REC_LBP, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 245, 4,
     CEOS_REC_TYP_I}, /* Left Border Pixels */
    {CEOS_REC_RBP, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 257, 4,
     CEOS_REC_TYP_I}, /* Right Border Pixels */
    {CEOS_REC_BPP, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 225, 4,
     CEOS_REC_TYP_I}, /* Bytes Per Pixel */
    {CEOS_REC_RPL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 273, 2,
     CEOS_REC_TYP_I}, /* Records per line */
    {CEOS_REC_PPR, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 0, 0,
     CEOS_REC_TYP_I}, /* Pixels Per Record -- need to fill record type */
    {CEOS_REC_PDBPR, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 281, 8,
     CEOS_REC_TYP_I}, /* pixel data bytes per record */
    {CEOS_REC_IDS, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 277, 4,
     CEOS_REC_TYP_I}, /* Prefix data per record */
    {CEOS_REC_FDL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 9, 4,
     CEOS_REC_TYP_B}, /* Length of Imagry Options Header */
    {CEOS_REC_PIXORD, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 0, 0,
     CEOS_REC_TYP_I}, /* Must be calculated */
    {CEOS_REC_LINORD, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 0, 0,
     CEOS_REC_TYP_I}, /* Must be calculated */
    {CEOS_REC_PRODTYPE, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 0, 0,
     CEOS_REC_TYP_I},

    {CEOS_REC_RECORDSIZE, 1, CEOS_IMAGRY_OPT_FILE, PROC_DATA_REC, 9, 4,
     CEOS_REC_TYP_B}, /* The processed image record size */

    /* Some ERS-1 products use an alternate data record subtype2. */
    {CEOS_REC_RECORDSIZE, 1, CEOS_IMAGRY_OPT_FILE, PROC_DATA_REC_ALT, 9, 4,
     CEOS_REC_TYP_B}, /* The processed image record size */

    /* Yet another ERS-1 and ERS-2 alternate data record subtype2. */
    {CEOS_REC_RECORDSIZE, 1, CEOS_IMAGRY_OPT_FILE, PROC_DATA_REC_ALT2, 9, 4,
     CEOS_REC_TYP_B}, /* The processed image record size */

    {CEOS_REC_SUFFIX_SIZE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 289, 4,
     CEOS_REC_TYP_I},                /* Suffix data per record */
    {0, 0, 0, {0, 0, 0, 0}, 0, 0, 0} /* Last record is Zero */
};

static const CeosRecipeType_t JersRecipe[] = {
    {CEOS_REC_NUMCHANS, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 233, 4,
     CEOS_REC_TYP_I}, /* Number of channels */
    {CEOS_REC_INTERLEAVE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 269, 4,
     CEOS_REC_TYP_A}, /* Interleaving type */
    {CEOS_REC_DATATYPE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 429, 4,
     CEOS_REC_TYP_A}, /* Data type */
    {CEOS_REC_BPR, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 0, 0,
     CEOS_REC_TYP_A}, /* For Defeault CEOS, this is done using other vals */
    {CEOS_REC_LINES, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 237, 8,
     CEOS_REC_TYP_I}, /* How many lines */
    {CEOS_REC_TBP, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 261, 4,
     CEOS_REC_TYP_I},
    {CEOS_REC_BBP, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 265, 4,
     CEOS_REC_TYP_I}, /* Bottom border pixels */
    {CEOS_REC_PPL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 249, 8,
     CEOS_REC_TYP_I}, /* Pixels per line */
    {CEOS_REC_LBP, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 245, 4,
     CEOS_REC_TYP_I}, /* Left Border Pixels */
    {CEOS_REC_RBP, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 257, 4,
     CEOS_REC_TYP_I}, /* Isn't available for RadarSAT */
    {CEOS_REC_BPP, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 225, 4,
     CEOS_REC_TYP_I}, /* Bytes Per Pixel */
    {CEOS_REC_RPL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 273, 2,
     CEOS_REC_TYP_I}, /* Records per line */
    {CEOS_REC_PPR, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 0, 0,
     CEOS_REC_TYP_I}, /* Pixels Per Record -- need to fill record type */
    {CEOS_REC_PDBPR, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 281, 8,
     CEOS_REC_TYP_I}, /* pixel data bytes per record */
    {CEOS_REC_IDS, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 277, 4,
     CEOS_REC_TYP_I}, /* Prefix data per record */
    {CEOS_REC_FDL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 9, 4,
     CEOS_REC_TYP_B}, /* Length of Imagry Options Header */
    {CEOS_REC_PIXORD, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 0, 0,
     CEOS_REC_TYP_I}, /* Must be calculated */
    {CEOS_REC_LINORD, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 0, 0,
     CEOS_REC_TYP_I}, /* Must be calculated */
    {CEOS_REC_PRODTYPE, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 0, 0,
     CEOS_REC_TYP_I},

    {CEOS_REC_RECORDSIZE, 1, CEOS_IMAGRY_OPT_FILE, PROC_DATA_REC, 9, 4,
     CEOS_REC_TYP_B}, /* The processed image record size */

    {CEOS_REC_SUFFIX_SIZE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_JERS_OPT, 289, 4,
     CEOS_REC_TYP_I},                /* Suffix data per record */
    {0, 0, 0, {0, 0, 0, 0}, 0, 0, 0} /* Last record is Zero */
};

static const CeosRecipeType_t ScanSARRecipe[] = {
    {CEOS_REC_NUMCHANS, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 233, 4,
     CEOS_REC_TYP_I}, /* Number of channels */
    {CEOS_REC_INTERLEAVE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 269, 4,
     CEOS_REC_TYP_A}, /* Interleaving type */
    {CEOS_REC_DATATYPE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 429, 4,
     CEOS_REC_TYP_A}, /* Data type */
    {CEOS_REC_LINES, 1, CEOS_ANY_FILE, DATA_SET_SUMMARY, 325, 8,
     CEOS_REC_TYP_I}, /* How many lines */
    {CEOS_REC_PPL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 249, 8,
     CEOS_REC_TYP_I}, /* Pixels per line */
    {CEOS_REC_BPP, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 225, 4,
     CEOS_REC_TYP_I}, /* Bytes Per Pixel */
    {CEOS_REC_RPL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 273, 2,
     CEOS_REC_TYP_I}, /* Records per line */
    {CEOS_REC_IDS, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 277, 4,
     CEOS_REC_TYP_I}, /* Prefix data per record */
    {CEOS_REC_FDL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 9, 4,
     CEOS_REC_TYP_B}, /* Length of Imagry Options Header */
    {CEOS_REC_RECORDSIZE, 1, CEOS_IMAGRY_OPT_FILE, PROC_DATA_REC, 9, 4,
     CEOS_REC_TYP_B}, /* The processed image record size */
    {CEOS_REC_SUFFIX_SIZE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 289, 4,
     CEOS_REC_TYP_I},                /* Suffix data per record */
    {0, 0, 0, {0, 0, 0, 0}, 0, 0, 0} /* Last record is Zero */
};

static const CeosRecipeType_t SIRCRecipe[] = {
    {CEOS_REC_NUMCHANS, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 233, 4,
     CEOS_REC_TYP_I}, /* Number of channels */
    {CEOS_REC_INTERLEAVE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 269, 4,
     CEOS_REC_TYP_A}, /* Interleaving type */
    {CEOS_REC_DATATYPE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 429, 4,
     CEOS_REC_TYP_A}, /* Data type */
    {CEOS_REC_LINES, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 237, 8,
     CEOS_REC_TYP_I}, /* How many lines */
    {CEOS_REC_TBP, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 261, 4, CEOS_REC_TYP_I},
    {CEOS_REC_BBP, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 265, 4,
     CEOS_REC_TYP_I}, /* Bottom border pixels */
    {CEOS_REC_PPL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 249, 8,
     CEOS_REC_TYP_I}, /* Pixels per line */
    {CEOS_REC_LBP, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 245, 4,
     CEOS_REC_TYP_I}, /* Left Border Pixels */
    {CEOS_REC_RBP, 0, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 257, 4,
     CEOS_REC_TYP_I}, /* Right Border Pixels */
    {CEOS_REC_BPP, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 225, 4,
     CEOS_REC_TYP_I}, /* Bytes Per Pixel */
    {CEOS_REC_RPL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 273, 2,
     CEOS_REC_TYP_I}, /* Records per line */
    {CEOS_REC_IDS, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 277, 4,
     CEOS_REC_TYP_I}, /* Prefix data per record */
    {CEOS_REC_FDL, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 9, 4,
     CEOS_REC_TYP_B}, /* Length of Imagry Options Header */
    {CEOS_REC_RECORDSIZE, 1, CEOS_IMAGRY_OPT_FILE, PROC_DATA_REC, 9, 4,
     CEOS_REC_TYP_B}, /* The processed image record size */
    {CEOS_REC_SUFFIX_SIZE, 1, CEOS_IMAGRY_OPT_FILE, IMAGE_OPT, 289, 4,
     CEOS_REC_TYP_I}, /* Suffix data per record */

    {0, 0, 0, {0, 0, 0, 0}, 0, 0, 0} /* Last record is Zero */
};

#undef PROC_DATA_REC

static void ExtractInt(CeosRecord_t *record, int type, unsigned int offset,
                       unsigned int length, int *value);

static char *ExtractString(CeosRecord_t *record, unsigned int offset,
                           unsigned int length, char *string);

static int GetCeosStringType(const CeosStringType_t *CeosType,
                             const char *string);

static int SIRCRecipeFCN(CeosSARVolume_t *volume, const void *token);
static int PALSARRecipeFCN(CeosSARVolume_t *volume, const void *token);

Link_t *RecipeFunctions = NULL;

void RegisterRecipes(void)
{

    AddRecipe(SIRCRecipeFCN, SIRCRecipe, "SIR-C");
    AddRecipe(ScanSARRecipeFCN, ScanSARRecipe, "ScanSAR");
    AddRecipe(CeosDefaultRecipe, RadarSatRecipe, "RadarSat");
    AddRecipe(CeosDefaultRecipe, JersRecipe, "Jers");
    AddRecipe(PALSARRecipeFCN, RadarSatRecipe, "PALSAR-ALOS");
    /*  AddRecipe( CeosDefaultRecipe, AtlantisRecipe ); */
}

void FreeRecipes(void)

{
    Link_t *l_link;

    for (l_link = RecipeFunctions; l_link != NULL; l_link = l_link->next)
        HFree(l_link->object);

    DestroyList(RecipeFunctions);
    RecipeFunctions = NULL;
}

void AddRecipe(int (*function)(CeosSARVolume_t *volume, const void *token),
               const void *token, const char *name)
{

    RecipeFunctionData_t *TempData;

    Link_t *Link;

    TempData = HMalloc(sizeof(RecipeFunctionData_t));

    TempData->function = function;
    TempData->token = token;
    TempData->name = name;

    Link = ceos2CreateLink(TempData);

    if (RecipeFunctions == NULL)
    {
        RecipeFunctions = Link;
    }
    else
    {
        RecipeFunctions = InsertLink(RecipeFunctions, Link);
    }
}

int CeosDefaultRecipe(CeosSARVolume_t *volume, const void *token)
{
    const CeosRecipeType_t *recipe;
    CeosRecord_t *record;
    CeosTypeCode_t TypeCode = {0};
    struct CeosSARImageDesc *ImageDesc = &(volume->ImageDesc);
    char temp_str[1024];
    int i /*, temp_int */;

#define DoExtractInt(a)                                                        \
    ExtractInt(record, recipe[i].Type, recipe[i].Offset, recipe[i].Length, &a)

    if (token == NULL)
    {
        return 0;
    }

    memset(ImageDesc, 0, sizeof(struct CeosSARImageDesc));

    /*    temp_imagerecipe = (CeosSARImageDescRecipe_t *) token;
        recipe = temp_imagerecipe->Recipe; */

    recipe = token;

    for (i = 0; recipe[i].ImageDescValue != 0; i++)
    {
        if (recipe[i].Override)
        {
            TypeCode.UCharCode.Subtype1 = recipe[i].TypeCode.Subtype1;
            TypeCode.UCharCode.Type = recipe[i].TypeCode.Type;
            TypeCode.UCharCode.Subtype2 = recipe[i].TypeCode.Subtype2;
            TypeCode.UCharCode.Subtype3 = recipe[i].TypeCode.Subtype3;

            record = FindCeosRecord(volume->RecordList, TypeCode,
                                    recipe[i].FileId, -1, -1);

            if (record == NULL)
            {
                /* temp_int = 0; */
            }
            else
            {

                switch (recipe[i].ImageDescValue)
                {
                    case CEOS_REC_NUMCHANS:
                        DoExtractInt(ImageDesc->NumChannels);
                        break;
                    case CEOS_REC_LINES:
                        DoExtractInt(ImageDesc->Lines);
                        break;
                    case CEOS_REC_BPP:
                        DoExtractInt(ImageDesc->BytesPerPixel);
                        break;
                    case CEOS_REC_RPL:
                        DoExtractInt(ImageDesc->RecordsPerLine);
                        break;
                    case CEOS_REC_PDBPR:
                        DoExtractInt(ImageDesc->PixelDataBytesPerRecord);
                        break;
                    case CEOS_REC_FDL:
                        DoExtractInt(ImageDesc->FileDescriptorLength);
                        break;
                    case CEOS_REC_IDS:
                        DoExtractInt(ImageDesc->ImageDataStart);
                        /*
                        ** This is really reading the quantity of prefix data
                        ** per data record.  We want the offset from the very
                        ** beginning of the record to the data, so we add
                        *another
                        ** 12 to that.  I think some products incorrectly
                        *indicate
                        ** 192 (prefix+12) instead of 180 so if we see 192
                        *assume
                        ** the 12 bytes of record start data has already been
                        ** added.  Frank Warmerdam.
                        */
                        if (ImageDesc->ImageDataStart != 192)
                            ImageDesc->ImageDataStart += 12;
                        break;
                    case CEOS_REC_SUFFIX_SIZE:
                        DoExtractInt(ImageDesc->ImageSuffixData);
                        break;
                    case CEOS_REC_RECORDSIZE:
                        DoExtractInt(ImageDesc->BytesPerRecord);
                        break;
                    case CEOS_REC_PPL:
                        DoExtractInt(ImageDesc->PixelsPerLine);
                        break;
                    case CEOS_REC_TBP:
                        DoExtractInt(ImageDesc->TopBorderPixels);
                        break;
                    case CEOS_REC_BBP:
                        DoExtractInt(ImageDesc->BottomBorderPixels);
                        break;
                    case CEOS_REC_LBP:
                        DoExtractInt(ImageDesc->LeftBorderPixels);
                        break;
                    case CEOS_REC_RBP:
                        DoExtractInt(ImageDesc->RightBorderPixels);
                        break;
                    case CEOS_REC_INTERLEAVE:
                        ExtractString(record, recipe[i].Offset,
                                      recipe[i].Length, temp_str);

                        ImageDesc->ChannelInterleaving =
                            GetCeosStringType(CeosInterleaveType, temp_str);
                        break;
                    case CEOS_REC_DATATYPE:
                        ExtractString(record, recipe[i].Offset,
                                      recipe[i].Length, temp_str);

                        ImageDesc->DataType =
                            GetCeosStringType(CeosDataType, temp_str);
                        break;
                }
            }
        }
    }

    /* Some files (Telaviv) don't record the number of pixel groups per line.
     * Try to derive it from the size of a data group, and the number of
     * bytes of pixel data if necessary.
     */

    if (ImageDesc->PixelsPerLine == 0 &&
        ImageDesc->PixelDataBytesPerRecord != 0 &&
        ImageDesc->BytesPerPixel != 0)
    {
        ImageDesc->PixelsPerLine =
            ImageDesc->PixelDataBytesPerRecord / ImageDesc->BytesPerPixel;
        CPLDebug("SAR_CEOS", "Guessing PixelPerLine to be %d\n",
                 ImageDesc->PixelsPerLine);
    }

    /* Some files don't have the BytesPerRecord stuff, so we calculate it if
     * possible */

    if (ImageDesc->BytesPerRecord == 0 && ImageDesc->RecordsPerLine == 1 &&
        ImageDesc->PixelsPerLine > 0 && ImageDesc->BytesPerPixel > 0)
    {
        CeosRecord_t *img_rec;

        ImageDesc->BytesPerRecord =
            ImageDesc->PixelsPerLine * ImageDesc->BytesPerPixel +
            ImageDesc->ImageDataStart + ImageDesc->ImageSuffixData;

        TypeCode.UCharCode.Subtype1 = 0xed;
        TypeCode.UCharCode.Type = 0xed;
        TypeCode.UCharCode.Subtype2 = 0x12;
        TypeCode.UCharCode.Subtype3 = 0x12;

        img_rec = FindCeosRecord(volume->RecordList, TypeCode,
                                 CEOS_IMAGRY_OPT_FILE, -1, -1);
        if (img_rec == NULL)
        {
            CPLDebug("SAR_CEOS",
                     "Unable to find imagery rec to check record length.");
            return 0;
        }

        if (img_rec->Length != ImageDesc->BytesPerRecord)
        {
            CPLDebug("SAR_CEOS",
                     "Guessed record length (%d) did not match\n"
                     "actual imagery record length (%d), recipe fails.",
                     ImageDesc->BytesPerRecord, img_rec->Length);
            return 0;
        }
    }

    if (ImageDesc->PixelsPerRecord == 0 && ImageDesc->BytesPerRecord != 0 &&
        ImageDesc->BytesPerPixel != 0)
    {
        ImageDesc->PixelsPerRecord =
            ((ImageDesc->BytesPerRecord -
              (ImageDesc->ImageSuffixData + ImageDesc->ImageDataStart)) /
             ImageDesc->BytesPerPixel);

        if (ImageDesc->PixelsPerRecord > ImageDesc->PixelsPerLine)
            ImageDesc->PixelsPerRecord = ImageDesc->PixelsPerLine;
    }

    /* If we didn't get a data type, try guessing. */
    if (ImageDesc->DataType == 0 && ImageDesc->BytesPerPixel != 0 &&
        ImageDesc->NumChannels != 0)
    {
        int nDataTypeSize = ImageDesc->BytesPerPixel / ImageDesc->NumChannels;

        if (nDataTypeSize == 1)
            ImageDesc->DataType = CEOS_TYP_UCHAR;
        else if (nDataTypeSize == 2)
            ImageDesc->DataType = CEOS_TYP_USHORT;
    }

    /* Sanity checking */

    if (ImageDesc->PixelsPerLine == 0 || ImageDesc->Lines == 0 ||
        ImageDesc->RecordsPerLine == 0 || ImageDesc->ImageDataStart == 0 ||
        ImageDesc->FileDescriptorLength == 0 || ImageDesc->DataType == 0 ||
        ImageDesc->NumChannels == 0 || ImageDesc->BytesPerPixel == 0 ||
        ImageDesc->ChannelInterleaving == 0 || ImageDesc->BytesPerRecord == 0)
    {
        return 0;
    }
    else
    {

        ImageDesc->ImageDescValid = TRUE;
        return 1;
    }
}

int ScanSARRecipeFCN(CeosSARVolume_t *volume, const void *token)
{
    struct CeosSARImageDesc *ImageDesc = &(volume->ImageDesc);

    memset(ImageDesc, 0, sizeof(struct CeosSARImageDesc));

    if (CeosDefaultRecipe(volume, token))
    {
        ImageDesc->Lines *= 2;
        return 1;
    }

    return 0;
}

static int SIRCRecipeFCN(CeosSARVolume_t *volume, const void *token)
{
    struct CeosSARImageDesc *ImageDesc = &(volume->ImageDesc);
    CeosTypeCode_t TypeCode = {0};
    CeosRecord_t *record;
    char szSARDataFormat[29];

    memset(ImageDesc, 0, sizeof(struct CeosSARImageDesc));

    /* -------------------------------------------------------------------- */
    /*      First, we need to check if the "SAR Data Format Type            */
    /*      identifier" is set to "COMPRESSED CROSS-PRODUCTS" which is      */
    /*      pretty idiosyncratic to SIRC products.  It might also appear    */
    /*      for some other similarly encoded Polarimetric data I suppose.    */
    /* -------------------------------------------------------------------- */
    /* IMAGE_OPT */
    TypeCode.UCharCode.Subtype1 = 63;
    TypeCode.UCharCode.Type = 192;
    TypeCode.UCharCode.Subtype2 = 18;
    TypeCode.UCharCode.Subtype3 = 18;

    record = FindCeosRecord(volume->RecordList, TypeCode, CEOS_IMAGRY_OPT_FILE,
                            -1, -1);
    if (record == NULL)
        return 0;

    ExtractString(record, 401, 28, szSARDataFormat);
    if (!STARTS_WITH_CI(szSARDataFormat, "COMPRESSED CROSS-PRODUCTS"))
        return 0;

    /* -------------------------------------------------------------------- */
    /*      Apply normal handling...                                        */
    /* -------------------------------------------------------------------- */
    CeosDefaultRecipe(volume, token);

    /* -------------------------------------------------------------------- */
    /*      Make sure this looks like the SIRC product we are expecting.    */
    /* -------------------------------------------------------------------- */
    if (ImageDesc->BytesPerPixel != 10)
        return 0;

    /* -------------------------------------------------------------------- */
    /*      Then fix up a few values.                                       */
    /* -------------------------------------------------------------------- */
    /* It seems the bytes of pixel data per record is just wrong.  Fix. */
    ImageDesc->PixelDataBytesPerRecord =
        ImageDesc->BytesPerPixel * ImageDesc->PixelsPerLine;

    ImageDesc->DataType = CEOS_TYP_CCP_COMPLEX_FLOAT;

    /* -------------------------------------------------------------------- */
    /*      Sanity checking                                                 */
    /* -------------------------------------------------------------------- */
    if (ImageDesc->PixelsPerLine == 0 || ImageDesc->Lines == 0 ||
        ImageDesc->RecordsPerLine == 0 || ImageDesc->ImageDataStart == 0 ||
        ImageDesc->FileDescriptorLength == 0 || ImageDesc->DataType == 0 ||
        ImageDesc->NumChannels == 0 || ImageDesc->BytesPerPixel == 0 ||
        ImageDesc->ChannelInterleaving == 0 || ImageDesc->BytesPerRecord == 0)
    {
        return 0;
    }
    else
    {
        ImageDesc->ImageDescValid = TRUE;
        return 1;
    }
}

static int PALSARRecipeFCN(CeosSARVolume_t *volume, const void *token)
{
    struct CeosSARImageDesc *ImageDesc = &(volume->ImageDesc);
    CeosTypeCode_t TypeCode = {0};
    CeosRecord_t *record;
    char szSARDataFormat[29], szProduct[32];

    memset(ImageDesc, 0, sizeof(struct CeosSARImageDesc));

    /* -------------------------------------------------------------------- */
    /*      First, we need to check if the "SAR Data Format Type            */
    /*      identifier" is set to "COMPRESSED CROSS-PRODUCTS" which is      */
    /*      pretty idiosyncratic to SIRC products.  It might also appear    */
    /*      for some other similarly encoded Polarimetric data I suppose.    */
    /* -------------------------------------------------------------------- */
    /* IMAGE_OPT */
    TypeCode.UCharCode.Subtype1 = 63;
    TypeCode.UCharCode.Type = 192;
    TypeCode.UCharCode.Subtype2 = 18;
    TypeCode.UCharCode.Subtype3 = 18;

    record = FindCeosRecord(volume->RecordList, TypeCode, CEOS_IMAGRY_OPT_FILE,
                            -1, -1);
    if (record == NULL)
        return 0;

    ExtractString(record, 401, 28, szSARDataFormat);
    if (!STARTS_WITH_CI(szSARDataFormat, "INTEGER*18                 "))
        return 0;

    ExtractString(record, 49, 16, szProduct);
    if (!STARTS_WITH_CI(szProduct, "ALOS-"))
        return 0;

    /* -------------------------------------------------------------------- */
    /*      Apply normal handling...                                        */
    /* -------------------------------------------------------------------- */
    CeosDefaultRecipe(volume, token);

    /* -------------------------------------------------------------------- */
    /*      Make sure this looks like the SIRC product we are expecting.    */
    /* -------------------------------------------------------------------- */
    if (ImageDesc->BytesPerPixel != 18)
        return 0;

    /* -------------------------------------------------------------------- */
    /*      Then fix up a few values.                                       */
    /* -------------------------------------------------------------------- */
    ImageDesc->DataType = CEOS_TYP_PALSAR_COMPLEX_SHORT;
    ImageDesc->NumChannels = 6;

    /* -------------------------------------------------------------------- */
    /*      Sanity checking                                                 */
    /* -------------------------------------------------------------------- */
    if (ImageDesc->PixelsPerLine == 0 || ImageDesc->Lines == 0 ||
        ImageDesc->RecordsPerLine == 0 || ImageDesc->ImageDataStart == 0 ||
        ImageDesc->FileDescriptorLength == 0 || ImageDesc->DataType == 0 ||
        ImageDesc->NumChannels == 0 || ImageDesc->BytesPerPixel == 0 ||
        ImageDesc->ChannelInterleaving == 0 || ImageDesc->BytesPerRecord == 0)
    {
        return 0;
    }
    else
    {
        ImageDesc->ImageDescValid = TRUE;
        return 1;
    }
}

void GetCeosSARImageDesc(CeosSARVolume_t *volume)
{
    Link_t *l_link;
    RecipeFunctionData_t *rec_data;
    int (*function)(CeosSARVolume_t * volume, const void *token);

    if (RecipeFunctions == NULL)
    {
        RegisterRecipes();
    }

    if (RecipeFunctions == NULL)
    {
        return;
    }

    for (l_link = RecipeFunctions; l_link != NULL; l_link = l_link->next)
    {
        if (l_link->object)
        {
            rec_data = l_link->object;
            function = rec_data->function;
            if ((*function)(volume, rec_data->token))
            {
                CPLDebug("CEOS", "Using recipe '%s'.", rec_data->name);
                return;
            }
        }
    }

    return;
}

static void ExtractInt(CeosRecord_t *record, int type, unsigned int offset,
                       unsigned int length, int *value)
{
    void *buffer;
    char format[32];

    buffer = HMalloc(length + 1);

    switch (type)
    {
        case CEOS_REC_TYP_A:
            snprintf(format, sizeof(format), "A%u", length);
            GetCeosField(record, offset, format, buffer);
            *value = atoi(buffer);
            break;
        case CEOS_REC_TYP_B:
            snprintf(format, sizeof(format), "B%u", length);
#ifdef notdef
            GetCeosField(record, offset, format, buffer);
            if (length <= 4)
                CeosToNative(value, buffer, length, length);
            else
                *value = 0;
#else
            GetCeosField(record, offset, format, value);
#endif
            break;
        case CEOS_REC_TYP_I:
            snprintf(format, sizeof(format), "I%u", length);
            GetCeosField(record, offset, format, value);
            break;
    }

    HFree(buffer);
}

static char *ExtractString(CeosRecord_t *record, unsigned int offset,
                           unsigned int length, char *string)
{
    char format[12];

    if (string == NULL)
    {
        string = HMalloc(length + 1);
    }

    snprintf(format, sizeof(format), "A%u", length);

    GetCeosField(record, offset, format, string);

    return string;
}

static int GetCeosStringType(const CeosStringType_t *CeosStringType,
                             const char *string)
{
    int i;

    for (i = 0; CeosStringType[i].String != NULL; i++)
    {
        if (strncmp(CeosStringType[i].String, string,
                    strlen(CeosStringType[i].String)) == 0)
        {
            return CeosStringType[i].Type;
        }
    }

    return 0;
}
