//
//  GWSystemInfo.m
//  GWUtils
//
//  Created by huangqisheng on 14/12/11.
//  Copyright (c) 2014年 GW. All rights reserved.
//

#define MAXADDRS          32

char          *if_names[MAXADDRS];
char          *ip_names[MAXADDRS];
char          *hw_addrs[MAXADDRS];
unsigned long  ip_addrs[MAXADDRS];

// Function prototypes
void InitAddresses();
void FreeAddresses();
void GetIPAddresses();
void GetHWAddresses();


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/sockio.h>
#include <net/if.h>
#include <errno.h>
#include <net/if_dl.h>
#include <sys/sysctl.h>
#import <UIKit/UIKit.h>

#import "GWSystemInfo.h"

@implementation GWSystemInfo

+ (NSString *)getIPAdress
{
    InitAddresses();
    GetIPAddresses();
    GetHWAddresses();
    return [NSString stringWithFormat:@"%s", ip_names[1]];
}

+ (NSString *)getMacAddress
{
    int mib[6];
    size_t len;
    char *buf;
    unsigned char *ptr;
    struct if_msghdr *ifm;
    struct sockaddr_dl *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1/n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        free(buf);
        printf("Error: sysctl, take 2");
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    // NSString *outstring = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    NSString *outstring = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x", *ptr, *(ptr + 1), *(ptr + 2), *(ptr + 3), *(ptr + 4), *(ptr + 5)];
    free(buf);
    return [outstring uppercaseString];
}

+ (NSString *)getOSVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

+ (BOOL)isJailbroken
{
    BOOL jailbroken = NO;
    NSString *cydiaPath = @"/Applications/Cydia.app";
    NSString *aptPath = @"/private/var/lib/apt/";
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:cydiaPath]) {
        jailbroken = YES;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:aptPath]) {
        jailbroken = YES;
    }
    return jailbroken;
}

@end


#pragma mark - ip address

char *ether_ntoa(void *unknown);

#define min(a, b)           ((a) < (b) ? (a) : (b))
#define max(a, b)           ((a) > (b) ? (a) : (b))

#define BUFFERSIZE          4000

static int     nextAddr = 0;

void InitAddresses()
{
    int  i;
    
    for (i = 0; i < MAXADDRS; ++i) {
        if_names[i] = ip_names[i] = hw_addrs[i] = NULL;
        ip_addrs[i] = 0;
    }
}

void FreeAddresses()
{
    int  i;
    
    for (i = 0; i < MAXADDRS; ++i) {
        if (if_names[i] != 0) free(if_names[i]);
        if (ip_names[i] != 0) free(ip_names[i]);
        if (hw_addrs[i] != 0) free(hw_addrs[i]);
        ip_addrs[i] = 0;
    }
    InitAddresses();
}

void GetIPAddresses()
{
    int                 i, len, flags;
    char                buffer[BUFFERSIZE], *ptr, lastname[IFNAMSIZ], *cptr;
    struct ifconf       ifc;
    struct ifreq       *ifr, ifrcopy;
    struct sockaddr_in *sin;
    
    char                temp[80];
    
    int                 sockfd;
    
    for (i = 0; i < MAXADDRS; ++i) {
        if_names[i] = ip_names[i] = NULL;
        ip_addrs[i] = 0;
    }
    
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("socket failed");
        return;
    }
    
    ifc.ifc_len = BUFFERSIZE;
    ifc.ifc_buf = buffer;
    
    if (ioctl(sockfd, SIOCGIFCONF, &ifc) < 0) {
        perror("ioctl error");
        return;
    }
    
    lastname[0] = 0;
    
    for (ptr = buffer; ptr < buffer + ifc.ifc_len; ) {
        ifr = (struct ifreq *)ptr;
        len = max(sizeof(struct sockaddr), ifr->ifr_addr.sa_len);
        ptr += sizeof(ifr->ifr_name) + len; // for next one in buffer
        
        if (ifr->ifr_addr.sa_family != AF_INET) {
            continue;                       // ignore if not desired address family
        }
        
        if ((cptr = (char *)strchr(ifr->ifr_name, ':')) != NULL) {
            *cptr = 0;                      // replace colon will null
        }
        
        if (strncmp(lastname, ifr->ifr_name, IFNAMSIZ) == 0) {
            continue;                       /* already processed this interface */
        }
        
        memcpy(lastname, ifr->ifr_name, IFNAMSIZ);
        
        ifrcopy = *ifr;
        ioctl(sockfd, SIOCGIFFLAGS, &ifrcopy);
        flags = ifrcopy.ifr_flags;
        if ((flags & IFF_UP) == 0) {
            continue;                   // ignore if interface not up
        }
        
        if_names[nextAddr] = (char *)malloc(strlen(ifr->ifr_name) + 1);
        if (if_names[nextAddr] == NULL) {
            return;
        }
        strcpy(if_names[nextAddr], ifr->ifr_name);
        free(if_names[nextAddr]);
        sin = (struct sockaddr_in *)&ifr->ifr_addr;
        strcpy(temp, inet_ntoa(sin->sin_addr));
        
        ip_names[nextAddr] = (char *)malloc(strlen(temp) + 1);
        if (ip_names[nextAddr] == NULL) {
            return;
        }
        strcpy(ip_names[nextAddr], temp);
        free(ip_names[nextAddr]);
        ip_addrs[nextAddr] = sin->sin_addr.s_addr;
        
        ++nextAddr;
    }
    
    close(sockfd);
}

void GetHWAddresses()
{
    struct ifconf  ifc;
    struct ifreq  *ifr;
    int            i, sockfd;
    char           buffer[BUFFERSIZE], *cp, *cplim;
    char           temp[80];
    
    for (i = 0; i < MAXADDRS; ++i) {
        hw_addrs[i] = NULL;
    }
    
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("socket failed");
        return;
    }
    
    ifc.ifc_len = BUFFERSIZE;
    ifc.ifc_buf = buffer;
    
    if (ioctl(sockfd, SIOCGIFCONF, (char *)&ifc) < 0) {
        perror("ioctl error");
        close(sockfd);
        return;
    }
    
    // ifr = ifc.ifc_req;
    
    cplim = buffer + ifc.ifc_len;
    
    for (cp = buffer; cp < cplim; ) {
        ifr = (struct ifreq *)cp;
        if (ifr->ifr_addr.sa_family == AF_LINK) {
            struct sockaddr_dl *sdl = (struct sockaddr_dl *)&ifr->ifr_addr;
            int                 a, b, c, d, e, f;
            int                 i;
            
            strcpy(temp, (char *)ether_ntoa(LLADDR(sdl)));
            sscanf(temp, "%x:%x:%x:%x:%x:%x", &a, &b, &c, &d, &e, &f);
            sprintf(temp, "%02X:%02X:%02X:%02X:%02X:%02X", a, b, c, d, e, f);
            
            for (i = 0; i < MAXADDRS; ++i) {
                if ((if_names[i] != NULL) && (strcmp(ifr->ifr_name, if_names[i]) == 0)) {
                    if (hw_addrs[i] == NULL) {
                        hw_addrs[i] = (char *)malloc(strlen(temp) + 1);
                        strcpy(hw_addrs[i], temp);
                        break;
                    }
                }
            }
        }
        cp += sizeof(ifr->ifr_name) + max(sizeof(ifr->ifr_addr), ifr->ifr_addr.sa_len);
    }
    
    close(sockfd);
}
