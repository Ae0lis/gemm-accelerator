#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#define HW_BRIDGE_ADDR ( 0xff200000 )
#define HW_BRIDGE_SPAN ( 0x00200000 )
#define REG_OFFSET     ( 0x0 )

int main(void)
{
    int fd = 0;
    void *mempt = NULL;
    volatile uint32_t *regpt = NULL;

    fd = open("/dev/mem", ( O_RDWR | O_SYNC ));
    if(fd == -1)
    {
        printf("ERROR: Failed to open /dev/mem!\n");
        return(1);
    }

    mempt = mmap(NULL, HW_BRIDGE_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_BRIDGE_ADDR );
    if(mempt == MAP_FAILED)
    {
        printf("ERROR: Failed to map memory!\n");
        close(fd);
        return(1);
    }

    regpt = (volatile uint32_t *) (mempt + REG_OFFSET);

    /* 
        Register Map

        Controls
        regpt[0]: ctrlwr [31:1 unused, 0 start]. Write to 0 to start the calculations.
        regpt[1]: ctrlrd [31:2 unused, 1 busy, 0 done]. When 1 is false and 0 is true, the calculation 
            is done. When 1 is true, it's currently working. When neither is true, the machine is idle
        regpt[2]: ID. Reading this should always return 0xabcd0000. If it doesn't, something has gone wrong.
        regpt[3]: rwtest. Can be written to and read to test if the system is working.
        regpt[15:4]: unused.

        Matrix Writes
        regpt[31:16]: Write in matrix A here. IMPORTANT: in the current implementation, A *must be written transposed*.
            Scaffold code is provided to help with this, but this is important to remember for any future development.
            Each write should be 4 packed int8 numbers, lowest at the lowest address (ex: [int8 3, int8 2, int8 1, int8 0])
            A will look like the following:
        
        regpt[16][7:0] regpt[16][15:8] regpt[16][23:16] regpt[16][31:24] regpt[17][7:0] regpt[17][15:8] regpt[17][23:16] regpt[17][31:24]
        regpt[18][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[20][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[22][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[24][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[26][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[28][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[30][7:0] ...             ...              ...              ...            ...             ...              regpt[31][31:24]
        
        
        regpt[47:32]: Write in matrix B here. B should be stored normally. Each write should be 4 packed int8 numbers, 
            lowest at the lowest address (ex: [int8 3, int8 2, int8 1, int8 0])
            B will look like the following:

        regpt[32][7:0] regpt[32][15:8] regpt[32][23:16] regpt[32][31:24] regpt[33][7:0] regpt[33][15:8] regpt[33][23:16] regpt[33][31:24]
        regpt[34][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[36][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[38][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[40][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[42][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[44][7:0] ...             ...              ...              ...            ...             ...              ...
        regpt[46][7:0] ...             ...              ...              ...            ...             ...              regpt[47][31:24]


        regpt[63:48]: unused.

        Final Read
        regpt[127:64]: Matrix C. Each read is a single int32 value. C will look like the following:

        regpt[64] regpt[65] regpt[66] regpt[67] regpt[68] regpt[69] regpt[70] regpt[71]
        regpt[72] ...       ...       ...       ...       ...       ...       ...
        regpt[80] ...       ...       ...       ...       ...       ...       ...
        regpt[88] ...       ...       ...       ...       ...       ...       ...
        regpt[96] ...       ...       ...       ...       ...       ...       ...
        regpt[104]...       ...       ...       ...       ...       ...       ...
        regpt[112]...       ...       ...       ...       ...       ...       ...
        regpt[120]...       ...       ...       ...       ...       ...       regpt[127]
    */


    // Basic debug tests
    printf("Beginning basic tests\n");
    regpt[3] = 67;
    if(regpt[2] != 0xabcd0000)
    {
        printf("ERROR: ID mismatch. Something has gone wrong!\n");
    } 
    else if (regpt[3] != 67)
    {
        printf("ERROR: Read/Write test failed. Something has gone wrong!\n");
    }
    else
    {
        printf("System operational.\n");
    }

    /* Test arrays with known good solution to compare against */
    int8_t A_arr[8][8] = {
        {   61,  -92, -71, -103, -125,  -38,   94,   42 }
        { -115,   24, -17,   35,  117,   40,   37,   18 }
        {  -51,  -32, -68,  -87,    9,   61,  -55,  -66 }
        {  -87,  121, 127,  -87,   97,   54, -111, -100 }
        {   66,   -5,  29,    6,   68, -107,  -23,   24 }
        {  -45,  -79,  65,    0,  -66,    2,  -86,   35 }
        { -122,   98, -83,   -1, -127,   22,  -20,  -85 }
        {  116, -126, -52,  100,  -35,   93,    2,  -96 }
    }

    int8_t B_arr[8][8] = {
        {   46,   74,   87,  -21,  127,  114,  -86,  -41 }
        {   85, -119,   84,   85,  -40,    6,  -36,   69 }
        {   66,  123,    0,   -1,  -30, -118,   76,   83 }
        {  126,  -98,   -5, -120,  -81,   64,  -43,  -26 }
        {  116, -119,  -35,  -52,   65,  -67,  -25,  103 }
        { -127,  -91,   28, -108,   55,  -44,  -40,  -11 }
        {  -85,  109,  104,  -65,  112,   88,   33,   11 }
        {   -7, -117,   78,   23,   72,   37,  118, -127 }
    }

    // To write A as transposed
    int8_t A_transposed[8][8];
    for(int i = 0; i < 8; i ++)
    {
        for(int j = 0; j < 8; j ++)
        {
            A_transposed[j][i] = A_arr[i][j];
        }
    }

    uint32_t A_chunk;
    uint32_t B_chunk;
    // TODO: Load the arrays into the machine

    if(munmap(mempt, HW_BRIDGE_SPAN) != 0)
    {
        printf("ERROR: Failed to unmap memory!\n");
        close(fd);
        return(1);
    }

    close(fd);
    return(0);
}