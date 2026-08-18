#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <time.h>

#define HW_BRIDGE_ADDR ( 0xff200000 )
#define HW_BRIDGE_SPAN ( 0x00200000 )
#define REG_OFFSET     ( 0x0 )

void load_machine(volatile uint32_t *addr, const int8_t *arrayA, const int8_t *arrayB);
void create_arrays(int8_t arrayA[64], int8_t arrayB[64], int32_t arrayC[64]);
int debug_tests(volatile uint32_t *regpt);
int start_machine(volatile uint32_t *regpt);
int check_answers(volatile uint32_t *C_addr, const int32_t arrayC[64]);

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
        regpt[0]: ctrlwr [31:1 unused, 0 start]. Write a 1 to bit 0 to start the calculations.
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

    if(debug_tests(regpt) != 0)    
    {
        if(munmap(mempt, HW_BRIDGE_SPAN) != 0)
        {
            printf("ERROR: Failed to unmap memory!\n");
            close(fd);
            return(1);
        }

        close(fd);
        return(1);
    }

    int8_t arrayA[64];
    int8_t arrayB[64];
    int32_t arrayC[64];

    create_arrays(arrayA, arrayB, arrayC);

    load_machine(&regpt[16], arrayA, arrayB);

    if(start_machine(regpt) != 0)
    {
        if(munmap(mempt, HW_BRIDGE_SPAN) != 0)
        {
            printf("ERROR: Failed to unmap memory!\n");
            close(fd);
            return(1);
        }

        close(fd);
        return(1);

    }

    if(check_answers(&regpt[64], arrayC) != 0)
    {
        if(munmap(mempt, HW_BRIDGE_SPAN) != 0)
        {
            printf("ERROR: Failed to unmap memory!\n");
            close(fd);
            return(1);
        }

        close(fd);
        return(1);
    }

    if(munmap(mempt, HW_BRIDGE_SPAN) != 0)
    {
        printf("ERROR: Failed to unmap memory!\n");
        close(fd);
        return(1);
    }

    close(fd);
    return(0);
}

void load_machine(volatile uint32_t *addr, 
                 const int8_t *arrayA, 
                 const int8_t *arrayB)
{
    uint32_t arrchunkA;
    uint32_t arrchunkB;
    for(int i = 0; i < 16; i ++)
    {

        arrchunkA  = (uint32_t)(uint8_t)arrayA[i * 4];
        arrchunkA |= (uint32_t)(uint8_t)arrayA[i * 4 + 1] << 8;
        arrchunkA |= (uint32_t)(uint8_t)arrayA[i * 4 + 2] << 16;
        arrchunkA |= (uint32_t)(uint8_t)arrayA[i * 4 + 3] << 24;

        arrchunkB  = (uint32_t)(uint8_t)arrayB[i * 4];
        arrchunkB |= (uint32_t)(uint8_t)arrayB[i * 4 + 1] << 8;
        arrchunkB |= (uint32_t)(uint8_t)arrayB[i * 4 + 2] << 16;
        arrchunkB |= (uint32_t)(uint8_t)arrayB[i * 4 + 3] << 24;

        addr[i] = arrchunkA;
        addr[i + 16] = arrchunkB;
    }
}

void create_arrays(
    int8_t arrayA[64],
    int8_t arrayB[64],
    int32_t arrayC[64])
{
    int8_t A_arr[8][8] = {
        {   61,  -92, -71, -103, -125,  -38,   94,   42 },
        { -115,   24, -17,   35,  117,   40,   37,   18 },
        {  -51,  -32, -68,  -87,    9,   61,  -55,  -66 },
        {  -87,  121, 127,  -87,   97,   54, -111, -100 },
        {   66,   -5,  29,    6,   68, -107,  -23,   24 },
        {  -45,  -79,  65,    0,  -66,    2,  -86,   35 },
        { -122,   98, -83,   -1, -127,   22,  -20,  -85 },
        {  116, -126, -52,  100,  -35,   93,    2,  -96 }
    };

    int8_t B_arr[8][8] = {
        {   46,   74,   87,  -21,  127,  114,  -86,  -41 },
        {   85, -119,   84,   85,  -40,    6,  -36,   69 },
        {   66,  123,    0,   -1,  -30, -118,   76,   83 },
        {  126,  -98,   -5, -120,  -81,   64,  -43,  -26 },
        {  116, -119,  -35,  -52,   65,  -67,  -25,  103 },
        { -127,  -91,   28, -108,   55,  -44,  -40,  -11 },
        {  -85,  109,  104,  -65,  112,   88,   33,   11 },
        {   -7, -117,   78,   23,   72,   37,  118, -127 }
    };

    int32_t C_arr[8][8] = {
        { -40636,  40488,  14457,   8790,  25237,  28061,   9802, -28821 },
        {   5259, -32523,  -5887, -12123,  -2645, -14397,   5049,  13782 },
        { -22082,  -4699, -16165,   3860,  -3082, -14119,  -8157,   4534 },
        {  18232, -13546, -18197,  16464, -23009, -52089,  -3529,  45595 },
        {  28545,   4788,   -604,   7507,   4913,   3472,   1103,   4080 },
        {  -5340,   8269, -14399,   3776, -15797, -15213,  14516, -10422 },
        { -18117,  -9925,  -6026,  14668, -32248,   -954,  -7696,   2153 },
        { -11575,  14534,  -4443, -35656,   9384,  19881, -27799, -12780 }
    };

    for (int i = 0; i < 8; i++)
    {
        for (int j = 0; j < 8; j++)
        {
            arrayA[j * 8 + i] = A_arr[i][j];
            arrayB[i * 8 + j] = B_arr[i][j];
            arrayC[i * 8 + j] = C_arr[i][j];
        }
    }
}

int debug_tests(volatile uint32_t *regpt)
{
    // Basic debug tests
    printf("Beginning basic tests\n");

    // Try to read ID register
    if(regpt[2] != 0xabcd0000)
    {
        printf("ERROR: ID mismatch. Something has gone wrong!\n");
        return 1;
    }

    // Test read/write
    regpt[3] = 67;
    if (regpt[3] != 67)
    {
        printf("ERROR: Read/Write test failed. Something has gone wrong!\n");
        return 1;
    }

    printf("System operational.\n");
    return 0;
}

int start_machine(volatile uint32_t *regpt)
{

    struct timespec start, end;
    if(clock_gettime(CLOCK_MONOTONIC, &start) != 0)
    {
        printf("Failed to get clock start time\n");
        return 1;
    }
    // Write to start
    regpt[0] = 1;
    uint32_t status;
    int tries = 0;
    int LIMIT = 10000000;
    do {
        status = regpt[1];
        tries++;
    } while ((!(status & 0x1 /* not done */) || (status & 0x2 /* is busy */)) && tries < LIMIT);

    if (tries >= LIMIT) {
        printf("timeout, status = 0x%08x\n", status);
        return 1;
    }

    if(clock_gettime(CLOCK_MONOTONIC, &end) != 0)
    {
        printf("Failed to get clock end time\n");
        return 1;
    }

    // Calculate and print time
    double time_taken = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    printf("Took %f seconds to execute\n", time_taken);
    return 0;
}

int check_answers(volatile uint32_t *C_addr, const int32_t arrayC[64])
{
    int errcount = 0;
    for(int i = 0; i < 64; i ++)
    {
        if((int32_t)C_addr[i] != arrayC[i])
        {
            errcount ++;
        }
    }

    if(errcount == 0){
        printf("Arrays match!\n");
        return 0;
    }

    printf("Arrays do not match; %0d errors.", errcount);
    return 1;
}