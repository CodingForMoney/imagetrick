#include <string.h>
#include <stdio.h>
#include <sys/time.h>

long BKDRHash(const char* str)
{
    long seed = 131; // 31 131 1313 13131 131313 etc..
    long hash = 0;
    if (!str) {
        return 0;
    }
    int length = strlen(str);
    for(int i = 0; i < length; i++)
    {
        hash = (hash * seed) + str[i];
    }
    return hash;
}


int pdeletefile(const char* filename)
{
    return remove(filename);
}

int pmovefile(const char* src , const char* dest)
{
    return rename(src,dest);
}

long getmillisecond() {
    struct timeval tv;
    gettimeofday(&tv,NULL);
    long millisecond = (tv.tv_sec*1000000+tv.tv_usec)/1000;
    return millisecond;
}
