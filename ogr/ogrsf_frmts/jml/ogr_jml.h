/******************************************************************************
 *
 * Project:  JML .jml Translator
 * Purpose:  Definition of classes for OGR JML driver.
 * Author:   Even Rouault, even dot rouault at spatialys dot com
 *
 ******************************************************************************
 * Copyright (c) 2014, Even Rouault <even dot rouault at spatialys dot com>
 *
 * SPDX-License-Identifier: MIT
 ****************************************************************************/

#ifndef OGR_JML_H_INCLUDED
#define OGR_JML_H_INCLUDED

#include "ogrsf_frmts.h"
#include "ogr_p.h"

#ifdef HAVE_EXPAT
#include "ogr_expat.h"
#endif

#include <vector>

class OGRJMLDataset;

#ifdef HAVE_EXPAT

/************************************************************************/
/*                            OGRJMLColumn                              */
/************************************************************************/

class OGRJMLColumn
{
  public:
    CPLString osName;
    CPLString osType;
    CPLString osElementName;
    CPLString osAttributeName;
    CPLString osAttributeValue;
    bool bIsBody; /* if false: attribute */

    OGRJMLColumn() : bIsBody(false)
    {
    }
};

/************************************************************************/
/*                             OGRJMLLayer                              */
/************************************************************************/

class OGRJMLLayer final : public OGRLayer
{
    GDALDataset *m_poDS = nullptr;
    OGRFeatureDefn *poFeatureDefn;

    int nNextFID;
    VSILFILE *fp;
    bool bHasReadSchema;

    XML_Parser oParser;

    int currentDepth;
    bool bStopParsing;
    int nWithoutEventCounter;
    int nDataHandlerCounter;

    bool bAccumulateElementValue;
    char *pszElementValue;
    int nElementValueLen;
    int nElementValueAlloc;

    OGRFeature *poFeature;
    OGRFeature **ppoFeatureTab;
    int nFeatureTabLength;
    int nFeatureTabIndex;

    bool bSchemaFinished;
    int nJCSGMLInputTemplateDepth;
    int nCollectionElementDepth;
    int nFeatureCollectionDepth;
    CPLString osCollectionElement;
    int nFeatureElementDepth;
    CPLString osFeatureElement;
    int nGeometryElementDepth;
    CPLString osGeometryElement;
    int nColumnDepth;
    int nNameDepth;
    int nTypeDepth;
    int nAttributeElementDepth;
    int iAttr;
    int iRGBField;
    CPLString osSRSName;

    OGRJMLColumn oCurColumn;
    std::vector<OGRJMLColumn> aoColumns;

    void AddStringToElementValue(const char *data, int nLen);
    void StopAccumulate();

    void LoadSchema();

  public:
    OGRJMLLayer(const char *pszLayerName, OGRJMLDataset *poDS, VSILFILE *fp);
    ~OGRJMLLayer();

    const char *GetName() override
    {
        return poFeatureDefn->GetName();
    }

    void ResetReading() override;
    OGRFeature *GetNextFeature() override;

    OGRFeatureDefn *GetLayerDefn() override;

    int TestCapability(const char *) override;

    GDALDataset *GetDataset() override
    {
        return m_poDS;
    }

    void startElementCbk(const char *pszName, const char **ppszAttr);
    void endElementCbk(const char *pszName);
    void dataHandlerCbk(const char *data, int nLen);

    void startElementLoadSchemaCbk(const char *pszName, const char **ppszAttr);
    void endElementLoadSchemaCbk(const char *pszName);
};

#endif /* HAVE_EXPAT */

/************************************************************************/
/*                          OGRJMLWriterLayer                           */
/************************************************************************/

class OGRJMLWriterLayer final : public OGRLayer
{
    OGRJMLDataset *poDS;
    OGRFeatureDefn *poFeatureDefn;
    VSILFILE *fp;
    bool bFeaturesWritten;
    bool bAddRGBField;
    bool bAddOGRStyleField;
    bool bClassicGML;
    int nNextFID;
    CPLString osSRSAttr;
    OGREnvelope sLayerExtent;
    vsi_l_offset nBBoxOffset;

    void WriteColumnDeclaration(const char *pszName, const char *pszType);

  public:
    OGRJMLWriterLayer(const char *pszLayerName, OGRSpatialReference *poSRS,
                      OGRJMLDataset *poDSIn, VSILFILE *fp, bool bAddRGBField,
                      bool bAddOGRStyleField, bool bClassicGML);
    ~OGRJMLWriterLayer();

    void ResetReading() override
    {
    }

    OGRFeature *GetNextFeature() override
    {
        return nullptr;
    }

    OGRErr ICreateFeature(OGRFeature *poFeature) override;
    OGRErr CreateField(const OGRFieldDefn *poField, int bApproxOK) override;

    OGRFeatureDefn *GetLayerDefn() override
    {
        return poFeatureDefn;
    }

    int TestCapability(const char *) override;

    GDALDataset *GetDataset() override;
};

/************************************************************************/
/*                            OGRJMLDataset                             */
/************************************************************************/

class OGRJMLDataset final : public GDALDataset
{
    OGRLayer *poLayer;

    VSILFILE *fp; /* Virtual file API */
    bool bWriteMode;

  public:
    OGRJMLDataset();
    ~OGRJMLDataset();

    int GetLayerCount() override
    {
        return poLayer != nullptr ? 1 : 0;
    }

    OGRLayer *GetLayer(int) override;

    OGRLayer *ICreateLayer(const char *pszName,
                           const OGRGeomFieldDefn *poGeomFieldDefn,
                           CSLConstList papszOptions) override;

    int TestCapability(const char *) override;

    static int Identify(GDALOpenInfo *poOpenInfo);
    static GDALDataset *Open(GDALOpenInfo *poOpenInfo);
    static GDALDataset *Create(const char *pszFilename, int nBands, int nXSize,
                               int nYSize, GDALDataType eDT,
                               char **papszOptions);
};

#endif /* ndef OGR_JML_H_INCLUDED */
