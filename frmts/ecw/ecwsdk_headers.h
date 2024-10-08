/******************************************************************************
 *
 * Project:  GDAL
 * Purpose:  Includes ECW SDK headers
 * Author:   Even Rouault <even dot rouault at spatialys dot com>
 *
 ******************************************************************************
 * Copyright (c) 2015, Even Rouault <even dot rouault at spatialys dot com>
 *
 * SPDX-License-Identifier: MIT
 *****************************************************************************/

#ifndef ECWSDK_HEADERS_H
#define ECWSDK_HEADERS_H

#include "cpl_port.h"

#ifdef HAVE_GCC_SYSTEM_HEADER
#pragma GCC system_header
#endif

// The following is needed on 4.x+ to enable rw support.
#if defined(HAVE_COMPRESS)
#ifndef ECW_COMPRESS_RW_SDK_VERSION
#define ECW_COMPRESS_RW_SDK_VERSION
#endif
#endif

#if defined(_MSC_VER)
#pragma warning(disable : 4800)
#endif

#include <NCSECWClient.h>
#include <NCSECWCompressClient.h>
#include <NCSErrors.h>
#include <NCSFile.h>
#include <NCSJP2FileView.h>

#ifdef HAVE_ECW_BUILDNUMBER_H
#include <ECWJP2BuildNumber.h>
#if !defined(ECW_VERSION)
#define ECWSDK_VERSION (NCS_ECWJP2_VER_MAJOR * 10 + NCS_ECWJP2_VER_MINOR)
#endif
#else
/* By default, assume 3.3 SDK Version. */
#if !defined(ECWSDK_VERSION)
#define ECWSDK_VERSION 33
#endif
#endif

#if ECWSDK_VERSION < 40

#include <NCSJPCFileIOStream.h>
#if !defined(NO_COMPRESS) && !defined(HAVE_COMPRESS)
#define HAVE_COMPRESS
#endif

#else
#if ECWSDK_VERSION >= 50
#if ECWSDK_VERSION >= 51
#define JPEG2000_DOMAIN_NAME "JPEG2000"
#endif
#include <NCSECWHeaderEditor.h>
#include "NCSEcw/SDK/Box.h"
#else
#include <HeaderEditor.h>
#endif
#define NCS_FASTCALL
#endif

#if ECWSDK_VERSION >= 40
#define SDK_CAN_DO_SUPERSAMPLING 1
#endif

#ifndef NCSFILEBASE_H
#include <NCSJP2FileView.h>
#else
#undef CNCSJP2FileView
#define CNCSJP2FileView CNCSFile
#endif

/* Trick to avoid warnings with SDK 3.3 when assigning a NCSError code */
/* to a CNCSError object */
static inline CNCSError GetCNCSError(NCSError nCode)
{
    return CNCSError(nCode);
}

#if ECWSDK_VERSION < 50
/* For NCSStrDup */
#include "NCSUtil.h"
#endif

#endif
