//! @file version.h
//! @brief Reports software version
#ifndef VERSION_H
#define VERSION_H

#include <stdint.h>

//! @brief Get major PS image revision
//! @return major version as int
uint16_t version_get_major(void);

//! @brief Get minor PS image revision
//! @return minor version as int
uint16_t version_get_minor(void);

//! @brief Get revision number of the PS image
//! @return revision number as int
uint16_t version_get_rev(void);

#endif
