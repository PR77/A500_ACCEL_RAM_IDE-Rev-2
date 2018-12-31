#include <dos/dos.h>
#include <dos/dostags.h>

#include <clib/dos_protos.h>
#include <clib/exec_protos.h>
#include <clib/expansion_protos.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/*****************************************************************************/
/* Defines *******************************************************************/
/*****************************************************************************/

#define IO_PORT_BIT_SIZE        2
#define IO_PORT_BIT_MAX_SIZE    16
#define IO_PORT_MASK            (IO_PORT_BIT_SIZE + 1)
#define IO_PORT_BIT_POSITION    (IO_PORT_BIT_MAX_SIZE - IO_PORT_BIT_SIZE)

#define TEMPLATE                "PORTVALUE/N"

/*****************************************************************************/
/* Types *********************************************************************/
/*****************************************************************************/

/*****************************************************************************/
/* Globals *******************************************************************/
/*****************************************************************************/

struct Library *ExpansionBase = NULL;

/*****************************************************************************/
/* Prototypes ****************************************************************/
/*****************************************************************************/

int main(int argc, char **argv);

/*****************************************************************************/
/* Code **********************************************************************/
/*****************************************************************************/

/*****************************************************************************/
/* Main **********************************************************************/
/*****************************************************************************/
int main(int argc, char **argv)
{
    struct ConfigDev *myCD = NULL;
    struct RDArgs *myrda = NULL;
    LONG params[1];
    LONG portValue = 0;
    
    /* Check if application has been started with correct parameters */
    if (argc != 2)
    {
        printf("usage: IOTest <%s>\n", (STRPTR)TEMPLATE);
        exit(RETURN_FAIL);
    }
    
    myrda = ReadArgs((STRPTR)TEMPLATE, params, NULL);
    
    if (NULL == myrda)
    {
        printf("Error with <%s> specified\n", (STRPTR)TEMPLATE);
        exit(RETURN_FAIL);        
    }
    else
    {
        portValue = *(LONG *)params[0];
        FreeArgs(myrda);
    }
    
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
  
    /* Check if correct Zorro II hardware is present. IO Interface */
    myCD = FindConfigDev(0L, 1977, 101);

    /* Check if opened correctly, otherwise exit with message and error */
    if (NULL == myCD)
    {
        printf("Failed to identify IO Interface Hardware\n");
        CloseLibrary(ExpansionBase);
        exit(RETURN_FAIL);
    }
    else
    /* Opened correctly, so print out the configuration details */
    {
        printf("IO Interface Hardware identified with configuration:\n");
        printf("cd_BoardAddr = 0x%X\n", myCD->cd_BoardAddr);
        printf("cd_BoardSize = 0x%X (%ldK)\n", myCD->cd_BoardSize,((ULONG)myCD->cd_BoardSize)/1024);
        
        printf("Writing [%d] to IO Interface ... ", portValue);
        *(LONG *)myCD->cd_BoardAddr = ((portValue & IO_PORT_MASK) << IO_PORT_BIT_POSITION);
        printf("Done\n");
    }

    CloseLibrary(ExpansionBase);
}
