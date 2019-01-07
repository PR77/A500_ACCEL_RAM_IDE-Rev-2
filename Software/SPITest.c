#include <clib/dos_protos.h>
#include <clib/exec_protos.h>
#include <clib/expansion_protos.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/*****************************************************************************/
/* Defines *******************************************************************/
/*****************************************************************************/

#define READ_ID_CMD                         0x90
#define READ_ID_CMD_ADDR_MANUFACTURE_ID     0x00
#define READ_ID_CMD_ADDR_DEVICE_ID          0x01

#define SPI_CS_MASK                         0x8000
#define SPI_SCK_MASK                        0x0001
#define SPI_MOSI_MASK                       0x0080
#define SPI_MISO_MASK                       0x0001

/*****************************************************************************/
/* Types *********************************************************************/
/*****************************************************************************/

typedef enum {
    
    spiIdle = 0,
    spiOK
    
} tSpiCommandStatus;

/*****************************************************************************/
/* Globals *******************************************************************/
/*****************************************************************************/

struct Library *ExpansionBase = NULL;

/*****************************************************************************/
/* Prototypes ****************************************************************/
/*****************************************************************************/

tSpiCommandStatus setSpiChipSelect(ULONG * pDeviceAddress, UBYTE chipSelect);
tSpiCommandStatus writeSpiCommand(ULONG * pDeviceAddress, UBYTE command);
tSpiCommandStatus readSpidata(ULONG * pDeviceAddress, UBYTE * pData);

void hexDump (char *desc, void *addr, int len);
int main(int argc, char **argv);

/*****************************************************************************/
/* Code **********************************************************************/
/*****************************************************************************/

/*****************************************************************************/
/* Function:    setSpiChipSelect()                                           */
/* Returns:     tSpiCommandStatus                                            */
/* Parameters:  ULONG * deviceAddress, UBYTE chipSelect                      */
/* Description: Controls the SPI device chip select                          */
/*****************************************************************************/
tSpiCommandStatus setSpiChipSelect(ULONG * pDeviceAddress, UBYTE chipSelect)
{
    tSpiCommandStatus spiCommandStatus = spiIdle;
    
#ifndef NDEBUG
    printf("ENTRY: setSpiChipSelect(ULONG * pDeviceAddress 0x%X, UBYTE chipSelect 0x%X)\n", pDeviceAddress, chipSelect);
#endif
         
#ifndef NDEBUG
    printf("FLOW: \n");
#endif

#ifndef NDEBUG
    printf("EXIT: setSpiChipSelect(spiCommandStatus 0x%X)\n", spiCommandStatus);
#endif
    return (spiCommandStatus);
}

/*****************************************************************************/
/* Function:    writeSpiCommand()                                            */
/* Returns:     tSpiCommandStatus                                            */
/* Parameters:  ULONG * deviceAddress, UBYTE command                         */
/* Description: Sends a single byte SPI command                              */
/*****************************************************************************/
tSpiCommandStatus writeSpiCommand(ULONG * pDeviceAddress, UBYTE command)
{
    tSpiCommandStatus spiCommandStatus = spiIdle;
    
#ifndef NDEBUG
    printf("ENTRY: writeSpiCommand(ULONG * pDeviceAddress 0x%X, UBYTE command 0x%X)\n", pDeviceAddress, command);
#endif
         
#ifndef NDEBUG
    printf("FLOW: \n");
#endif

#ifndef NDEBUG
    printf("EXIT: writeSpiCommand(spiCommandStatus 0x%X)\n", spiCommandStatus);
#endif
    return (spiCommandStatus);
}

/*****************************************************************************/
/* Function:    readSpidata()                                                */
/* Returns:     tSpiCommandStatus                                            */
/* Parameters:  ULONG * deviceAddress, UBYTE * data                          */
/* Description: Sends a single byte SPI command                              */
/*****************************************************************************/
tSpiCommandStatus readSpidata(ULONG * pDeviceAddress, UBYTE * pData)
{
    tSpiCommandStatus spiCommandStatus = spiIdle;
    
#ifndef NDEBUG
    printf("ENTRY: readSpidata(ULONG * pDeviceAddress 0x%X, UBYTE pData 0x%X)\n", pDeviceAddress, pData);
#endif
         
#ifndef NDEBUG
    printf("FLOW: \n");
#endif

#ifndef NDEBUG
    printf("EXIT: writeSpiCommand(spiCommandStatus 0x%X)\n", spiCommandStatus);
#endif
    return (spiCommandStatus);
}

/*****************************************************************************/
/* Function:    hexDump()                                                    */
/* Returns:     void                                                         */
/* Parameters:  char *desc, void *addr, int len                              */
/* Description: Prints a formatted HEX dump of (len) &(addr) with (desc)     */
/*****************************************************************************/
void hexDump (char *desc, void *addr, int len)
{
    int i;
    unsigned char buff[17];
    unsigned char *pc = (unsigned char*)addr;

    // Output description if given.
    if (desc != NULL)
        printf ("%s:\n", desc);

    if (len == 0) {
        printf("  ZERO LENGTH\n");
        return;
    }
    if (len < 0) {
        printf("  NEGATIVE LENGTH: %i\n",len);
        return;
    }

    // Process every byte in the data.
    for (i = 0; i < len; i++) {
        // Multiple of 16 means new line (with line offset).

        if ((i % 16) == 0) {
            // Just don't print ASCII for the zeroth line.
            if (i != 0)
                printf ("  %s\n", buff);

            // Output the offset.
            printf ("  %04x ", i);
        }

        // Now the hex code for the specific character.
        printf (" %02x", pc[i]);

        // And store a printable ASCII character for later.
        if ((pc[i] < 0x20) || (pc[i] > 0x7e))
            buff[i % 16] = '.';
        else
            buff[i % 16] = pc[i];
        buff[(i % 16) + 1] = '\0';
    }

    // Pad out last line if not exactly 16 characters.
    while ((i % 16) != 0) {
        printf ("   ");
        i++;
    }

    // And print the final ASCII bit.
    printf ("  %s\n", buff);
}

/*****************************************************************************/
/* Main **********************************************************************/
/*****************************************************************************/
int main(int argc, char **argv)
{
    struct ConfigDev *myCD = NULL;

    /* Open any version expansion.library to read in ConfigDevs */
    ExpansionBase = OpenLibrary("expansion.library", 0L);
    
    /* Check if opened correctly, otherwise exit with message and error */
    if (NULL == ExpansionBase)
    {
        printf("Failed to open expansion.library\n");
        exit(RETURN_FAIL);
    }
 
    /*----------------------------------------------------*/
    /* FindConfigDev(oldConfigDev, manufacturer, product) */
    /* oldConfigDev = NULL for the top of the list        */
    /* manufacturer = -1 for any manufacturer             */
    /* product      = -1 for any product                  */
    /*----------------------------------------------------*/
  
    /* Check if correct Zorro II hardware is present. SPI Interface */
    myCD = FindConfigDev(0L, 1977, 102);

    /* Check if opened correctly, otherwise exit with message and error */
    if (NULL == myCD)
    {
        printf("Failed to identify SPI Interface Hardware\n");
        CloseLibrary(ExpansionBase);
        exit(RETURN_FAIL);
    }
    else
    /* Opened correctly, so print out the configuration details */
    {
        printf("SPI Interface Hardware identified with configuration:\n");
        printf("cd_BoardAddr = 0x%X\n", myCD->cd_BoardAddr);
        printf("cd_BoardSize = 0x%X (%ldK)\n", myCD->cd_BoardSize,((ULONG)myCD->cd_BoardSize)/1024);
        printf("Identyfing SPI Device:\n");

        // TODO: Add code here to read device

    }

    CloseLibrary(ExpansionBase);
}
