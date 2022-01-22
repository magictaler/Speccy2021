//! @file version.c
//! @brief Reports software version
#include "version.h"

#define IMAGE_ID        0
#define VERSION_MAJOR   1
#define VERSION_MINOR   0
#define VERSION_BUGFIX  0

uint16_t version_get_major(void)
{
    return VERSION_MAJOR;
}

uint16_t version_get_minor(void)
{
    return VERSION_MINOR;
}

uint16_t version_get_rev(void)
{
    return VERSION_BUGFIX;
}



